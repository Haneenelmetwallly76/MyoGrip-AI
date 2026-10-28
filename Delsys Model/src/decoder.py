import os, json, numpy as np, torch
import torch.nn.functional as F
from .preprocess import preprocess_emg_multiband, scale
from .adapter import UniversalEMGAdapter
from .model_def import Metric_ContinualNet_v2
from .slda import slda_from_profile
from .safety import soft_confidence, causal_majority

class ProstheticDecoder:
    def __init__(self, bundle, subject='S01', device='cpu', passes=5):
        self.cfg   = json.load(open(f'{bundle}/config/constants.json'))
        self.pol   = json.load(open(f'{bundle}/config/policy.json'))
        self.names = json.load(open(f'{bundle}/config/class_names.json'))
        self.device = device
        self.passes = passes or self.pol['mc_passes']
        prof = json.load(open(f'{bundle}/profiles/{subject}.json'))
        wpath = f'{bundle}/profiles/{subject}.pth'
        self.wsrc = wpath if os.path.exists(wpath) else f'{bundle}/model/student_v2.pth'
        print(f'[decoder] weights source: {os.path.basename(self.wsrc)}')
        self.model = Metric_ContinualNet_v2(num_sensors=self.cfg['num_sensors']).to(device)
        self.model.load_state_dict(torch.load(self.wsrc, map_location=device))
        self.model.eval()
        self.sl = slda_from_profile(prof, self.pol.get('slda_shrinkage', 0.3))
        self.protos = torch.tensor(prof['protos'], dtype=torch.float32) if prof.get('protos') else None
        self.mean, self.std = prof['scaler_mean'], prof['scaler_std']
        self.warm = 400
        self.adapter = UniversalEMGAdapter(self.cfg['fs'], 12)
        self.buf = np.zeros((0, 12), np.float32)
        self.hist_p, self.hist_c = [], []

    @torch.no_grad()
    def feed(self, raw_chunk, src_fs=2000.0, src_ch=12):
        x = self.adapter.adapt(np.asarray(raw_chunk, np.float32), src_fs, src_ch)
        self.buf = np.vstack([self.buf, x])
        W, step = self.cfg['window'], self.cfg['step_stream']
        NEED = self.warm + W                      # ✅ 800 = 400 استقرار + 400 نافذة
        out = None
        while len(self.buf) >= NEED:              # ✅ مش >= W — ده كان الباج
            seg = self.buf[-NEED:]
            mb = preprocess_emg_multiband(seg)    # الفلاتر بتستقر جوّه الـ warm
            feat = scale(mb[self.warm:], self.mean, self.std)   # ✅ آخر 400 ميزة مستقرة بس
            _, emb, kin, force = self.model(torch.from_numpy(feat[None]).to(self.device))
            emb = emb.cpu()
            preds, confs = soft_confidence(self.model, feat[None], self.sl, self.device, self.passes)
            pred, conf = int(preds[0]), float(confs[0])
            if self.protos is not None and self.pol.get('ood_proto_thresh'):
                d = torch.cdist(F.normalize(emb, p=2, dim=1), self.protos).min().item()
                if d > self.pol['ood_proto_thresh']:
                    pred, conf = 0, 0.0
            self.hist_p.append(pred); self.hist_c.append(conf)
            sm = causal_majority(np.array(self.hist_p), np.array(self.hist_c),
                                 self.pol['K_smooth'], self.pol['conf_vote'])[-1]
            out = {'class': pred, 'name': self.names[str(pred)], 'conf': round(conf, 3),
                   'kin': kin.cpu().numpy()[0].round(3).tolist(),
                   'force': force.cpu().numpy()[0].round(3).tolist(),
                   'smoothed': int(sm), 'action': self.names[str(int(sm))]}
            self.buf = self.buf[step:]            # 800-80=720 → الدفعة الجاية 800 ✅
        return out
