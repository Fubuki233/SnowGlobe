# TileMap 导入工具使用指南

## 功能概述

这个工具可以自动将图片导入到 Isometric TileSet,并根据图片尺寸自动配置:

- **256x256 图片** → 地形层(最下层),无碰撞体积
- **其他尺寸图片** → 物体层,可选择是否需要碰撞体积
- **碰撞体积** → 自动排除透明区域,只为不透明部分生成碰撞

---

## 核心文件

1. **`scripts/utils/tilemap_importer.gd`** - 核心导入类
2. **`scripts/examples/tilemap_import_example.gd`** - 运行时使用示例
3. **`scripts/editor/tilemap_import_tool.gd`** - 编辑器工具

---

## 使用方法

### 方法1: 在编辑器中使用 (推荐)

1. 打开 `scripts/editor/tilemap_import_tool.gd`
2. 修改配置区域:

```gdscript
# 选择导入模式
var import_mode = ImportMode.BATCH  # SINGLE, BATCH, 或 DIRECTORY

# 配置要导入的图片
var batch_configs = [
	{
		"path": "res://your_terrain.png",  # 256x256 地形
		"tile_id": Vector2i(0, 0),
		"need_collision": false
	},
	{
		"path": "res://your_object.png",   # 其他尺寸物体
		"tile_id": Vector2i(1, 0),
		"need_collision": true  # 自动排除透明区域
	}
]
```

3. 点击 **文件 → 运行** (或按 `Ctrl+Shift+X`)
4. 保存场景 (`Ctrl+S`)

### 方法2: 在代码中使用

```gdscript
extends Node

@onready var tile_map_layer = $TileMapLayer

func _ready():
	# 创建 TileSet
	var tile_set = TilemapImporter.create_isometric_tileset()
	
	# 导入地形 (256x256)
	TilemapImporter.import_image_to_tileset(
		tile_set,
		"res://terrain_grass.png",
		Vector2i(0, 0),
		false  # 地形不需要碰撞
	)
	
	# 导入物体 (需要碰撞)
	TilemapImporter.import_image_to_tileset(
		tile_set,
		"res://tree.png",
		Vector2i(1, 0),
		true  # 自动生成碰撞,排除透明区域
	)
	
	# 应用到 TileMapLayer
	tile_map_layer.tile_set = tile_set
```

### 方法3: 批量导入

```gdscript
var configs = [
	{
		"path": "res://grass.png",
		"tile_id": Vector2i(0, 0),
		"need_collision": false,
		"custom_data": {"name": "terrain_type", "value": "grass"}
	},
	{
		"path": "res://stone.png",
		"tile_id": Vector2i(1, 0),
		"need_collision": false,
		"custom_data": {"name": "terrain_type", "value": "stone"}
	},
	{
		"path": "res://tree.png",
		"tile_id": Vector2i(2, 0),
		"need_collision": true,
		"custom_data": {"name": "object_type", "value": "obstacle"}
	}
]

TilemapImporter.batch_import_images(tile_set, configs)
```

### 方法4: 从整个文件夹导入

```gdscript
# 导入文件夹中所有图片
TilemapImporter.import_from_directory(
	tile_set,
	"res://Assets/Tiles/",
	true  # 所有物体都需要碰撞
)
```

---

## API 参考

### 主要方法

#### `import_image_to_tileset()`

导入单张图片到 TileSet

```gdscript
TilemapImporter.import_image_to_tileset(
	tile_set: TileSet,           # 目标 TileSet
	image_path: String,          # 图片路径 "res://..."
	tile_id: Vector2i,           # 瓦片坐标 Vector2i(x, y)
	need_collision: bool,        # 是否需要碰撞体积
	custom_data_name: String,    # 自定义数据名 (可选)
	custom_data_value: Variant   # 自定义数据值 (可选)
) -> bool
```

**返回**: 成功返回 `true`

#### `batch_import_images()`

批量导入多张图片

```gdscript
TilemapImporter.batch_import_images(
	tile_set: TileSet,
	image_configs: Array[Dictionary]
) -> int
```

**配置字典格式**:
```gdscript
{
	"path": "res://...",
	"tile_id": Vector2i(x, y),
	"need_collision": true/false,
	"custom_data": {
		"name": "data_name",
		"value": "data_value"
	}
}
```

**返回**: 成功导入的数量

#### `import_from_directory()`

从文件夹导入所有图片

```gdscript
TilemapImporter.import_from_directory(
	tile_set: TileSet,
	directory_path: String,
	need_collision_for_objects: bool
) -> int
```

**返回**: 导入的图片数量

#### `create_isometric_tileset()`

创建预配置的 Isometric TileSet

```gdscript
var tile_set = TilemapImporter.create_isometric_tileset()
```

---

## 碰撞体积生成规则

### 自动检测透明区域

1. **扫描图片所有像素**
2. **识别非透明像素** (Alpha > 10/255)
3. **计算边界框** (最小矩形包围非透明区域)
4. **生成矩形碰撞体** (排除透明边缘)

### 示例

```
原始图片 (64x64):
┌────────────┐
│▓▓▓▓░░░░░░░│  ▓ = 不透明
│▓▓▓▓░░░░░░░│  ░ = 透明
│▓▓▓▓░░░░░░░│
│░░░░░░░░░░░│
└────────────┘

生成的碰撞体:
┌────┐
│▓▓▓▓│ 只包围不透明区域
│▓▓▓▓│
│▓▓▓▓│
└────┘
```

---

## 自定义数据使用

### 设置自定义数据

```gdscript
TilemapImporter.import_image_to_tileset(
	tile_set,
	"res://grass.png",
	Vector2i(0, 0),
	false,
	"terrain_type",  # 自定义数据名
	"grass"          # 自定义数据值
)
```

### 读取自定义数据

```gdscript
# 在 TileMapLayer 中
var tile_data = tile_map_layer.get_cell_tile_data(Vector2i(x, y))
if tile_data:
	var terrain_type = tile_data.get_custom_data("terrain_type")
	print("地形类型: ", terrain_type)  # 输出: grass
```

---

## 完整示例

### 创建包含地形和物体的 TileSet

```gdscript
@tool
extends EditorScript

func _run():
	# 获取场景中的 TileMapLayer
	var scene = get_scene()
	var tile_map = scene.get_node("TileMapLayer")
	
	# 创建 TileSet
	var tile_set = TilemapImporter.create_isometric_tileset()
	
	# 导入地形层 (256x256)
	TilemapImporter.import_image_to_tileset(
		tile_set,
		"res://Assets/terrain_grass.png",
		Vector2i(0, 0),
		false,
		"terrain_type",
		"grass"
	)
	
	TilemapImporter.import_image_to_tileset(
		tile_set,
		"res://Assets/terrain_stone.png",
		Vector2i(1, 0),
		false,
		"terrain_type",
		"stone"
	)
	
	# 导入物体层 (其他尺寸, 需要碰撞)
	TilemapImporter.import_image_to_tileset(
		tile_set,
		"res://Assets/tree.png",
		Vector2i(0, 1),
		true,  # 碰撞体积自动排除透明区域
		"object_type",
		"obstacle"
	)
	
	TilemapImporter.import_image_to_tileset(
		tile_set,
		"res://Assets/flower.png",
		Vector2i(1, 1),
		false,  # 装饰物不需要碰撞
		"object_type",
		"decoration"
	)
	
	# 应用 TileSet
	tile_map.tile_set = tile_set
	
	print("✓ TileSet 导入完成!")
```

---

## 配置常量

可在 `tilemap_importer.gd` 中修改:

```gdscript
# 地形图片尺寸 (会被识别为地形层)
const TERRAIN_SIZE = Vector2i(256, 256)

# 透明度阈值 (0-255)
# 像素 Alpha 值大于此值才被视为不透明
const ALPHA_THRESHOLD = 10
```

---

## 注意事项

1. **图片格式**: 支持 PNG, JPG, JPEG, BMP, TGA, WebP
2. **透明度**: PNG 格式可以正确检测透明区域
3. **碰撞精度**: 当前使用边界框碰撞,未来可扩展为多边形碰撞
4. **性能**: 批量导入大量图片时可能需要一些时间
5. **保存**: 编辑器工具执行后记得保存场景

---

## 常见问题

### Q: 如何修改已导入的瓦片?

A: 再次调用 `import_image_to_tileset()` 使用相同的 `tile_id` 会覆盖原有设置

### Q: 碰撞体积不准确?

A: 调整 `ALPHA_THRESHOLD` 常量,或考虑手动编辑碰撞多边形

### Q: 如何删除已导入的瓦片?

A: 使用 `atlas_source.remove_tile(tile_id)`

### Q: 支持其他 TileSet 类型吗?

A: 可以,修改 `create_isometric_tileset()` 中的 `tile_shape` 和 `tile_layout`

---

## 进阶: 自定义碰撞生成

如需更精确的碰撞多边形,可以修改 `_generate_collision()` 方法:

```gdscript
# 示例: 使用多边形简化算法
static func _generate_advanced_collision(atlas_source, tile_id, image, image_size):
	# 1. 提取轮廓点
	var outline_points = _extract_outline(image)
	
	# 2. 简化多边形 (Douglas-Peucker 算法)
	var simplified = _simplify_polygon(outline_points)
	
	# 3. 设置碰撞
	atlas_source.set_tile_data(tile_id, 0, "physics_layer_0/polygon_0/points", simplified)
```

---

**工具版本**: 1.0  
**Godot 版本**: 4.3+  
**创建日期**: 2025-11-29
