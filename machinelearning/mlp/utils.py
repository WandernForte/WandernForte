import torch
import numpy as np
import matplotlib.pylab as plt
from torch import nn
from torch.nn import init

from ..tools.LinearNet import FlattenLayer


# import d2lzh_pytorch as d2l


class Mlp(nn.Module):
    def __init__(self, in_channels, hidden_channels, out_channels):
        super(Mlp, self).__init__()
        self.block = nn.Sequential(
            FlattenLayer(),
            nn.Linear(in_channels, hidden_channels),
            nn.ReLU(),
            nn.Linear(hidden_channels, out_channels),
        )
        self.init_weights()

    def init_weights(self):
        for params in self.block.parameters():
            init.normal_(params, mean=0.01, std=0.01)

    def forward(self, input):
        return self.block(input)
