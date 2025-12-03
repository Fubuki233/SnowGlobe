@tool
extends EditorScript

"""
编辑器工具: TileSet 导入器
在 Godot 编辑器中运行此脚本来导入图片到 TileSet

使用方法:
1. 打开此脚本
2. 修改下方的配置
3. 点击 "文件" -> "运行" (或 Ctrl+Shift+X)
"""

# ========== 配置区域 ==========

# TileMapLayer 节点的路径 (相对于当前场景根节点)
const TILEMAP_NODE_PATH = "TileMapLayer"

# 导入模式
enum ImportMode {
	SINGLE, # 单张图片
	BATCH, # 批量导入
	DIRECTORY # 整个文件夹
}

# 选择模式
var import_mode = ImportMode.BATCH

# 单张图片配置 (当 import_mode = SINGLE 时使用)
var single_image_config = {
	"path": "res://Assets/Roles/Actors/DefaultGirl/frame_000.png",
	"tile_id": Vector2i(0, 0),
	"need_collision": true,
	"custom_data_name": "object_type",
	"custom_data_value": "character"
}

# 批量导入配置 (当 import_mode = BATCH 时使用)
var batch_configs = [
	{
		"path": "res://Assets/Environments/grass.jpg",
		"tile_id": Vector2i(0, 0),
		"need_collision": false,
		"custom_data": {"name": "terrain_type", "value": "grass"}
	},
	{
		"path": "res://Assets/Roles/Actors/DefaultGirl/frame_000.png",
		"tile_id": Vector2i(1, 0),
		"need_collision": true,
		"custom_data": {"name": "object_type", "value": "character"}
	},
	{
		"path": "res://Assets/Roles/Actors/DefaultGirl/frame_001.png",
		"tile_id": Vector2i(2, 0),
		"need_collision": true,
		"custom_data": {"name": "object_type", "value": "character"}
	}
]

# 文件夹导入配置 (当 import_mode = DIRECTORY 时使用)
var directory_config = {
	"path": "res://Assets/Roles/Actors/DefaultGirl/",
	"need_collision": true
}

# ========== 脚本执行 ==========

func _run():
	print("\n" + "=".repeat(60))
	print("TileSet 导入工具启动")
	print("=".repeat(60) + "\n")
	
	# 获取当前编辑的场景
	var scene_root = get_scene()
	if not scene_root:
		printerr("❌ 错误: 没有打开的场景")
		return
	
	print("当前场景: %s" % scene_root.name)
	
	# 获取 TileMapLayer 节点
	var tile_map_layer = scene_root.get_node_or_null(TILEMAP_NODE_PATH)
	if not tile_map_layer:
		printerr("❌ 错误: 找不到 TileMapLayer 节点: %s" % TILEMAP_NODE_PATH)
		return
	
	print("TileMapLayer: %s\n" % tile_map_layer.name)
	
	# 确保有 TileSet
	if not tile_map_layer.tile_set:
		print("创建新的 Isometric TileSet...")
		tile_map_layer.tile_set = TilemapImporter.create_isometric_tileset()
	
	var tile_set = tile_map_layer.tile_set
	
	# 根据模式执行导入
	match import_mode:
		ImportMode.SINGLE:
			_import_single(tile_set)
		ImportMode.BATCH:
			_import_batch(tile_set)
		ImportMode.DIRECTORY:
			_import_directory(tile_set)
	
	# 保存场景
	print("\n" + "=".repeat(60))
	print("✓ 导入完成!")
	print("=".repeat(60))
	print("\n提示: 记得保存场景 (Ctrl+S)\n")

# 单张导入
func _import_single(tile_set: TileSet):
	print("模式: 单张图片导入\n")
	
	TilemapImporter.import_image_to_tileset(
		tile_set,
		single_image_config["path"],
		single_image_config["need_collision"],
		single_image_config.get("custom_data_name", ""),
		single_image_config.get("custom_data_value", ""),
		single_image_config.get("metadata", {})
	)

# 批量导入
func _import_batch(tile_set: TileSet):
	print("模式: 批量导入")
	print("图片数量: %d\n" % batch_configs.size())
	
	TilemapImporter.batch_import_images(tile_set, batch_configs)

# 文件夹导入
func _import_directory(tile_set: TileSet):
	print("模式: 文件夹导入")
	print("路径: %s\n" % directory_config["path"])
	
	TilemapImporter.import_from_directory(
		tile_set,
		directory_config["path"],
		directory_config["need_collision"]
	)
