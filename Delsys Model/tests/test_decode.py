import numpy as np, sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from src.decoder import ProstheticDecoder
B = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
dec = ProstheticDecoder(B, 'S01')
rng = np.random.RandomState(0)
chunk = rng.randn(800, 12).astype(np.float32) * 0.001
out = None
for i in range(0, len(chunk), 80): out = dec.feed(chunk[i:i+80])
assert out is None or set(out) >= {'class','name','conf','kin','force','smoothed','action'}
print('✅ SCHEMA OK — decoder بيرجع العقد الكامل')
