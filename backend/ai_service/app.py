import hmac
import io
import os
import pickle
import sys
import threading
from contextlib import asynccontextmanager
from pathlib import Path

import numpy as np
import torch
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel


REPO_ROOT = Path(__file__).resolve().parents[2]
MYO_DIR = Path(os.environ.get("MYO_CODE_DIR", REPO_ROOT / "MYO ARMBAND CODE")).resolve()
sys.path.insert(0, str(MYO_DIR))

import config as cfg
from architecture import Metric_ContinualNet
from continual_algorithms import StreamingLDA
from dataset_handler import apply_myo_filters
from haptic_alif import ALIF_Encoder

SERVICE_KEY = os.environ.get("SERVICE_KEY", "")

SLDA_FILE = os.environ.get("SLDA_FILE", "slda_classifier_original.pkl")


class _State:
    model = None
    slda = None
    scaler = None
    lock = threading.Lock()
    alif = {}


class _SafeUnpickler(pickle.Unpickler):

    def find_class(self, module, name):
        if name == "StreamingLDA":
            return StreamingLDA
        if module == "torch.storage" and name == "_load_from_bytes":
            return lambda b: torch.load(io.BytesIO(b), map_location="cpu", weights_only=False)
        return super().find_class(module, name)


def load_artifacts():
    wdir = Path(cfg.WEIGHTS_DIR)

    with open(wdir / "subject_scaler.pkl", "rb") as f:
        _State.scaler = pickle.load(f)

    model = Metric_ContinualNet(
        embedding_dim=cfg.EMBEDDING_DIM, num_sensors=cfg.NUM_SENSORS, window_size=cfg.WINDOW_SIZE
    )
    model.load_state_dict(torch.load(wdir / "metric_model_myo.pth", map_location="cpu", weights_only=True))
    model.eval()
    _State.model = model

    with open(wdir / SLDA_FILE, "rb") as f:
        slda = _SafeUnpickler(f).load()
    slda.device = "cpu"
    slda.class_means = {c: m.to("cpu") for c, m in slda.class_means.items()}
    slda.scatter_matrix = slda.scatter_matrix.to("cpu")
    slda.precision_matrix = slda.precision_matrix.to("cpu")
    _State.slda = slda


def _enable_dropout(model):
    for m in model.modules():
        if m.__class__.__name__.startswith("Dropout"):
            m.train()


def _cocontraction(flexor, extensor, epsilon=1e-5):
    flex_env = np.mean(np.abs(flexor))
    ext_env = np.mean(np.abs(extensor))
    return float(2 * min(flex_env, ext_env) / (flex_env + ext_env + epsilon))


def run_inference(raw: np.ndarray, user_id: str) -> dict:
    filtered = apply_myo_filters(raw, fs=cfg.SAMPLING_RATE)
    scaled = _State.scaler.transform(filtered)
    x = torch.tensor(scaled, dtype=torch.float32).unsqueeze(0)

    with _State.lock, torch.no_grad():
        _State.model.eval()
        _enable_dropout(_State.model)
        preds, forces = [], []
        for _ in range(cfg.MC_DROPOUT_PASSES):
            embeddings, force = _State.model(x)
            pred_class, _ = _State.slda.predict(embeddings)
            preds.append(pred_class.item())
            forces.append(force.item())

        t = torch.tensor(preds, dtype=torch.float32)
        uncertainty = float(torch.var(t).item())
        gesture = int(torch.mode(t).values.item())
        force_val = float(np.mean(forces))

        rejected = uncertainty > cfg.UNCERTAINTY_THRESHOLD
        if rejected:
            gesture, force_val = 0, 0.0

        neuron = _State.alif.setdefault(user_id, ALIF_Encoder(base_threshold=0.5))
        spike = int(neuron.step(force_val))

    stiffness = _cocontraction(raw[:, 0], raw[:, 1])
    return {
        "gesture": gesture,
        "force": force_val,
        "uncertainty": uncertainty,
        "rejectedBySafety": rejected,
        "stiffnessIndex": stiffness,
        "stiffnessFlag": 1 if stiffness > 0.6 else 0,
        "hapticSpike": spike,
    }


@asynccontextmanager
async def lifespan(_app):
    if len(SERVICE_KEY) < 16:
        raise RuntimeError("Set the SERVICE_KEY environment variable (16+ characters).")
    load_artifacts()
    yield


app = FastAPI(title="MyoGrip AI service", lifespan=lifespan)


class PredictIn(BaseModel):
    window: list[list[float]]


def _check_key(key):
    if not key or not hmac.compare_digest(key.encode(), SERVICE_KEY.encode()):
        raise HTTPException(status_code=401, detail="Invalid service key")


@app.get("/health")
def health():
    return {
        "status": "ok",
        "classes": sorted(_State.slda.class_means.keys()),
        "windowSize": cfg.WINDOW_SIZE,
        "channels": cfg.NUM_SENSORS,
    }


@app.post("/predict")
def predict(body: PredictIn, x_service_key: str | None = Header(default=None),
            x_user_id: str | None = Header(default=None)):
    _check_key(x_service_key)
    arr = np.asarray(body.window, dtype=np.float64)
    if arr.shape != (cfg.WINDOW_SIZE, cfg.NUM_SENSORS):
        raise HTTPException(400, f"window must be {cfg.WINDOW_SIZE} x {cfg.NUM_SENSORS}, got {list(arr.shape)}")
    if not np.isfinite(arr).all():
        raise HTTPException(400, "window contains NaN or infinite values")
    return run_inference(arr, x_user_id or "anonymous")
