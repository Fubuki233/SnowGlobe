@tool
class_name TilemapImporter

"""
Tilemap 导入工具 - 用于处理 Isometric 瓦片地图
功能:
1. 导入图片并自动识别类型(256x256=地形, 其他=物体)
2. 为物体自动生成碰撞体积(排除透明区域)
3. 支持自定义碰撞设置
"""

enum TileType {
	TERRAIN, # 地形(256x256)
	OBJECT # 物体(其他尺寸)
}

# 配置常量
const TERRAIN_SIZE = Vector2i(256, 256)
const ALPHA_THRESHOLD = 10 # 透明度阈值(0-255)

## 核心方法:导入单张图片到 TileSet
static func import_image_to_tileset(
	tile_set: TileSet,
	image_path: String,
	need_collision: bool = true,
	custom_data_name: String = "",
	custom_data_value: Variant = "",
	metadata: Dictionary = {}
) -> bool:
	"""
	导入图片到 TileSet
	
	参数:
		tile_set: 目标 TileSet
		image_path: 图片路径 (res://...)
		need_collision: 是否需要碰撞体积
		custom_data_name: 自定义数据名称(如 "Block Name")
		custom_data_value: 自定义数据值
		metadata: 额外的元数据字典 (如 {"description": "草地瓦片"})
	
	返回: 是否成功
	"""
	# 加载图片
	var texture = load(image_path) as Texture2D
	if not texture:
		push_error("无法加载图片: " + image_path)
		return false
	
	var image = texture.get_image()
	var image_size = image.get_size()
	
	print("\n=== 导入图片 ===")
	print("路径: %s" % image_path)
	print("尺寸: %s" % image_size)
	
	# 确定瓦片类型
	var tile_type = _get_tile_type(image_size)
	print("类型: %s" % ("地形" if tile_type == TileType.TERRAIN else "物体"))
	
	# 获取或创建 TileSetAtlasSource
	var atlas_source = _get_or_create_atlas_source(tile_set, texture, image_size)
	if not atlas_source:
		push_error("无法创建 Atlas Source")
		return false
	
	# 对于单图片导入，瓦片ID总是 (0,0)
	# tile_id 参数用于未来扩展(如果需要使用图集)
	var actual_tile_id = Vector2i(0, 0)
	
	# 创建瓦片
	if not atlas_source.has_tile(actual_tile_id):
		atlas_source.create_tile(actual_tile_id)
		print("创建瓦片: %s (在 Atlas Source 中)" % actual_tile_id)
	
	# 设置自定义数据
	if not custom_data_name.is_empty():
		_set_custom_data(tile_set, atlas_source, actual_tile_id, custom_data_name, custom_data_value)
	
	# 设置元数据 (自动添加 tile_id)
	var tile_name = image_path.get_file().get_basename()
	var full_metadata = metadata.duplicate()
	full_metadata["tile_id"] = tile_name
	full_metadata["source_path"] = image_path
	_set_metadata(atlas_source, actual_tile_id, full_metadata)
	
	# 如果需要碰撞,生成碰撞体积(地形和物体都生成)
	if need_collision:
		_generate_collision(atlas_source, actual_tile_id, image, image_size)
	
	print("✓ 导入成功\n")
	return true

## 批量导入图片
static func batch_import_images(
	tile_set: TileSet,
	image_configs: Array[Dictionary]
) -> int:
	"""
	批量导入图片
	
	参数:
		tile_set: 目标 TileSet
		image_configs: 配置数组,每个元素包含:
			{
				"path": "res://...",
				"tile_id": Vector2i(x, y),
				"need_collision": true/false,
				"custom_data": {"name": "Block Name", "value": "Stone"}
			}
	
	返回: 成功导入的数量
	"""
	var success_count = 0
	
	for config in image_configs:
		var path = config.get("path", "")
		var need_collision = config.get("need_collision", true)
		var custom_data = config.get("custom_data", {})
		var metadata = config.get("metadata", {})
		
		var custom_name = custom_data.get("name", "")
		var custom_value = custom_data.get("value", "")
		
		if import_image_to_tileset(tile_set, path, need_collision, custom_name, custom_value, metadata):
			success_count += 1
	
	print("=== 批量导入完成 ===")
	print("成功: %d/%d" % [success_count, image_configs.size()])
	return success_count

## 辅助方法:判断瓦片类型
static func _get_tile_type(size: Vector2i) -> TileType:
	"""根据尺寸判断是地形还是物体"""
	if size == TERRAIN_SIZE:
		return TileType.TERRAIN
	return TileType.OBJECT

## 辅助方法:获取或创建 Atlas Source
static func _get_or_create_atlas_source(
	tile_set: TileSet,
	texture: Texture2D,
	tile_size: Vector2i
) -> TileSetAtlasSource:
	"""获取或创建 TileSetAtlasSource"""
	# 查找现有的 Atlas Source (必须纹理和尺寸都匹配)
	var next_source_id = 0
	for i in tile_set.get_source_count():
		var existing_id = tile_set.get_source_id(i)
		if existing_id >= next_source_id:
			next_source_id = existing_id + 1
			
		var source = tile_set.get_source(existing_id)
		if source is TileSetAtlasSource:
			var atlas = source as TileSetAtlasSource
			# 纹理和区域尺寸都必须匹配
			if atlas.texture == texture and atlas.texture_region_size == tile_size:
				print("使用现有 Atlas Source (ID: %d)" % existing_id)
				return atlas
	
	# 创建新的 Atlas Source
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.texture_region_size = tile_size
	
	var new_id = tile_set.add_source(atlas_source, next_source_id)
	print("创建新的 Atlas Source (ID: %d, 尺寸: %s)" % [new_id, tile_size])
	
	return atlas_source

## 辅助方法:设置元数据
static func _set_metadata(
	atlas_source: TileSetAtlasSource,
	tile_id: Vector2i,
	metadata: Dictionary
):
	"""设置瓦片的元数据"""
	var tile_data = atlas_source.get_tile_data(tile_id, 0)
	if tile_data:
		for key in metadata:
			tile_data.set_meta(key, metadata[key])
		print("设置元数据: %s" % metadata)

## 辅助方法:设置自定义数据
static func _set_custom_data(
	tile_set: TileSet,
	atlas_source: TileSetAtlasSource,
	tile_id: Vector2i,
	data_name: String,
	data_value: Variant
):
	"""设置瓦片的自定义数据"""
	# 确保自定义数据层存在
	var layer_index = -1
	for i in range(tile_set.get_custom_data_layers_count()):
		if tile_set.get_custom_data_layer_name(i) == data_name:
			layer_index = i
			break
	
	# 如果不存在,创建新层
	if layer_index == -1:
		layer_index = tile_set.get_custom_data_layers_count()
		tile_set.add_custom_data_layer(layer_index)
		tile_set.set_custom_data_layer_name(layer_index, data_name)
		tile_set.set_custom_data_layer_type(layer_index, typeof(data_value))
		print("创建自定义数据层: %s" % data_name)
	
	# 设置数据
	var tile_data = atlas_source.get_tile_data(tile_id, 0)
	if tile_data:
		tile_data.set_custom_data(data_name, data_value)
		print("设置自定义数据: %s = %s" % [data_name, data_value])

## 辅助方法:生成碰撞体积(排除透明区域)
static func _generate_collision(
	atlas_source: TileSetAtlasSource,
	tile_id: Vector2i,
	image: Image,
	image_size: Vector2i
):
	"""
	根据图片非透明区域生成碰撞多边形
	使用位图法检测边界
	"""
	print("生成碰撞体积...")
	
	# 创建物理层(如果不存在)
	var physics_layer = 0
	
	# 获取非透明像素的边界框
	var collision_rect = _get_opaque_bounds(image)
	if collision_rect.size.x == 0 or collision_rect.size.y == 0:
		print("  警告: 图片完全透明,跳过碰撞生成")
		return
	
	# 生成精细的碰撞多边形
	var polygon = _trace_contour(image, image_size)
	
	if polygon.size() < 3:
		print("  警告: 无法生成有效的碰撞多边形,使用矩形碰撞")
		# 回退到矩形碰撞
		polygon = PackedVector2Array([
			Vector2(collision_rect.position.x - image_size.x / 2, collision_rect.position.y - image_size.y / 2),
			Vector2(collision_rect.end.x - image_size.x / 2, collision_rect.position.y - image_size.y / 2),
			Vector2(collision_rect.end.x - image_size.x / 2, collision_rect.end.y - image_size.y / 2),
			Vector2(collision_rect.position.x - image_size.x / 2, collision_rect.end.y - image_size.y / 2)
		])
	
	# 设置碰撞多边形
	var tile_data = atlas_source.get_tile_data(tile_id, 0)
	if tile_data:
		var collision_polygon = tile_data.get_collision_polygons_count(physics_layer)
		if collision_polygon == 0:
			tile_data.add_collision_polygon(physics_layer)
		tile_data.set_collision_polygon_points(physics_layer, 0, polygon)
	
	print("碰撞体积: %d 个顶点" % polygon.size())

## 辅助方法:轮廓追踪生成精细多边形
static func _trace_contour(image: Image, image_size: Vector2i) -> PackedVector2Array:
	"""追踪图片轮廓生成精细碰撞多边形"""
	var width = image.get_width()
	var height = image.get_height()
	var bounds = _get_opaque_bounds(image)
	
	if bounds.size.x == 0 or bounds.size.y == 0:
		return PackedVector2Array()
	
	var points = PackedVector2Array()
	
	# 采样边界上的点以创建更精细的轮廓
	var sample_step = max(2, int(min(bounds.size.x, bounds.size.y) / 8))
	
	# 上边 (从左到右)
	for x in range(bounds.position.x, min(bounds.end.x, width), sample_step):
		var y = _find_top_edge(image, x, bounds.position.y, bounds.end.y)
		if y >= 0:
			points.append(Vector2(x - image_size.x / 2, y - image_size.y / 2))
	
	# 右边 (从上到下)
	for y in range(bounds.position.y, min(bounds.end.y, height), sample_step):
		var x = _find_right_edge(image, y, bounds.position.x, bounds.end.x)
		if x >= 0:
			points.append(Vector2(x - image_size.x / 2, y - image_size.y / 2))
	
	# 下边 (从右到左)
	for x in range(min(bounds.end.x - 1, width - 1), bounds.position.x - 1, -sample_step):
		var y = _find_bottom_edge(image, x, bounds.position.y, bounds.end.y)
		if y >= 0:
			points.append(Vector2(x - image_size.x / 2, y - image_size.y / 2))
	
	# 左边 (从下到上)
	for y in range(min(bounds.end.y - 1, height - 1), bounds.position.y - 1, -sample_step):
		var x = _find_left_edge(image, y, bounds.position.x, bounds.end.x)
		if x >= 0:
			points.append(Vector2(x - image_size.x / 2, y - image_size.y / 2))
	
	# 简化多边形(移除共线点)
	var simplified = _simplify_polygon(points)
	
	# 验证多边形有效性
	if simplified.size() < 3:
		return PackedVector2Array()
	
	# 确保多边形是顺时针方向(Godot要求)
	if _is_polygon_counter_clockwise(simplified):
		simplified.reverse()
	
	return simplified

## 辅助方法:检查多边形是否逆时针
static func _is_polygon_counter_clockwise(points: PackedVector2Array) -> bool:
	"""使用有向面积判断多边形方向"""
	var area = 0.0
	for i in range(points.size()):
		var p1 = points[i]
		var p2 = points[(i + 1) % points.size()]
		area += (p2.x - p1.x) * (p2.y + p1.y)
	return area > 0

## 辅助方法:查找边缘像素
static func _find_top_edge(image: Image, x: int, y_min: int, y_max: int) -> int:
	"""从上往下查找第一个不透明像素"""
	for y in range(y_min, y_max):
		var pixel = image.get_pixel(x, y)
		if pixel.a * 255 > ALPHA_THRESHOLD:
			return y
	return -1

static func _find_bottom_edge(image: Image, x: int, y_min: int, y_max: int) -> int:
	"""从下往上查找第一个不透明像素"""
	for y in range(y_max - 1, y_min - 1, -1):
		var pixel = image.get_pixel(x, y)
		if pixel.a * 255 > ALPHA_THRESHOLD:
			return y
	return -1

static func _find_left_edge(image: Image, y: int, x_min: int, x_max: int) -> int:
	"""从左往右查找第一个不透明像素"""
	for x in range(x_min, x_max):
		var pixel = image.get_pixel(x, y)
		if pixel.a * 255 > ALPHA_THRESHOLD:
			return x
	return -1

static func _find_right_edge(image: Image, y: int, x_min: int, x_max: int) -> int:
	"""从右往左查找第一个不透明像素"""
	for x in range(x_max - 1, x_min - 1, -1):
		var pixel = image.get_pixel(x, y)
		if pixel.a * 255 > ALPHA_THRESHOLD:
			return x
	return -1

## 辅助方法:简化多边形
static func _simplify_polygon(points: PackedVector2Array, epsilon: float = 2.0) -> PackedVector2Array:
	"""使用距离阈值简化多边形"""
	if points.size() < 3:
		return points
	
	# 移除重复点
	var unique_points = PackedVector2Array()
	for i in range(points.size()):
		if unique_points.size() == 0 or points[i].distance_to(unique_points[-1]) > 0.5:
			unique_points.append(points[i])
	
	if unique_points.size() < 3:
		return unique_points
	
	# 简单的距离阈值简化
	var simplified = PackedVector2Array()
	simplified.append(unique_points[0])
	
	for i in range(1, unique_points.size() - 1):
		var prev = simplified[-1]
		var curr = unique_points[i]
		var next = unique_points[i + 1]
		
		# 计算点到线段的距离
		var line_vec = next - prev
		var point_vec = curr - prev
		var line_len = line_vec.length()
		
		if line_len > 0:
			var dist = abs(line_vec.cross(point_vec)) / line_len
			if dist > epsilon:
				simplified.append(curr)
	
	simplified.append(unique_points[-1])
	
	return simplified

## 辅助方法:获取不透明区域的边界
static func _get_opaque_bounds(image: Image) -> Rect2i:
	"""获取图片中非透明像素的边界框"""
	var min_x = image.get_width()
	var min_y = image.get_height()
	var max_x = 0
	var max_y = 0
	
	var found_opaque = false
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel = image.get_pixel(x, y)
			if pixel.a * 255 > ALPHA_THRESHOLD: # 非透明像素
				found_opaque = true
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
	
	if not found_opaque:
		return Rect2i(0, 0, 0, 0)
	
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

## 便捷方法:创建 Isometric TileSet
static func create_isometric_tileset() -> TileSet:
	"""创建预配置的 Isometric TileSet"""
	var tile_set = TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tile_set.tile_size = TERRAIN_SIZE
	
	# 添加物理层
	tile_set.add_physics_layer(0)
	
	print("创建 Isometric TileSet")
	return tile_set

## 便捷方法:配置现有 TileSet 为 Isometric
static func setup_existing_tileset(tile_set: TileSet) -> void:
	"""
	配置现有的 TileSet 为 Isometric 模式
	
	参数:
		tile_set: 要配置的 TileSet
	"""
	if not tile_set:
		push_error("TileSet 为 null")
		return
	
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tile_set.tile_size = TERRAIN_SIZE
	
	# 如果没有物理层,添加一个
	if tile_set.get_physics_layers_count() == 0:
		tile_set.add_physics_layer(0)
		print("添加物理层到现有 TileSet")
	
	print("✓ 已配置现有 TileSet 为 Isometric 模式")

## 便捷方法:保存 TileSet 到文件
static func save_tileset_to_file(tile_set: TileSet, save_path: String) -> bool:
	"""
	将 TileSet 保存为 .tres 资源文件
	
	参数:
		tile_set: 要保存的 TileSet
		save_path: 保存路径 (如 "res://Assets/tilesets/my_tileset.tres")
	
	返回: 是否成功
	"""
	if not tile_set:
		push_error("TileSet 为 null")
		return false
	
	if not save_path.ends_with(".tres"):
		save_path += ".tres"
	
	var error = ResourceSaver.save(tile_set, save_path)
	if error == OK:
		print("✓ TileSet 已保存到: %s" % save_path)
		return true
	else:
		push_error("保存 TileSet 失败: %d" % error)
		return false

## 便捷方法:加载 TileSet 文件
static func load_tileset_from_file(load_path: String) -> TileSet:
	"""
	从文件加载 TileSet
	
	参数:
		load_path: 文件路径 (如 "res://Assets/tilesets/my_tileset.tres")
	
	返回: TileSet 或 null
	"""
	if not FileAccess.file_exists(load_path):
		push_error("文件不存在: %s" % load_path)
		return null
	
	var tile_set = load(load_path) as TileSet
	if tile_set:
		print("✓ 已加载 TileSet: %s" % load_path)
	else:
		push_error("加载 TileSet 失败")
	
	return tile_set

## 便捷方法:导入图片到现有 TileSet 文件
static func import_to_existing_tileset(
	tileset_path: String,
	image_path: String,
	need_collision: bool = true,
	custom_data_name: String = "",
	custom_data_value: Variant = "",
	metadata: Dictionary = {},
	auto_save: bool = true
) -> bool:
	"""
	导入图片到现有的 TileSet 文件,自动检测并避免重复导入
	
	参数:
		tileset_path: TileSet 文件路径 (如 "res://Assets/tilesets/my_tileset.tres")
		image_path: 图片路径 (res://...)
		need_collision: 是否需要碰撞体积
		custom_data_name: 自定义数据名称
		custom_data_value: 自定义数据值
		metadata: 额外的元数据字典
		auto_save: 是否自动保存 TileSet
	
	返回: 是否成功
	"""
	# 加载现有 TileSet
	var tile_set = load_tileset_from_file(tileset_path)
	if not tile_set:
		push_error("无法加载 TileSet: %s" % tileset_path)
		return false
	
	# 检查是否已存在相同图片
	var tile_name = image_path.get_file().get_basename()
	var existing_tile = find_tile_by_id(tile_set, tile_name)
	if not existing_tile.is_empty():
		print("警告: 瓦片 '%s' 已存在,跳过导入" % tile_name)
		return false
	
	# 导入新图片
	var success = import_image_to_tileset(
		tile_set,
		image_path,
		need_collision,
		custom_data_name,
		custom_data_value,
		metadata
	)
	
	if success and auto_save:
		# 保存更新后的 TileSet
		return save_tileset_to_file(tile_set, tileset_path)
	
	return success

## 辅助方法:判断是否为图片文件
static func _is_image_file(filename: String) -> bool:
	"""检查文件是否为图片"""
	var ext = filename.get_extension().to_lower()
	return ext in ["png", "jpg", "jpeg", "bmp", "tga", "webp"]

## 便捷方法:通过 tile_id 查找瓦片
static func find_tile_by_id(tile_set: TileSet, tile_id: String) -> Dictionary:
	"""
	通过 tile_id (图片名称) 查找瓦片
	
	参数:
		tile_set: TileSet
		tile_id: 瓦片ID (图片名称,不含扩展名)
	
	返回: 包含 source_id 和 atlas_coords 的字典,如果未找到则返回空字典
		{"source_id": int, "atlas_coords": Vector2i, "metadata": Dictionary}
	"""
	if not tile_set:
		return {}
	
	for source_id_index in tile_set.get_source_count():
		var source_id = tile_set.get_source_id(source_id_index)
		var source = tile_set.get_source(source_id)
		
		if source is TileSetAtlasSource:
			var atlas = source as TileSetAtlasSource
			# 遍历 atlas 中所有的瓦片坐标
			var grid_size = atlas.get_atlas_grid_size()
			for y in range(grid_size.y):
				for x in range(grid_size.x):
					var tile_coords = Vector2i(x, y)
					if atlas.has_tile(tile_coords):
						var tile_data = atlas.get_tile_data(tile_coords, 0)
						if tile_data and tile_data.has_meta("tile_id"):
							if tile_data.get_meta("tile_id") == tile_id:
								var metadata = {}
								for meta_key in tile_data.get_meta_list():
									metadata[meta_key] = tile_data.get_meta(meta_key)
								return {
									"source_id": source_id,
									"atlas_coords": tile_coords,
									"metadata": metadata
								}
	
	return {}

## 便捷方法:通过 tile_id 放置瓦片
static func place_tile_by_id(
	tile_map: TileMapLayer,
	tile_id: String,
	map_position: Vector2i
) -> bool:
	"""
	通过 tile_id 在地图上放置瓦片
	
	参数:
		tile_map: TileMapLayer
		tile_id: 瓦片ID (图片名称)
		map_position: 地图坐标
	
	返回: 是否成功放置
	"""
	if not tile_map or not tile_map.tile_set:
		push_error("TileMapLayer 或 TileSet 为 null")
		return false
	
	var tile_info = find_tile_by_id(tile_map.tile_set, tile_id)
	if tile_info.is_empty():
		push_error("找不到 tile_id: %s" % tile_id)
		return false
	
	tile_map.set_cell(map_position, tile_info["source_id"], tile_info["atlas_coords"])
	print("已放置瓦片 '%s' 到位置 %s" % [tile_id, map_position])
	return true

## 便捷方法:获取所有瓦片的 tile_id 列表
static func get_all_tile_ids(tile_set: TileSet) -> Array[String]:
	"""
	获取 TileSet 中所有瓦片的 tile_id 列表
	
	参数:
		tile_set: TileSet
	
	返回: tile_id 字符串数组
	"""
	var tile_ids: Array[String] = []
	
	if not tile_set:
		return tile_ids
	
	for source_id_index in tile_set.get_source_count():
		var source_id = tile_set.get_source_id(source_id_index)
		var source = tile_set.get_source(source_id)
		
		if source is TileSetAtlasSource:
			var atlas = source as TileSetAtlasSource
			# 遍历 atlas 中所有的瓦片坐标
			var grid_size = atlas.get_atlas_grid_size()
			for y in range(grid_size.y):
				for x in range(grid_size.x):
					var tile_coords = Vector2i(x, y)
					if atlas.has_tile(tile_coords):
						var tile_data = atlas.get_tile_data(tile_coords, 0)
						if tile_data and tile_data.has_meta("tile_id"):
							tile_ids.append(tile_data.get_meta("tile_id"))
	
	return tile_ids
