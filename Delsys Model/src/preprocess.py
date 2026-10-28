import numpy as np
from scipy.signal import butter, lfilter, iirnotch
FS, WINDOW, MU_STUDENT = 2000.0, 400, 255.0
def preprocess_emg_multiband(emg, fs=FS, mu=MU_STUDENT,
                             bands=((20, 60), (60, 120), (120, 250), (250, 450)),
                             env_cutoff=20.0):
    b, a = iirnotch(50.0/(fs/2), 30.0); x = lfilter(b, a, emg, axis=0)
    b, a = butter(4, [20.0/(fs/2), 450.0/(fs/2)], btype='band'); x = lfilter(b, a, x, axis=0)
    outs = []
    for lo, hi in bands:
        b, a = butter(4, [lo/(fs/2), hi/(fs/2)], btype='band')
        sb = np.abs(lfilter(b, a, x, axis=0))
        b, a = butter(4, env_cutoff/(fs/2), btype='low')
        outs.append(lfilter(b, a, sb, axis=0))
    feat = np.clip(np.concatenate(outs, axis=1), 0, None)      # (N, 48)
    return (np.log1p(mu*feat)/np.log1p(mu)).astype(np.float32)

def window_emg(seg, window_size=WINDOW, step=80):
    n = len(seg)
    if n < window_size: return np.zeros((0, seg.shape[1]), np.float32)
    starts = np.arange(0, n-window_size+1, step, dtype=np.int64)
    idx = starts[:, None] + np.arange(window_size, dtype=np.int64)[None, :]
    return seg[idx].astype(np.float32)

def cap_windows(arrays, cap):
    n = len(arrays[0])
    if n <= cap: return arrays
    idx = np.unique(np.linspace(0, n-1, cap).astype(int))
    return [a[idx] for a in arrays]

def scale(mb, mean, std):
    return ((mb - np.asarray(mean, np.float32)) / np.maximum(np.asarray(std, np.float32), 1e-6)).astype(np.float32)
