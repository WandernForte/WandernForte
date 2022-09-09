from typing import Any

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torch import device
from torchvision import datasets, transforms

import d2lzh_pytorch
from mlp.utils import xyplot
from tools import train


class Net(nn.Module):
    def __init__(self):
        super(Net, self).__init__()
        self.conv1 = nn.Conv2d(24, 48, kernel_size=1)
        self.conv2 = nn.Conv2d(48, 24, kernel_size=1)
        self.drop = nn.Dropout2d()
        self.fc1 = nn.Linear(128, 64)
        self.fc2 = nn.Linear(64, 16)

    def forward(self, x):
        x = F.relu(F.max_pool2d(self.conv1(x), 2))
        x = F.relu(F.max_pool2d(self.drop(self.conv2(x)), 2))
        x = x.view(-1, 128)
        x = F.relu(self.fc1(x))
        x = F.dropout(x, training=self.training)
        x = self.fc2(x)
        return F.log_softmax(x, dim=1)


model = Net().to("cpu")
batch_size = 256
# train_iter, test_iter = d2lzh_pytorch.load_data_fashion_mnist(batch_size)
# x = torch.arange(-8.0, 8.0, 0.1, requires_grad=True)
# y = x.relu()
# xyplot(x, y, 'relu')
# num_inputs, num_outputs, num_hiddens = 784, 10, 256
# W1 = torch.tensor(np.random.normal(0, 0.01, (num_inputs, num_hiddens)), dtype=torch.float)
# b1 = torch.zeros(num_hiddens, dtype=torch.float)
# W2 = torch.tensor(np.random.normal(0, 0.01, (num_hiddens, num_outputs)), dtype=torch.float)
# b2 = torch.zeros(num_outputs, dtype=torch.float)
device = torch.device('cpu')
kwargs = {}
optimizer = torch.optim.SGD(model.parameters(), lr=0.5)
train_loader = torch.utils.data.DataLoader(
        datasets.MNIST('../data', train=True, download=True,
                       transform=transforms.Compose([
                           transforms.ToTensor(),
                           transforms.Normalize((0.1307,), (0.3081,))
                       ])), batch_size=batch_size, shuffle=True, **kwargs)
train(batch_size=batch_size, model=model, device=device,
      train_loader=train_loader, optimizer=optimizer, loss_func=torch.nn.CrossEntropyLoss(), epoch=10)
# params = [W1, b1, W2, b2]
#
# for param in params:
#     param.requires_grad_(requires_grad=True)

