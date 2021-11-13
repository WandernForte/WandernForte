import torch
import torch.nn as nn
import torchvision.transforms as transforms
import torch.nn.functional as F
import sklearn
import torchvision
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import numpy as np
import cupy as cp
import gc
import pandas as pd
import os
import matplotlib.pyplot as plt
import PIL
import json
from PIL import Image, ImageEnhance
import albumentations as A
import mmdet
import mmcv
from albumentations.pytorch import ToTensorV2
import seaborn as sns
import glob
from pathlib import Path
import pycocotools
from pycocotools import mask
import numpy.random
import random
import cv2
import re
import shutil
from mmdet.datasets import build_dataset
from mmdet.models import build_detector
from mmdet.apis import train_detector
from mmdet.apis import inference_detector, init_detector, show_result_pyplot, set_random_seed


# The new config inherits a base config to highlight the necessary modification
_base_ = '../configs/mask_rcnn/mask_rcnn_r50_caffe_fpn_mstrain-poly_1x_coco.py'

# We also need to change the num_classes in head to match the dataset's annotation
model = dict(
    roi_head=dict(
        bbox_head=dict(num_classes=1),
        mask_head=dict(num_classes=1)))

# Modify dataset related settings
dataset_type = 'COCODataset'
classes = ('balloon',)
data = dict(
    train=dict(
        img_prefix='../resources/sartorius-cell-instance-segmentation/train/',
        classes=classes,
        ann_file='../resources/sartorius-cell-instance-segmentation/\
                 LIVECell_dataset_2021/annotations/LIVECell/livecell_coco_train.json')
    ,
    val=dict(
        img_prefix='../resources/sartorius-cell-instance-segmentation/train/',
        classes=classes,
        ann_file='../resources/sartorius-cell-instance-segmentation/\
                 LIVECell_dataset_2021/annotations/LIVECell/livecell_coco_val.json'),
    test=dict(
        img_prefix='../resources/sartorius-cell-instance-segmentation/train/',
        classes=classes,
        ann_file='../resources/sartorius-cell-instance-segmentation/\
                 LIVECell_dataset_2021/annotations/LIVECell/livecell_coco_val.json')
)

# We can use the pre-trained Mask RCNN model to obtain higher performance
load_from = '../checkpoints/mask_rcnn_r50_caffe_fpn_mstrain-poly\
                _3x_coco_bbox_mAP-0.408__segm_mAP-0.37_20200504_163245-42aa3d00.pth'


