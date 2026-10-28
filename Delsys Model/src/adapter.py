import numpy as np
from scipy.signal import resample_poly
from math import gcd
class UniversalEMGAdapter:
    def __init__(self, target_fs=2000.0, target_ch=12): self.tf, self.tc = target_fs, target_ch
    def resample_fs(self, emg, fs):
        if abs(fs-self.tf) < 1e-3: return emg
        g = gcd(int(fs), int(self.tf)); return resample_poly(emg, int(self.tf)//g, int(fs)//g, axis=0).astype(np.float32)
    def align_channels(self, emg, c):
        N = emg.shape[0]
        if c == self.tc: return emg.astype(np.float32)
        if c < self.tc:
            sp, tp = np.linspace(0,1,c), np.linspace(0,1,self.tc)
            return np.stack([np.interp(tp, sp, emg[i]) for i in range(N)]).astype(np.float32)
        return emg[:, np.linspace(0, c-1, self.tc).astype(int)].astype(np.float32)
    def adapt(self, x, fs, c): return self.align_channels(self.resample_fs(x, fs), c).astype(np.float32)

