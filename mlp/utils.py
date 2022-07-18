import torch
import numpy as np
import matplotlib.pylab as plt
# import d2lzh_pytorch as d2l
import tools


def xyplot(x_vals, y_vals, name):
    tools.set_figsize(figsize=(4, 2))
    plt.plot(x_vals.detach().numpy(), y_vals.detach().numpy())
    plt.xlabel('x')
    plt.ylabel(name+"(x)")
    plt.show()



