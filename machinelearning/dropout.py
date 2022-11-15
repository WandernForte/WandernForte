import torch
import torch.nn as nn

from d2lzh_pytorch import d2l

net = nn.Sequential(nn.Flatten(),
                    nn.Linear(784, 256),
                    nn.ReLU(),
                    nn.Dropout(0.1),
                    nn.Linear(256, 256),
                    nn.ReLU(),
                    nn.Dropout(0.3),
                    nn.Linear(256, 10))


def init_weights(m):
    if type(m) == nn.Linear:
        nn.init.normal_(m.weight, std=0.01)


num_epochs, lr, batch_size = 10, 0.01, 64
loss = nn.CrossEntropyLoss()
train_iter, test_iter = d2l.load_data_fashion_mnist(batch_size)
# trainer = torch.optim.SGD(net.parameters(), lr=lr)
# d2l.train_ch3(net, train_iter, test_iter, loss, num_epochs, trainer)
net.apply(init_weights)
trainer = torch.optim.SGD(net.parameters(), lr=lr)
d2l.train_ch3(net, train_iter, test_iter, loss, num_epochs, trainer)
