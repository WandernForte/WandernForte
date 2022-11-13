import torch
from torch import nn


# 基础模型， 使用mm进行矩阵乘法
def linreg(X, w, b):
    # print(X.dtype)
    return torch.mm(X, w) + b


# 损失函数
def square_loss(y_hat, y):
    return (y_hat - y.view(y_hat.size())) ** 2 / 2


# 优化算法
def sgd(params, lr, batch_size):
    for param in params:
        param.data -= lr * param.grad / batch_size


class LinearRegression(nn.Module):
    def __init__(self, n_features):
        super(LinearRegression, self).__init__()
        self.linear = nn.Linear(n_features, 1)

    def forward(self, x):
        return self.linear(x)
