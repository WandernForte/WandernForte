import torch
from IPython import display
from matplotlib import pyplot as plt
import numpy as np
import random
from datasets.linear_reg import data_iter
from machinelearning.tools.linreg import linreg, square_loss, sgd

num_inputs = 2
num_examples = 1000
true_w = [2, -3.4]
# test = torch.from_numpy(np.random.normal(0, 1, (5, 5)))
true_b = 4.2
features = torch.from_numpy(np.random.normal(0, 1, (num_examples, num_inputs))).type(torch.float32)

# print(test)
# print(test[0, :]) # 相当于第0列
labels = true_w[0] * features[:, 0] + true_w[1] * features[:, 1] + true_b
labels += torch.from_numpy(np.random.normal(0, 0.01, size=labels.size()))

batch_size = 10

# for X, y in data_iter(batch_size, features, labels, in_order=True):
#     print(X, y)
#     break

w = torch.tensor(np.random.normal(0, 0.01, (num_inputs, 1)), dtype=torch.float32)
b = torch.zeros(1, dtype=torch.float32)
w.requires_grad_(requires_grad=True)
b.requires_grad_(requires_grad=True)


lr = 5e-2
# 迭代周期数
num_epochs = 3
net = linreg
loss = square_loss
for epoch in range(num_epochs):
    for(X, y) in data_iter(batch_size, features, labels):
        l = loss(net(X, w, b), y).sum()
        l.backward()
        sgd([w, b], lr, batch_size)
        w.grad.data.zero_()
        b.grad.data.zero_()
    train_l = loss(net(features, w, b), labels)
    print("epoch:{}, loss:{}".format(epoch+1, train_l.mean().item()))