from collections import OrderedDict

import numpy as np
import torch
import torchvision
import torchvision.transforms as transforms
import matplotlib.pyplot as plt
from torch import nn
from torch.nn import init

from datasets import show_fashion_mnist, get_fashion_mnist_labels
from machinelearning.mlp.utils import Mlp
from machinelearning.tools import LinearNet, FlattenLayer, train_ch3

mnist_train = torchvision.datasets.FashionMNIST(root="~/Datasets/FashionMNIST", train=True, download=True,
                                                transform=transforms.ToTensor())
mnist_test = torchvision.datasets.FashionMNIST(root="~/Datasets/FashionMNIST", train=False, download=True,
                                               transform=transforms.ToTensor())

X, y = [], []
for i in range(100):
    X.append(mnist_train[i][0])
    y.append(mnist_train[i][1])

# print(mnist_train)
# show_fashion_mnist(X, get_fashion_mnist_labels(y))
# export https_proxy=http://192.168.153.1:7890 http_proxy=http://192.168.153.1:7890 all_proxy=socks5://192.168.153.1:7891

batch_size = 256
num_workers = 4

train_iter = torch.utils.data.DataLoader(mnist_train, batch_size, shuffle=True, num_workers=num_workers)
test_iter = torch.utils.data.DataLoader(mnist_test, batch_size, shuffle=False, num_workers=num_workers)

input_ch = 784
output_ch = 10
W = torch.tensor(np.random.normal(0, 0.01, (input_ch, output_ch)), dtype=torch.float)
b = torch.zeros(output_ch, dtype=torch.float)
num_epochs, lr = 5, 0.01

# net = LinearNet(input_ch, output_ch)
net = Mlp(input_ch, output_ch, output_ch)

# init.normal_(net.linear.weight, mean=0, std=0.01)
# init.constant_(net.linear.bias, val=0)

loss = nn.CrossEntropyLoss()
optimizer = torch.optim.SGD(net.parameters(), lr=0.1)
train_ch3(net, train_iter, test_iter, loss, num_epochs,
          batch_size, None, None, optimizer)
