extends TileMapLayer
var id = "tile_map_layer"
var a_star := AStarGrid2D.new()
var show_debug_grid = true # 是否显示调试网格

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GodotRPC.register_instance(id, self)
	
	# 确保获取正确的 tile_size
	var current_tile_size = tile_set.tile_size
	print("TileSet tile_size: ", current_tile_size)
	
	# 配置 A* 网格
	a_star.region = get_used_rect()
	a_star.cell_size = current_tile_size # 使用当前的 tile_size
	a_star.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	a_star.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	a_star.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	a_star.update()
	
	var used_rect = get_used_rect()
	for i in range(used_rect.position.x, used_rect.end.x):
		for j in range(used_rect.position.y, used_rect.end.y):
			var tile_pos = Vector2i(i, j)
			# 检查坐标是否在 A* 区域内
			if a_star.is_in_boundsv(tile_pos) and not is_walkable(tile_pos):
				a_star.set_point_solid(tile_pos)
	
	print("TileMapLayer ready")
	print("  Region: ", a_star.region)
	print("  Cell size: ", a_star.cell_size)
	print("  Offset: ", a_star.offset)

func get_random_walkable_position() -> Vector2:
	"""获取随机的可行走位置(世界坐标)"""
	var used_rect = get_used_rect()
	var max_attempts = 100
	
	for i in range(max_attempts):
		# 随机选择一个方块坐标
		var random_x = randi_range(used_rect.position.x, used_rect.end.x)
		var random_y = randi_range(used_rect.position.y, used_rect.end.y)
		var tile_pos = Vector2i(random_x, random_y)
		
		# 检查是否可行走
		if is_walkable(tile_pos):
			# 转换为世界坐标
			return tile_pos
	
	# 如果找不到,返回地图中心
	var center = used_rect.get_center()
	return Vector2i(center)

func is_walkable(tile_pos: Vector2i) -> bool:
	"""检查指定方块是否可行走"""
	var tile_data = get_cell_tile_data(tile_pos)
	
	if not tile_data:
		return false
	
	# 检查自定义数据层是否存在
	var block_name = ""
	if tile_set.get_custom_data_layer_by_name("Name") >= 0:
		var custom_name = tile_data.get_custom_data("Name")
		if custom_name != null:
			block_name = str(custom_name)
	
	# Grass 可行走, Stone 和 Sea 不可行走
	return block_name == "Grass"

func get_astar_path(from_grid: Vector2i, to_grid: Vector2i) -> PackedVector2Array:
	"""获取从起点到终点的路径(网格坐标输入,返回世界坐标路径)"""
	# 检查起点和终点是否在范围内
	if not a_star.is_in_boundsv(from_grid):
		print("警告: 起点 ", from_grid, " 超出 A* 范围 ", a_star.region)
		return PackedVector2Array()
	
	if not a_star.is_in_boundsv(to_grid):
		print("警告: 终点 ", to_grid, " 超出 A* 范围 ", a_star.region)
		return PackedVector2Array()
	
	# 检查起点和终点是否可行走
	if a_star.is_point_solid(from_grid):
		print("警告: 起点 ", from_grid, " 是障碍物")
		return PackedVector2Array()
	
	if a_star.is_point_solid(to_grid):
		print("警告: 终点 ", to_grid, " 是障碍物")
		return PackedVector2Array()
	
	# 使用 A* 计算路径
	var path_tiles = a_star.get_id_path(from_grid, to_grid)
	
	if path_tiles.size() == 0:
		print("警告: 无法找到从 ", from_grid, " 到 ", to_grid, " 的路径")
		return PackedVector2Array()
	
	# 转换为世界坐标
	var path_world = PackedVector2Array()
	for tile in path_tiles:
		path_world.append(map_to_local(tile))
	
	print("路径计算成功: ", from_grid, " -> ", to_grid, ", 步数: ", path_tiles.size())
	return path_world

func _draw():
	if not show_debug_grid:
		return
	
	var used_rect = get_used_rect()
	var current_tile_size = tile_set.tile_size # 使用当前的 tile_size
	
	# 绘制网格线
	for x in range(used_rect.position.x, used_rect.end.x + 1):
		for y in range(used_rect.position.y, used_rect.end.y + 1):
			var tile_pos = Vector2i(x, y)
			var world_pos = map_to_local(tile_pos)
			
			# 绘制网格边框
			var rect_pos = world_pos - Vector2(current_tile_size) / 2
			draw_rect(Rect2(rect_pos, current_tile_size), Color(0, 1, 0, 0.3), false, 1.0)
			
			if x % 2 == 0 and y % 2 == 0:
				var coord_text = "(%d,%d)" % [x, y]
				draw_string(ThemeDB.fallback_font, world_pos - Vector2(15, -5),
							coord_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 0))

func _process(_delta):
	pass

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_debug_grid()

func toggle_debug_grid():
	show_debug_grid = not show_debug_grid
	queue_redraw()
	
func get_nearby_blocks(pos: Array, radius: int) -> Array:
	var blocks = []
	var used_rect = get_used_rect()
	var x = pos[0]
	var y = pos[1]
	for ix in range(x - radius, x + radius + 1):
		for iy in range(y - radius, y + radius + 1):
			var tile_pos = Vector2i(ix, iy)
			if used_rect.has_point(tile_pos):
				var tile_data = get_cell_tile_data(tile_pos)
				if tile_data:
					blocks.append({
						"position": tile_pos,
						"block_name": tile_data.get_custom_data("Block Name")
					})
	return blocks
