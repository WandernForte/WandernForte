import random

import torch


def data_iter(batch_size, features, labels, in_order=False):
    """
    :param batch_size: input batch 训练步长
    :param features: input data features
    :param labels: input labels
    :return:
    """
    num_examples = len(features)
    indices = list(range(num_examples))
    if in_order:
        random.shuffle(indices)
    for i in range(0, num_examples, batch_size):
        j = torch.LongTensor(indices[i:min(i + batch_size, num_examples)])# 最后一次可能不足一个batch
        yield features.index_select(0, j), labels.index_select(0, j)

