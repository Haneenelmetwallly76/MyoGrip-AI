import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import TensorDataset, DataLoader
class SupConLoss(nn.Module):
    def __init__(self, temperature=0.07): super().__init__(); self.t = temperature
    def forward(self, f, y):
        f = F.normalize(f, p=2, dim=1); B = f.shape[0]
        y = y.contiguous().view(-1, 1); m = torch.eq(y, y.T).float().to(f.device)
        a = torch.matmul(f, f.T)/self.t; a = a - a.max(1, keepdim=True).values.detach()
        lm = torch.scatter(torch.ones_like(m), 1, torch.arange(B, device=f.device).view(-1,1), 0)
        m = m*lm; e = torch.exp(a)*lm
        lp = a - torch.log(e.sum(1, keepdim=True)+1e-9)
        l = -(m*lp).sum(1)/(m.sum(1)+1e-9); v = m.sum(1) > 0
        return l[v].mean() if v.sum() else l.mean()


def few_shot_arrays(mdl, anchor, wts, Xtr, Ytr, epochs=15, lr=3e-4, lam=5.0):
    mdl.load_state_dict(copy.deepcopy(wts))
    for nm in ['branch1','branch2','branch3','depthwise','pointwise']:
        if hasattr(mdl, nm):
            for p in getattr(mdl, nm).parameters(): p.requires_grad = False
    with torch.no_grad():
        A = torch.cat([anchor(torch.from_numpy(w[None]).to(device))[1].cpu() for w in Xtr])
    ds = DataLoader(TensorDataset(torch.from_numpy(Xtr), torch.from_numpy(Ytr), A), 128, shuffle=True)
    opt = torch.optim.AdamW(filter(lambda p: p.requires_grad, mdl.parameters()), lr=lr, weight_decay=1e-4)
    crit = SupConLoss(0.07); mdl.train()
    for _ in range(epochs):
        for xb, yb, ab in ds:
            xb, yb, ab = xb.to(device), yb.to(device), ab.to(device)
            xb = xb*torch.empty(xb.shape[0],1,xb.shape[2],device=device).uniform_(0.8,1.2)+torch.randn_like(xb)*0.01
            opt.zero_grad(); proj, base, _, _ = mdl(xb)
            (crit(proj, yb) + lam*F.mse_loss(base, ab)).backward()
            torch.nn.utils.clip_grad_norm_(mdl.parameters(), 1.0); opt.step()
    mdl.eval()
    for p in mdl.parameters(): p.requires_grad = True
