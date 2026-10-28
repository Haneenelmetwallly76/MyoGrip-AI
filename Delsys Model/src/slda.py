import torch
import torch.nn.functional as F
class SLDA:
    def __init__(self, shrinkage=0.3): self.a = shrinkage
    def fit(self, E, L):
        E = E.double(); L = L.long(); self.classes = torch.unique(L)
        self.means = torch.stack([E[L==c].mean(0) for c in self.classes])
        Ec = E - self.means[torch.searchsorted(self.classes, L)]
        S = (Ec.T@Ec)/max(1, E.shape[0]-len(self.classes)); D = S.shape[0]
        Sig = (1-self.a)*S + self.a*torch.trace(S)/D*torch.eye(D, dtype=torch.float64)
        self.W = torch.linalg.solve(Sig, self.means.T); self.b = -0.5*(self.means@self.W).diag()
    def predict(self, E): return self.classes[(E.double()@self.W + self.b).argmax(1)]
    def probs(self, E): return torch.softmax(E.double()@self.W + self.b, dim=1)


def slda_from_profile(prof, shrinkage=0.3):
    sl = SLDA(shrinkage=shrinkage)
    sl.W = torch.tensor(prof['W'], dtype=torch.float64)
    sl.b = torch.tensor(prof['b'], dtype=torch.float64)
    sl.classes = torch.tensor(prof['classes'])
    return sl
