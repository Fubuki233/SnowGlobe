# TileSet 资源文件夹

此文件夹用于存储生成的 TileSet 资源文件（.tres）。

## 使用方法

### 1. 生成 TileSet 并保存
```gdscript
# 创建 TileSet
var tile_set = TilemapImporter.create_isometric_tileset()

# 导入图片
TilemapImporter.import_image_to_tileset(
    tile_set,
    "res://path/to/image.png",
    Vector2i(0, 0),
    true
)

# 保存到文件(持久化)
TilemapImporter.save_tileset_to_file(tile_set, "res://Assets/tilesets/my_tileset.tres")
```

### 2. 在编辑器中使用保存的 TileSet

保存后的 `.tres` 文件可以：
- 在 Godot 编辑器的文件系统中直接看到
- 拖拽到 TileMapLayer 节点的 TileSet 属性上
- 在检查器中点击 TileSet 属性，选择 "Load" 加载该文件
- 在多个场景中重复使用

### 3. 在代码中加载保存的 TileSet
```gdscript
# 加载已保存的 TileSet
var loaded_tileset = TilemapImporter.load_tileset_from_file("res://Assets/tilesets/my_tileset.tres")

# 应用到 TileMapLayer
tile_map_layer.tile_set = loaded_tileset
```

### 4. 更新已保存的 TileSet
```gdscript
# 加载现有 TileSet
var tile_set = TilemapImporter.load_tileset_from_file("res://Assets/tilesets/my_tileset.tres")

# 添加新瓦片
TilemapImporter.import_image_to_tileset(
    tile_set,
    "res://path/to/new_image.png",
    Vector2i(0, 0),
    true
)

# 保存更新
TilemapImporter.save_tileset_to_file(tile_set, "res://Assets/tilesets/my_tileset.tres")
```

## 优势

✓ **持久化**: TileSet 保存为 .tres 文件，可以在编辑器中永久使用  
✓ **可复用**: 同一个 TileSet 可以在多个场景中使用  
✓ **可编辑**: 在 Godot 编辑器中可以直接查看和编辑  
✓ **版本控制**: .tres 文件可以被 Git 等版本控制系统管理  
✓ **资源引用**: 其他资源可以引用该 TileSet 文件
