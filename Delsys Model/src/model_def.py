import torch
import torch.nn as nn
import torch.nn.functional as F
class ChannelAttention(nn.Module):
    def __init__(self, in_planes, ratio=8):
        super(ChannelAttention, self).__init__()
        self.avg_pool = nn.AdaptiveAvgPool2d(1)
        self.max_pool = nn.AdaptiveMaxPool2d(1)
        self.fc1 = nn.Conv2d(in_planes, in_planes // ratio, 1, bias=False)
        self.relu = nn.ReLU()
        self.fc2 = nn.Conv2d(in_planes // ratio, in_planes, 1, bias=False)
        self.sigmoid = nn.Sigmoid()

    def forward(self, x):
        avg_out = self.fc2(self.relu(self.fc1(self.avg_pool(x))))
        max_out = self.fc2(self.relu(self.fc1(self.max_pool(x))))
        out = avg_out + max_out
        return self.sigmoid(out) * x



class SpatialAttention(nn.Module):
    def __init__(self, kernel_size=7):
        super(SpatialAttention, self).__init__()
        self.conv = nn.Conv2d(2, 1, 3, padding=1, bias=False)
        self.sigmoid = nn.Sigmoid()

    def forward(self, x):
        avg_out = torch.mean(x, dim=1, keepdim=True)
        max_out, _ = torch.max(x, dim=1, keepdim=True)
        out = torch.cat([avg_out, max_out], dim=1)
        out = self.conv(out)
        return self.sigmoid(out) * x



class TemporalAttention(nn.Module):
    def __init__(self, hidden_size):
        super(TemporalAttention, self).__init__()
        self.attention = nn.Sequential(
            nn.Linear(hidden_size, hidden_size // 2),
            nn.Tanh(),
            nn.Linear(hidden_size // 2, 1)
        )

    def forward(self, gru_output):
        attention_weights = self.attention(gru_output)
        attention_weights = F.softmax(attention_weights, dim=1)
        context_vector = torch.sum(attention_weights * gru_output, dim=1)
        return context_vector



class Metric_ContinualNet_v2(nn.Module):
    """
    Multi-Task Metric Continual Network with 3 Heads:
      1) Metric Embedding Head  -> for SupCon Loss (classification)
      2) Kinematic Head         -> 22 joint angles (Cyberglove)
      3) Force Head             -> 6 finger forces (from E3)
    """
    def __init__(self, embedding_dim=32, proj_dim=128, num_sensors=12,
                 num_joints=22, num_forces=6):
        super(Metric_ContinualNet_v2, self).__init__()
        
        self.num_joints = num_joints
        self.num_forces = num_forces
        
        # ============================================================
        # Input Sensor Attention Gate (نفس المعمارية القديمة)
        # ============================================================
        self.sensor_attention = nn.Sequential(
            nn.Linear(num_sensors, num_sensors),
            nn.Sigmoid()
        )

        self.band_attention = nn.Sequential(nn.Linear(4, 4), nn.Sigmoid())
        
        # ============================================================
        # Dilated Multi-Scale Temporal Convolutions (نفس المعمارية القديمة)
        # ============================================================
        self.branch1 = nn.Conv2d(1, 4, kernel_size=(1, 15), stride=(1, 4), padding=(0, 7))
        self.branch2 = nn.Conv2d(1, 4, kernel_size=(1, 9), stride=(1, 4), dilation=(1, 4), padding=(0, 16))
        self.branch3 = nn.Conv2d(1, 8, kernel_size=(1, 9), stride=(1, 4), dilation=(1, 8), padding=(0, 32))
        
        self.bn_temp = nn.BatchNorm2d(16)
        
        # ============================================================
        # Depthwise Separable Spatial Convolutions
        # ============================================================
        self.depthwise = nn.Conv2d(16, 32, kernel_size=(3, 3), padding=0, groups=16)
        self.pointwise = nn.Conv2d(32, 32, kernel_size=1)
        self.bn_spat = nn.BatchNorm2d(32)
        
        # ============================================================
        # Attention Modules
        # ============================================================
        self.ca = ChannelAttention(32)
        self.sa = SpatialAttention()
        
        self.pool = nn.MaxPool2d(kernel_size=(2, 4))
        self.dropout = nn.Dropout(0.4)
        
        # ============================================================
        # Temporal Processing (GRU + Temporal Attention)
        # ============================================================
        s_new = num_sensors // 2
        gru_input_dim = 32 * s_new
        
        self.gru = nn.GRU(
            input_size=gru_input_dim,
            hidden_size=64,
            num_layers=1,
            batch_first=True
        )
        self.temporal_attention = TemporalAttention(64)
        
        # ============================================================
        # HEAD 1: Metric Embedding Head (للتصنيف عبر SupCon Loss)
        # ============================================================
        self.embedding_head = nn.Sequential(
            nn.Linear(64, 64),
            nn.BatchNorm1d(64),
            nn.ReLU(),
            nn.Dropout(0.4),
            nn.Linear(64, embedding_dim)
        )
        
        self.projection_head = nn.Sequential(
            nn.Linear(embedding_dim, 64),
            nn.BatchNorm1d(64),
            nn.ReLU(),
            nn.Linear(64, proj_dim)
        )
        
        # ============================================================
        # HEAD 2: Kinematic Regression Head (جديد — 22 زاوية مفصل)
        # للتنبؤ بزوايا Cyberglove
        # ============================================================
        self.kinematic_head = nn.Sequential(
            nn.Linear(64, 64),
            nn.BatchNorm1d(64),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(64, 32),
            nn.ReLU(),
            nn.Linear(32, num_joints)
            # بدون Sigmoid لأن الزوايا قد تكون سالبة (حسب المعايرة)
        )
        
        # ============================================================
        # HEAD 3: Force Regression Head (مُحدّث — 6 قيم قوة أصابع)
        # للتنبؤ بقوى أصابع معينة من تمرين E3
        # ============================================================
        self.force_head = nn.Sequential(
            nn.Linear(64, 32),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(32, num_forces),
            nn.Sigmoid()   # القوة بين 0 و 1
        )
    
    def forward(self, x):
        B, W, S = x.shape

        xb = x.view(B, W, 4, S // 4)                      # (B, W, 4 bands, 12 sensors) band-major
        g  = self.band_attention(xb.mean(dim=(1, 3)))     # (B, 4) أهمية كل نطاق ترددي
        x  = (xb * g.unsqueeze(1).unsqueeze(3)).view(B, W, S)
        
        # 1) Sensor Attention Gate
        sensor_importance = self.sensor_attention(x.mean(dim=1))
        x = x * sensor_importance.unsqueeze(1)
        
        # 2) Reshape for Conv2d: (B, 1, S, W)
        x = x.permute(0, 2, 1).contiguous()
        x = x.unsqueeze(1)
        
        # 3) Multi-Scale Dilated Convolutions
        b1 = self.branch1(x)
        b2 = self.branch2(x)
        b3 = self.branch3(x)
        x = torch.cat([b1, b2, b3], dim=1)
        x = F.relu(self.bn_temp(x))
        
        # 4) Depthwise Separable Spatial Convolutions + Attention
        x = F.pad(x, (1, 1, 0, 0), mode='constant', value=0)
        x = F.pad(x, (0, 0, 1, 1), mode='circular')
        x = self.depthwise(x)
        x = F.relu(self.bn_spat(self.pointwise(x)))
        x = self.ca(x)
        x = self.sa(x)
        
        # 5) Pooling + Dropout
        x = self.pool(x)
        x = self.dropout(x)
        
        # 6) Reshape for GRU
        B, C, S_new, T_new = x.shape
        x = x.permute(0, 3, 1, 2).contiguous()
        x = x.view(B, T_new, C * S_new)
        
        # 7) GRU + Temporal Attention
        gru_out, _ = self.gru(x)
        features = self.temporal_attention(gru_out)  # (B, 64)
        
        # 8) Multi-Head Outputs
        base_embeddings = self.embedding_head(features)        # (B, 32)
        proj_embeddings = self.projection_head(base_embeddings)  # (B, 128)
        
        base_embeddings = F.normalize(base_embeddings, p=2, dim=1)
        proj_embeddings = F.normalize(proj_embeddings, p=2, dim=1)
        
        kinematics = self.kinematic_head(features)   # (B, 22)
        forces     = self.force_head(features)        # (B, 6)
        
        return proj_embeddings, base_embeddings, kinematics, forces
