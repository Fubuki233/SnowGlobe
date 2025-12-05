class_name AIItemLoader

"""
AI 物品加载器
功能:
1. 从 JSON 配置文件加载 AI 生成的物品
2. 实例化预制场景并应用参数
3. 支持从 user:// 路径加载图片（打包后可用）
"""

# 预制场景路径映射
const PRESET_PATHS = {
	"weapon": "res://scenes/item_presets/weapon_preset.tscn",
	"consumable": "res://scenes/item_presets/consumable_preset.tscn",
	"equipment": "res://scenes/item_presets/equipment_preset.tscn",
	"block": "res://scenes/item_presets/block_preset.tscn",
	"plant": "res://scenes/item_presets/plant_preset.tscn",
	"default": "res://scenes/item_presets/default_preset.tscn"
}

## 核心方法: 从 JSON 文件加载 AI 物品
static func load_ai_item(json_path: String) -> Node2D:
	"""
	从 JSON 配置文件加载并实例化物品
	
	参数:
		json_path: JSON 配置文件路径 (支持 res:// 和 user://)
	
	返回: 实例化的物品节点，失败返回 null
	"""
	# 1. 读取 JSON 配置
	var config = _load_json_config(json_path)
	if config.is_empty():
		push_error("无法加载 JSON 配置: %s" % json_path)
		return null
	
	print("\n=== 加载 AI 物品: %s ===" % config.get("display_name", "未命名"))
	
	# 2. 加载预制场景
	var preset_type = config.get("preset_type", "default")
	var instance = _instantiate_preset(preset_type)
	if not instance:
		push_error("无法实例化预制场景: %s" % preset_type)
		return null
	
	# 3. 设置基础属性
	instance.name = config.get("item_id", "ai_item")
	
	# 4. 加载并应用贴图
	var texture_path = config.get("texture_path", "")
	var animation_config = config.get("animation", {})
	if not texture_path.is_empty():
		_apply_texture(instance, texture_path, animation_config)
	
	# 4.5. 加载植物生长阶段动画（如果是植物类型）
	if preset_type == "plant":
		_setup_plant_animations(instance, config)
	
	# 5. 应用参数
	var parameters = config.get("parameters", {})
	_apply_parameters(instance, parameters)
	
	# 6. 生成碰撞体积（如果需要）
	var collision_config = config.get("collision", {})
	if collision_config.get("enabled", false):
		_generate_collision(instance, texture_path, collision_config)
	
	# 7. 配置组件
	var components = config.get("components", {})
	_configure_components(instance, components)
	
	print("✓ AI 物品加载成功: %s" % config.get("display_name", ""))
	return instance

## 批量加载 AI 物品
static func load_ai_items_batch(json_paths: Array) -> Array[Node2D]:
	"""
	批量加载多个 AI 物品
	
	参数:
		json_paths: JSON 文件路径数组
	
	返回: 实例化的物品节点数组
	"""
	var items: Array[Node2D] = []
	for path in json_paths:
		var item = load_ai_item(path)
		if item:
			items.append(item)
	return items

## 从目录加载所有 AI 物品
static func load_all_from_directory(directory_path: String) -> Array[Node2D]:
	"""
	从指定目录加载所有 JSON 配置的 AI 物品
	
	参数:
		directory_path: 目录路径 (如 "user://ai_items/")
	
	返回: 所有加载成功的物品节点数组
	"""
	var items: Array[Node2D] = []
	var dir = DirAccess.open(directory_path)
	
	if not dir:
		push_error("无法打开目录: %s" % directory_path)
		return items
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var full_path = directory_path.path_join(file_name)
			var item = load_ai_item(full_path)
			if item:
				items.append(item)
		file_name = dir.get_next()
	
	print("从目录 %s 加载了 %d 个 AI 物品" % [directory_path, items.size()])
	return items

## 辅助方法: 读取 JSON 配置
static func _load_json_config(json_path: String) -> Dictionary:
	"""读取并解析 JSON 配置文件"""
	if not FileAccess.file_exists(json_path):
		push_error("JSON 文件不存在: %s" % json_path)
		return {}
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("无法打开 JSON 文件: %s" % json_path)
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("JSON 解析失败 (行 %d): %s" % [json.get_error_line(), json.get_error_message()])
		return {}
	
	return json.data

## 辅助方法: 实例化预制场景
static func _instantiate_preset(preset_type: String) -> Node2D:
	"""根据类型实例化预制场景"""
	var preset_path = PRESET_PATHS.get(preset_type, PRESET_PATHS["default"])
	
	if not FileAccess.file_exists(preset_path):
		push_warning("预制场景不存在: %s，使用默认预制" % preset_path)
		preset_path = PRESET_PATHS["default"]
	
	var scene = load(preset_path) as PackedScene
	if not scene:
		push_error("无法加载预制场景: %s" % preset_path)
		return null
	
	var instance = scene.instantiate() as Node2D
	print("  实例化预制场景: %s" % preset_type)
	return instance

## 辅助方法: 应用贴图
static func _apply_texture(instance: Node2D, texture_path: String, animation_config: Dictionary = {}) -> void:
	"""加载并应用贴图到 Sprite2D 节点（支持网络图片和 GIF 动图）"""
	# 检查是否是网络图片
	if texture_path.begins_with("http://") or texture_path.begins_with("https://"):
		_load_texture_from_url(instance, texture_path, animation_config)
	else:
		var texture = _load_texture(texture_path, animation_config)
		if not texture:
			push_warning("无法加载贴图: %s" % texture_path)
			return
		_apply_texture_to_sprite(instance, texture, texture_path, animation_config)

## 辅助方法: 将贴图应用到 Sprite2D
static func _apply_texture_to_sprite(instance: Node2D, texture: Texture2D, texture_path: String, animation_config: Dictionary = {}) -> void:
	"""将贴图应用到实例的 Sprite2D 或 AnimatedSprite2D 节点"""
	# 检查是否是动画贴图
	var is_animated = animation_config.get("enabled", false)
	
	if is_animated:
		# 查找或创建 AnimatedSprite2D
		var animated_sprite = instance.get_node_or_null("AnimatedSprite2D")
		if not animated_sprite:
			animated_sprite = _find_node_by_type(instance, AnimatedSprite2D)
		
		if not animated_sprite:
			# 尝试将 Sprite2D 替换为 AnimatedSprite2D
			var sprite = instance.get_node_or_null("Sprite2D")
			if sprite:
				animated_sprite = AnimatedSprite2D.new()
				animated_sprite.name = "AnimatedSprite2D"
				animated_sprite.position = sprite.position
				var parent = sprite.get_parent()
				parent.remove_child(sprite)
				parent.add_child(animated_sprite)
				animated_sprite.owner = instance
				sprite.queue_free()
		
		if animated_sprite:
			# 设置 SpriteFrames
			var sprite_frames = SpriteFrames.new()
			var anim_name = animation_config.get("default_animation", "default")
			sprite_frames.add_animation(anim_name)
			
			# 如果是 AnimatedTexture，拆分每一帧
			if texture is AnimatedTexture:
				var frame_count = texture.frames
				for i in range(frame_count):
					var frame_texture = texture.get_frame_texture(i)
					if frame_texture:
						sprite_frames.add_frame(anim_name, frame_texture)
				# 设置 FPS
				var fps = animation_config.get("fps", 10.0)
				sprite_frames.set_animation_speed(anim_name, fps)
			else:
				# 普通贴图，单帧动画
				sprite_frames.add_frame(anim_name, texture)
			
			animated_sprite.sprite_frames = sprite_frames
			animated_sprite.animation = anim_name
			
			# 设置是否自动播放
			var autoplay = animation_config.get("autoplay", true)
			if autoplay:
				animated_sprite.play()
			
			print("已应用动画贴图: %s (帧数: %d)" % [texture_path.get_file(), sprite_frames.get_frame_count(anim_name)])
		else:
			push_warning("未找到 AnimatedSprite2D 节点，无法应用动画")
	else:
		# 查找 Sprite2D 节点
		var sprite = instance.get_node_or_null("Sprite2D")
		if not sprite:
			# 尝试递归查找
			sprite = _find_node_by_type(instance, Sprite2D)
		
		if sprite:
			sprite.texture = texture
			print("已应用贴图: %s" % texture_path.get_file())
		else:
			push_warning("未找到 Sprite2D 节点，无法应用贴图")

## 辅助方法: 从 URL 加载贴图
static func _load_texture_from_url(instance: Node2D, url: String, animation_config: Dictionary = {}) -> void:
	"""从网络 URL 异步加载贴图"""
	print("开始下载网络图片: %s" % url)
	
	# 创建 HTTPRequest 节点
	var http_request = HTTPRequest.new()
	instance.add_child(http_request)
	
	# 设置超时
	http_request.timeout = 30.0
	
	# 存储上下文数据到 HTTPRequest 的 meta
	http_request.set_meta("instance", instance)
	http_request.set_meta("url", url)
	http_request.set_meta("animation_config", animation_config)
	
	# 连接请求完成信号
	http_request.request_completed.connect(_on_texture_downloaded.bind(http_request))
	
	# 等待节点进入场景树后再发起请求
	if not http_request.is_inside_tree():
		await http_request.ready
	
	# 发起请求
	var error = http_request.request(url)
	if error != OK:
		push_error("  网络请求失败 (错误码: %d): %s" % [error, url])
		http_request.queue_free()

## 辅助方法: 处理下载完成的图片
static func _on_texture_downloaded(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray,
	http_request: HTTPRequest
) -> void:
	"""处理网络图片下载完成"""
	# 从 meta 获取上下文
	var instance: Node2D = http_request.get_meta("instance")
	var url: String = http_request.get_meta("url")
	var animation_config: Dictionary = http_request.get_meta("animation_config")
	
	# 清理 HTTPRequest
	http_request.queue_free()
	
	print("  网络请求完成 - 结果: %d, HTTP状态: %d, 数据大小: %d bytes" % [result, response_code, body.size()])
	
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("  网络图片下载失败 (结果码: %d): %s" % [result, url])
		return
	
	if response_code != 200:
		push_error("  HTTP 错误 (状态码: %d): %s" % [response_code, url])
		return
	
	if body.size() == 0:
		push_error("  下载的数据为空: %s" % url)
		return
	
	# 从字节数组创建图片
	var image = Image.new()
	var error: int
	
	# 根据 URL 扩展名判断格式
	var ext = url.get_extension().to_lower()
	print("  尝试解析图片格式: %s" % (ext if ext else "未知，将智能检测"))
	
	match ext:
		"png":
			error = image.load_png_from_buffer(body)
		"jpg", "jpeg":
			error = image.load_jpg_from_buffer(body)
		"webp":
			error = image.load_webp_from_buffer(body)
		_:
			# 未知格式，智能检测（常见网络图片多为 JPEG）
			print("  尝试 JPG 格式...")
			error = image.load_jpg_from_buffer(body)
			if error != OK:
				print("  JPG 解析失败，尝试 PNG...")
				error = image.load_png_from_buffer(body)
			if error != OK:
				print("  PNG 解析失败，尝试 WEBP...")
				error = image.load_webp_from_buffer(body)
	
	if error != OK:
		push_error("  图片解析失败 (错误码: %d): %s" % [error, url])
		return
	
	var texture = ImageTexture.create_from_image(image)
	_apply_texture_to_sprite(instance, texture, url, animation_config)
	print("✓ 网络图片加载成功: %dx%d" % [image.get_width(), image.get_height()])

## 辅助方法: 加载贴图
static func _load_texture(texture_path: String, animation_config: Dictionary = {}) -> Texture2D:
	"""
	从文件路径加载贴图
	支持 res:// (打包资源) 和 user:// (用户数据)
	支持 GIF 动图
	"""
	# 如果是 res:// 路径，直接加载
	if texture_path.begins_with("res://"):
		return load(texture_path) as Texture2D
	
	# 如果是 user:// 路径或绝对路径，从文件加载
	if not FileAccess.file_exists(texture_path):
		return null
	
	# 检查是否是 GIF 文件
	var ext = texture_path.get_extension().to_lower()
	if ext == "gif":
		return _load_gif_as_animated_texture(texture_path, animation_config)
	
	var image = Image.new()
	var error = image.load(texture_path)
	
	if error != OK:
		push_error("图片加载失败: %s" % texture_path)
		return null
	
	return ImageTexture.create_from_image(image)

## 辅助方法: 加载 GIF 为 AnimatedTexture
static func _load_gif_as_animated_texture(gif_path: String, animation_config: Dictionary) -> AnimatedTexture:
	"""加载 GIF 文件为 AnimatedTexture（Godot 原生不支持 GIF，需要手动拆帧）"""
	push_warning("Godot 原生不支持 GIF 动图，请将 GIF 拆分为帧序列或使用 AnimatedSprite2D")
	push_warning("尝试将 GIF 作为静态图片加载第一帧")
	
	# Godot 不支持直接加载 GIF，这里返回 null
	# 用户需要使用第三方工具拆帧或使用 APNG/WebP 动图
	return null

## 辅助方法: 应用参数
static func _apply_parameters(instance: Node, parameters: Dictionary) -> void:
	"""通过反射设置实例的属性"""
	if parameters.is_empty():
		return
	
	print("  应用参数:")
	for key in parameters:
		var value = parameters[key]
		
		# 尝试直接设置属性
		if key in instance:
			instance.set(key, value)
			print("    %s = %s" % [key, value])
		else:
			# 如果根节点没有该属性，尝试查找脚本中的属性
			var script_instance = instance.get_script()
			if script_instance:
				push_warning("    属性 '%s' 不存在于实例中，已跳过" % key)

## 辅助方法: 配置组件
static func _configure_components(instance: Node, components: Dictionary) -> void:
	"""启用/禁用可选组件节点"""
	if components.is_empty():
		return
	
	print("  配置组件:")
	for comp_name in components:
		var enabled = components[comp_name]
		var node = instance.get_node_or_null(comp_name)
		
		if node:
			# 对于 Node2D/Control，控制 visible
			if node is Node2D or node is Control:
				node.visible = enabled
			# 对于其他节点，控制 process_mode
			else:
				node.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
			
			print("    %s: %s" % [comp_name, "启用" if enabled else "禁用"])
		else:
			push_warning("    组件节点 '%s' 不存在" % comp_name)

## 辅助方法: 递归查找特定类型的节点
static func _find_node_by_type(root: Node, node_type) -> Node:
	"""递归查找第一个匹配类型的子节点"""
	for child in root.get_children():
		if is_instance_of(child, node_type):
			return child
		var found = _find_node_by_type(child, node_type)
		if found:
			return found
	return null

## 辅助方法: 设置植物生长阶段动画
static func _setup_plant_animations(instance: Node2D, config: Dictionary) -> void:
	"""
	为植物设置生长阶段动画
	根据 growth_stages 和 animations 数组自动分配
	"""
	var growth_stages = config.get("growth_stages", 4)
	var animations = config.get("animations", [])
	
	if animations.is_empty():
		print("  未提供植物动画序列")
		return
	
	var animated_sprite = instance.get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		animated_sprite = _find_node_by_type(instance, AnimatedSprite2D)
	
	if not animated_sprite:
		push_warning("  未找到 AnimatedSprite2D 节点，无法设置植物动画")
		return
	
	var sprite_frames = animated_sprite.sprite_frames
	if not sprite_frames:
		sprite_frames = SpriteFrames.new()
		animated_sprite.sprite_frames = sprite_frames
	
	# 根据动画数量和生长阶段数分配动画
	for stage in range(growth_stages):
		var anim_name = "stage_%d" % (stage + 1)
		
		# 如果动画已存在，跳过
		if sprite_frames.has_animation(anim_name):
			continue
		
		sprite_frames.add_animation(anim_name)
		
		# 计算应该使用哪个动画资源
		var anim_index = stage
		if stage >= animations.size():
			# 如果动画不足，使用最后一个动画
			anim_index = animations.size() - 1
		
		var anim_path = animations[anim_index]
		
		# 加载动画帧
		if anim_path is String:
			var texture = load(anim_path) as Texture2D
			if texture:
				sprite_frames.add_frame(anim_name, texture)
		elif anim_path is Array:
			# 如果是帧序列
			for frame_path in anim_path:
				var texture = load(frame_path) as Texture2D
				if texture:
					sprite_frames.add_frame(anim_name, texture)
	
	print("  已设置 %d 个生长阶段动画" % growth_stages)

## 辅助方法: 生成碰撞体积
static func _generate_collision(instance: Node2D, texture_path: String, collision_config: Dictionary) -> void:
	"""
	为物品生成碰撞体积
	支持从贴图自动追踪轮廓或使用简单形状
	"""
	var collision_type = collision_config.get("type", "auto")
	
	# 加载贴图用于轮廓追踪
	var texture = _load_texture(texture_path)
	if not texture and collision_type == "auto":
		push_warning("  无法加载贴图，跳过碰撞生成")
		return
	
	# 检查是否已经有碰撞体（预制场景中可能已存在）
	var existing_body = instance as PhysicsBody2D
	if not existing_body:
		existing_body = _find_node_by_type(instance, PhysicsBody2D)
	
	var collision_body: Node2D
	var is_new_body = false
	
	if existing_body:
		collision_body = existing_body
		print("  使用现有碰撞体")
	else:
		# 创建新的 Area2D（用于拾取检测）
		var area = Area2D.new()
		area.name = "CollisionArea"
		area.collision_layer = collision_config.get("layer", 8)
		area.collision_mask = collision_config.get("mask", 1)
		collision_body = area
		is_new_body = true
		print("  创建新碰撞体")
	
	# 生成碰撞形状
	match collision_type:
		"auto":
			_generate_auto_collision(collision_body, texture, collision_config)
		"circle":
			_generate_circle_collision(collision_body, collision_config)
		"rect":
			_generate_rect_collision(collision_body, collision_config)
		_:
			push_warning("  未知的碰撞类型: %s" % collision_type)
			return
	
	# 添加碰撞体到场景
	if is_new_body:
		instance.add_child(collision_body)
		collision_body.owner = instance

## 辅助方法: 自动追踪碰撞轮廓
static func _generate_auto_collision(body: Node2D, texture: Texture2D, config: Dictionary) -> void:
	"""从贴图自动追踪碰撞多边形"""
	if not texture:
		return
	
	var image = texture.get_image()
	if not image:
		return
	
	# 追踪轮廓生成多边形
	var polygon = _trace_contour(image, image.get_size())
	
	if polygon.size() < 3:
		push_warning("  无法生成有效的碰撞多边形，使用矩形碰撞")
		_generate_rect_collision(body, config)
		return
	
	# 创建碰撞多边形
	var collision_shape = CollisionPolygon2D.new()
	collision_shape.name = "CollisionPolygon"
	collision_shape.polygon = polygon
	
	body.add_child(collision_shape)
	collision_shape.owner = body
	
	print("  已生成自动碰撞体 (%d 顶点)" % polygon.size())

## 辅助方法: 追踪图片轮廓
static func _trace_contour(image: Image, image_size: Vector2i) -> PackedVector2Array:
	"""追踪图片轮廓生成碰撞多边形"""
	const ALPHA_THRESHOLD = 10 # 透明度阈值(0-255)
	
	var width = image.get_width()
	var height = image.get_height()
	var bounds = _get_opaque_bounds(image, ALPHA_THRESHOLD)
	
	if bounds.size.x == 0 or bounds.size.y == 0:
		return PackedVector2Array()
	
	var points = PackedVector2Array()
	var sample_step = max(2, int(min(bounds.size.x, bounds.size.y) / 8))
	
	# 上边
	for x in range(bounds.position.x, min(bounds.end.x, width), sample_step):
		var y = _find_top_edge(image, x, bounds.position.y, bounds.end.y, ALPHA_THRESHOLD)
		if y >= 0: points.append(Vector2(x - image_size.x / 2, y - image_size.y / 2))
	# 右边
	for y in range(bounds.position.y, min(bounds.end.y, height), sample_step):
		var x = _find_right_edge(image, y, bounds.position.x, bounds.end.x, ALPHA_THRESHOLD)
		if x >= 0: points.append(Vector2(x - image_size.x / 2, y - image_size.y / 2))
	# 下边
	for x in range(min(bounds.end.x - 1, width - 1), bounds.position.x - 1, -sample_step):
		var y = _find_bottom_edge(image, x, bounds.position.y, bounds.end.y, ALPHA_THRESHOLD)
		if y >= 0: points.append(Vector2(x - image_size.x / 2, y - image_size.y / 2))
	# 左边
	for y in range(min(bounds.end.y - 1, height - 1), bounds.position.y - 1, -sample_step):
		var x = _find_left_edge(image, y, bounds.position.x, bounds.end.x, ALPHA_THRESHOLD)
		if x >= 0: points.append(Vector2(x - image_size.x / 2, y - image_size.y / 2))
	
	var simplified = _simplify_polygon(points)
	if simplified.size() < 3: return PackedVector2Array()
	if _is_polygon_counter_clockwise(simplified): simplified.reverse()
	return simplified

## 辅助方法: 检查多边形方向
static func _is_polygon_counter_clockwise(points: PackedVector2Array) -> bool:
	var area = 0.0
	for i in range(points.size()):
		var p1 = points[i]
		var p2 = points[(i + 1) % points.size()]
		area += (p2.x - p1.x) * (p2.y + p1.y)
	return area > 0

## 辅助方法: 查找边缘像素
static func _find_top_edge(image: Image, x: int, y_min: int, y_max: int, threshold: int) -> int:
	for y in range(y_min, y_max):
		if image.get_pixel(x, y).a * 255 > threshold: return y
	return -1

static func _find_bottom_edge(image: Image, x: int, y_min: int, y_max: int, threshold: int) -> int:
	for y in range(y_max - 1, y_min - 1, -1):
		if image.get_pixel(x, y).a * 255 > threshold: return y
	return -1

static func _find_left_edge(image: Image, y: int, x_min: int, x_max: int, threshold: int) -> int:
	for x in range(x_min, x_max):
		if image.get_pixel(x, y).a * 255 > threshold: return x
	return -1

static func _find_right_edge(image: Image, y: int, x_min: int, x_max: int, threshold: int) -> int:
	for x in range(x_max - 1, x_min - 1, -1):
		if image.get_pixel(x, y).a * 255 > threshold: return x
	return -1

## 辅助方法: 简化多边形
static func _simplify_polygon(points: PackedVector2Array, epsilon: float = 2.0) -> PackedVector2Array:
	if points.size() < 3: return points
	var unique_points = PackedVector2Array()
	for i in range(points.size()):
		if unique_points.size() == 0 or points[i].distance_to(unique_points[-1]) > 0.5:
			unique_points.append(points[i])
	if unique_points.size() < 3: return unique_points
	var simplified = PackedVector2Array()
	simplified.append(unique_points[0])
	for i in range(1, unique_points.size() - 1):
		var prev = simplified[-1]
		var curr = unique_points[i]
		var next = unique_points[i + 1]
		var line_vec = next - prev
		var point_vec = curr - prev
		var line_len = line_vec.length()
		if line_len > 0:
			var dist = abs(line_vec.cross(point_vec)) / line_len
			if dist > epsilon: simplified.append(curr)
	simplified.append(unique_points[-1])
	return simplified

## 辅助方法: 获取不透明区域边界
static func _get_opaque_bounds(image: Image, threshold: int) -> Rect2i:
	var min_x = image.get_width()
	var min_y = image.get_height()
	var max_x = 0
	var max_y = 0
	var found_opaque = false
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a * 255 > threshold:
				found_opaque = true
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
	if not found_opaque: return Rect2i(0, 0, 0, 0)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

## 辅助方法: 生成圆形碰撞
static func _generate_circle_collision(body: Node2D, config: Dictionary) -> void:
	"""生成圆形碰撞"""
	var radius = config.get("radius", 32.0)
	
	var shape = CircleShape2D.new()
	shape.radius = radius
	
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape"
	collision_shape.shape = shape
	
	body.add_child(collision_shape)
	collision_shape.owner = body
	
	print("  已生成圆形碰撞体 (半径: %.1f)" % radius)

## 辅助方法: 生成矩形碰撞
static func _generate_rect_collision(body: Node2D, config: Dictionary) -> void:
	"""生成矩形碰撞"""
	var size = config.get("size", Vector2(64, 64))
	
	var shape = RectangleShape2D.new()
	shape.size = size
	
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape"
	collision_shape.shape = shape
	
	body.add_child(collision_shape)
	collision_shape.owner = body
	
	print("  已生成矩形碰撞体 (尺寸: %s)" % size)

## 便捷方法: 生成示例 JSON 配置
static func generate_example_json(save_path: String) -> bool:
	"""
	生成一个示例 JSON 配置文件
	
	参数:
		save_path: 保存路径 (如 "user://ai_items/example.json")
	
	返回: 是否成功
	"""
	var example_config = {
		"item_id": "magic_sword_001",
		"display_name": "炎之魔剑",
		"description": "燃烧着烈焰的魔法剑",
		"texture_path": "user://ai_items/textures/magic_sword_001.png",
		"preset_type": "weapon",
		"parameters": {
			"damage": 150,
			"fire_damage": 50,
			"durability": 200,
			"rarity": "legendary",
			"price": 5000,
			"weight": 3.5
		},
		"collision": {
			"enabled": true,
			"type": "auto", # auto/circle/rect
			"layer": 8,
			"mask": 1,
			"radius": 32.0, # 用于 circle 类型
			"size": Vector2(64, 64) # 用于 rect 类型
		},
		"components": {
			"ParticleEffect": true,
			"SoundEffect": true,
			"GlowEffect": true
		}
	}
	
	var json_string = JSON.stringify(example_config, "\t")
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if not file:
		push_error("无法创建示例 JSON 文件: %s" % save_path)
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("示例 JSON 已生成: %s" % save_path)
	return true
