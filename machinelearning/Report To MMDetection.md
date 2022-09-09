# REPORT To MMDetection

### 使用时需要注意的一些细节：

**MMDetection 目前仅支持评估 COCO 格式的数据集的掩码 AP。  因此，例如分割任务用户应该将数据转换为 coco 格式。 **

```python
#COCO注解格式
{
    "images": [image],
    "annotations": [annotation],
    "categories": [category]
}


image = {
    "id": int,
    "width": int,
    "height": int,
    "file_name": str,
}

annotation = {
    "id": int,
    "image_id": int,
    "category_id": int,
    "segmentation": RLE or [polygon],
    "area": float,
    "bbox": [x,y,width,height],#(x,y)表示box起点坐标，w,h表示box的大小
    "iscrowd": 0 or 1,
}

categories = [{
    "id": int,
    "name": str,
    "supercategory": str,
}]
```

**对应到我们这次比赛的csv，就是：**

```python
{
    "images": [image],
    "annotations": [annotation],
    "categories": [category]
}


image = {
    "id": int,
    "width": int,
    "height": int,
    "file_name": str,
}

annotation = {
    "id": int,
    "image_id": int,
    "sample_id": int,
    "segmentation": RLE or [polygon],
    "area": float,
    "bbox": [x,y,width,height],#(x,y)表示box起点坐标，w,h表示box的大小
    "iscrowd": 0 or 1,
}

categories = [{
    "id": int,
    "cell_type": str,
    "supercategory": str,
}]
#暂时不知道对不对，蛮写的
```



以下是对非coco格式的json数据集进行coco格式化


```python
import os.path as osp

def convert_balloon_to_coco(ann_file, out_file, image_prefix):
    data_infos = mmcv.load(ann_file)
	annotations = []
	images = []
	obj_count = 0
	for idx, v in enumerate(mmcv.track_iter_progress(data_infos.values())):
    	filename = v['filename']
    	img_path = osp.join(image_prefix, filename)
    	height, width = mmcv.imread(img_path).shape[:2]

    	images.append(dict(
        	id=idx,
        	file_name=filename,
        	height=height,
        	width=width))

    	bboxes = []
    	labels = []
    	masks = []
    	for _, obj in v['regions'].items():
        	assert not obj['region_attributes']
        	obj = obj['shape_attributes']
        	px = obj['all_points_x']
        	py = obj['all_points_y']
        	poly = [(x + 0.5, y + 0.5) for x, y in zip(px, py)]
        	poly = [p for x in poly for p in x]

        	x_min, y_min, x_max, y_max = (
            	min(px), min(py), max(px), max(py))
        	data_anno = dict(
            	image_id=idx,
            	id=obj_count,
            	category_id=0,
            	bbox=[x_min, y_min, x_max - x_min, y_max - y_min],
            	area=(x_max - x_min) * (y_max - y_min),
            	segmentation=[poly],
            	iscrowd=0)
        	annotations.append(data_anno)
        	obj_count += 1

	coco_format_json = dict(
    	images=images,
    	annotations=annotations,
    	categories=[{'id':0, 'name': 'balloon'}])
	mmcv.dump(coco_format_json, out_file)
```

### 那么有一个问题需要解决，我们可不可以把csv转成coco格式的？

# 关于csv标注框转成coco数据集风格的json文件

https://blog.csdn.net/baidu_38270845/article/details/95125971

以上，输入问题（可能）基本解决

### 导入新模型问题



