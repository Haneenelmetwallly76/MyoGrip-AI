import torch, numpy as np
from torch.utils.data import TensorDataset, DataLoader
def enable_dropout(model):
    for m in model.modules():
        if m.__class__.__name__.startswith('Dropout'): m.train()
@torch.no_grad()
def soft_confidence(model, X, sl, device='cpu', passes=5):
    ds = DataLoader(TensorDataset(torch.from_numpy(X)), 256, shuffle=False)
    W, bb = sl.W.to(device), sl.b.to(device)
    cs = sl.classes.to(device)
    model.eval(); enable_dropout(model); Pall = []
    for (xb,) in ds:
        xb = xb.to(device)
        probs = torch.zeros(xb.shape[0], len(cs), device=device)
        for _ in range(passes):
            _, b, _, _ = model(xb)
            probs += torch.softmax(b.double() @ W + bb, dim=1)
        Pall.append((probs / passes).cpu())
    model.eval()
    P = torch.cat(Pall)
    return cs.cpu()[P.argmax(1)].numpy(), P.max(1).values.numpy()
def causal_majority(preds, confs, K=7, ct=0.6, rest=0):
    dec = np.zeros(len(preds), dtype=np.int64)
    for i in range(len(preds)):
        st = max(0, i - K + 1)
        wp, wc = preds[st:i+1], confs[st:i+1]
        m = wc >= ct
        if m.sum() == 0: dec[i] = rest
        else:
            v, c = np.unique(wp[m], return_counts=True); dec[i] = v[c.argmax()]
    return dec
