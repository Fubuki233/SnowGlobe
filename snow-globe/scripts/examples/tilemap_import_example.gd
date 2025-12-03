extends Node

"""
TilemapImporter 使用示例
演示如何导入图片到 Isometric TileSet
"""

# 引用您的 TileMapLayer 节点 (如果场景中没有,会创建一个临时的)
@onready var tile_map_layer: TileMapLayer = get_node_or_null("BaseLayer")
func _ready():
	# 示例1: 创建新的 Isometric TileSet 并导入单张图片
	example_1_single_import()
	
	# 示例2: 批量导入多张图片
	#example_2_batch_import()
	
	# 示例3: 从文件夹导入所有图片
	#example_3_directory_import()
	
	# 示例4: 使用现有的 TileSet
	#example_4_use_existing_tileset()
	
	# 示例5: 加载已保存的 TileSet
	#example_5_load_saved_tileset()
	
	# 示例6: 导入到现有的 TileSet 文件
	#example_6_import_to_existing_tileset()

## 示例1: 导入单张图片
func example_1_single_import():
	print("\n===== 示例1: 单张图片导入 =====\n")
	
	# 创建 TileSet
	var tile_set = TilemapImporter.create_isometric_tileset()
	
	# 导入地形图 (256x256)
	TilemapImporter.import_image_to_tileset(
		tile_set,
		"res://Assets/Environments/2D_Isometric_Tile_Pack/Sprites/Grass/grass_01/grass_01_iso_tile_256_0.png", # 图片路径
		false, # 地形不需要碰撞
		"terrain_type", # 自定义数据名
		"grass", # 自定义数据值
		{"description": "草地地形", "category": "terrain"} # metadata
	)
	
	# 导入物体图 (其他尺寸) - 需要碰撞
	TilemapImporter.import_image_to_tileset(
		tile_set,
		"res://Assets/Environments/2D_Isometric_Tile_Pack/Sprites/Grass/grass_01/grass_01_iso_tile_256_02.png",
		true, # 需要碰撞体积
		"object_type",
		"character",
		{"description": "草地变体", "category": "terrain"}
	)
	
	# 导入物体图 - 不需要碰撞
	TilemapImporter.import_image_to_tileset(
		tile_set,
		"res://Assets/Environments/2D_Isometric_Tile_Pack/Objects/bones_object_04.png",
		false, # 不需要碰撞
		"object_type",
		"decoration",
		{"description": "骨头装饰", "category": "decoration"}
	)
	
	# 应用到 TileMapLayer
	if tile_map_layer:
		tile_map_layer.tile_set = tile_set
		print("\n✓ TileSet 已应用到 TileMapLayer")
		
		# 随机放置一些瓦片
		_place_random_tiles(tile_map_layer)
		
		# 保存 TileSet 到文件(持久化)
		TilemapImporter.save_tileset_to_file(tile_set, "res://Assets/tilesets/my_isometric_tileset.tres")
		print("提示: TileSet 已保存,现在可以在编辑器中直接使用该资源文件")
		
		# 演示通过 tile_id 放置瓦片
		_place_tiles_by_id(tile_map_layer)

## 辅助函数: 通过 tile_id 放置瓦片
func _place_tiles_by_id(tile_map: TileMapLayer):
	"""演示如何通过 tile_id 来放置特定的瓦片"""
	if not tile_map or not tile_map.tile_set:
		return
	
	print("\n=== 通过 tile_id 放置瓦片 ===")
	
	# 获取所有可用的 tile_id
	var all_tile_ids = TilemapImporter.get_all_tile_ids(tile_map.tile_set)
	print("可用的瓦片: %s" % all_tile_ids)
	
	# 通过名称放置特定瓦片
	if all_tile_ids.size() > 0:
		# 放置第一个瓦片到指定位置
		TilemapImporter.place_tile_by_id(tile_map, all_tile_ids[0], Vector2i(0, 0))
		
		# 如果有骨头装饰,放置到另一个位置
		if "bones_object_04" in all_tile_ids:
			TilemapImporter.place_tile_by_id(tile_map, "bones_object_04", Vector2i(2, 2))
		
		# 演示查找瓦片信息
		var tile_info = TilemapImporter.find_tile_by_id(tile_map.tile_set, all_tile_ids[0])
		if not tile_info.is_empty():
			print("瓦片信息: %s" % tile_info)


## 辅助函数: 随机放置瓦片
func _place_random_tiles(tile_map: TileMapLayer):
	"""在地图上随机放置瓦片"""
	if not tile_map or not tile_map.tile_set:
		return
	
	print("\n=== 随机放置瓦片 ===")
	
	# 获取所有可用的 source
	var tile_set = tile_map.tile_set
	var source_count = tile_set.get_source_count()
	
	if source_count == 0:
		print("没有可用的瓦片源")
		return
	
	# 在 10x10 的区域内随机放置 20 个瓦片
	var placed_count = 0
	for i in range(20):
		# 随机选择一个 source
		var source_id = tile_set.get_source_id(randi() % source_count)
		var source = tile_set.get_source(source_id)
		
		if source is TileSetAtlasSource:
			# 随机地图位置
			var map_pos = Vector2i(
				randi() % 10 - 5, # -5 到 4
				randi() % 10 - 5 # -5 到 4
			)
			
			# 放置瓦片 (使用 Vector2i(0,0) 因为每个图片都在独立的 Atlas 中)
			tile_map.set_cell(map_pos, source_id, Vector2i(0, 0))
			placed_count += 1
	
	print("已放置 %d 个瓦片" % placed_count)

## 示例2: 批量导入
func example_2_batch_import():
	print("\n===== 示例2: 批量导入 =====\n")
	
	var tile_set = TilemapImporter.create_isometric_tileset()
	
	# 配置数组
	var configs = [
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
		},
		{
			"path": "res://Assets/Roles/Actors/DefaultGirl/frame_002.png",
			"tile_id": Vector2i(3, 0),
			"need_collision": false,
			"custom_data": {"name": "object_type", "value": "decoration"}
		}
	]
	
	# 批量导入
	TilemapImporter.batch_import_images(tile_set, configs)
	
	# 应用
	if tile_map_layer:
		tile_map_layer.tile_set = tile_set

## 示例3: 从文件夹导入
func example_3_directory_import():
	print("\n===== 示例3: 文件夹导入 =====\n")
	
	var tile_set = TilemapImporter.create_isometric_tileset()
	
	# 导入整个文件夹
	TilemapImporter.import_from_directory(
		tile_set,
		"res://Assets/Roles/Actors/DefaultGirl/",
		true # 所有物体都需要碰撞
	)
	
	# 应用
	if tile_map_layer:
		tile_map_layer.tile_set = tile_set

## 示例4: 使用现有的 TileSet
func example_4_use_existing_tileset():
	print("\n===== 示例4: 使用现有 TileSet =====\n")
	
	# 如果 TileMapLayer 已经有 TileSet,直接使用它
	if tile_map_layer and tile_map_layer.tile_set:
		var existing_tileset = tile_map_layer.tile_set
		
		# 配置现有 TileSet 为 Isometric 模式
		TilemapImporter.setup_existing_tileset(existing_tileset)
		
		# 在现有 TileSet 上添加新瓦片
		TilemapImporter.import_image_to_tileset(
			existing_tileset,
			"res://Assets/Items/potion_health.png",
			true,
			"item_type",
			"potion"
		)
		
		print("✓ 已在现有 TileSet 上添加新瓦片")
	else:
		print("警告: TileMapLayer 没有现有的 TileSet")

## 示例5: 加载已保存的 TileSet
func example_5_load_saved_tileset():
	print("\n===== 示例5: 加载已保存的 TileSet =====\n")
	
	# 从文件加载之前保存的 TileSet
	var loaded_tileset = TilemapImporter.load_tileset_from_file("res://Assets/tilesets/my_isometric_tileset.tres")
	
	if loaded_tileset and tile_map_layer:
		tile_map_layer.tile_set = loaded_tileset
		print("✓ 已加载并应用保存的 TileSet")
		
		# 可以继续添加新瓦片
		TilemapImporter.import_image_to_tileset(
			loaded_tileset,
			"res://Assets/Items/potion_health.png",
			true,
			"item_type",
			"health_potion"
		)
		
		# 保存更新后的 TileSet
		TilemapImporter.save_tileset_to_file(loaded_tileset, "res://Assets/tilesets/my_isometric_tileset.tres")
		print("✓ 已更新并保存 TileSet")

## 示例6: 导入到现有的 TileSet 文件
func example_6_import_to_existing_tileset():
	print("\n===== 示例6: 导入到现有 TileSet 文件 =====\n")
	
	var tileset_path = "res://Assets/tilesets/my_isometric_tileset.tres"
	
	# 方法1: 导入单张图片到现有 TileSet
	TilemapImporter.import_to_existing_tileset(
		tileset_path,
		"res://Assets/Items/potion_health.png",
		true, # 需要碰撞
		"item_type",
		"health_potion",
		{"description": "生命药水", "category": "consumable"},
		true # 自动保存
	)
	
	# 方法2: 批量导入多张图片
	var images_to_import: Array[String] = [
		"res://Assets/Items/potion_health.png",
		"res://Assets/Environments/2D_Isometric_Tile_Pack/Objects/bones_object_04.png"
	]
	TilemapImporter.batch_import_to_existing_tileset(
		tileset_path,
		images_to_import,
		true, # 需要碰撞
		true # 自动保存
	)
	
	# 方法3: 从文件夹导入到现有 TileSet
	TilemapImporter.import_directory_to_existing_tileset(
		tileset_path,
		"res://Assets/Environments/2D_Isometric_Tile_Pack/Objects/",
		true, # 需要碰撞
		true # 自动保存
	)
	
	# 应用到地图
	if tile_map_layer:
		var loaded_tileset = TilemapImporter.load_tileset_from_file(tileset_path)
		if loaded_tileset:
			tile_map_layer.tile_set = loaded_tileset
			print("\n✓ 已应用更新后的 TileSet")

## 示例4: 在编辑器中手动调用
func manual_import_example():
	"""
	您也可以在编辑器中手动调用:
	1. 获取当前场景的 TileMapLayer 节点
	2. 调用 TilemapImporter 方法
	"""
	var tile_map = get_node("TileMapLayer") as TileMapLayer
	if not tile_map:
		push_error("找不到 TileMapLayer 节点")
		return
	
	# 如果还没有 TileSet,创建一个
	if not tile_map.tile_set:
		tile_map.tile_set = TilemapImporter.create_isometric_tileset()
	
	# 导入图片
	TilemapImporter.import_image_to_tileset(
		tile_map.tile_set,
		"res://your_image_path.png",
		true # 需要碰撞
	)
	
	print("导入完成!")
