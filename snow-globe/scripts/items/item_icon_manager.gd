class_name ItemIconManager
extends Resource

"""
物品图标管理器
统一管理和加载物品图标
"""

# 图标缓存
static var icon_cache: Dictionary = {}

# 图标路径配置
const ICON_BASE_PATH = "res://Assets/Items/"
const DEFAULT_ICON_PATH = "res://icon.svg"

# 图标尺寸预设
enum IconSize {
	SMALL = 32,
	MEDIUM = 64,
	LARGE = 128
}

# ============ 加载图标 ============

static func load_icon(icon_name: String) -> Texture2D:
	"""
	加载图标,自动使用缓存
	
	参数:
		icon_name: 图标文件名(不含路径)
	
	示例:
		load_icon("potion_health.png")
		load_icon("sword_iron.png")
	"""
	# 检查缓存
	if icon_cache.has(icon_name):
		return icon_cache[icon_name]
	
	# 尝试加载
	var full_path = ICON_BASE_PATH + icon_name
	if ResourceLoader.exists(full_path):
		var icon = ResourceLoader.load(full_path) as Texture2D
		icon_cache[icon_name] = icon
		return icon
	
	# 返回默认图标
	return get_default_icon()

static func load_icon_by_id(item_id: String) -> Texture2D:
	"""
	根据物品ID加载图标
	自动查找对应的图标文件
	
	支持的命名规则:
		item_id: "potion_health_001" -> 查找: "potion_health.png"
		item_id: "sword_iron" -> 查找: "sword_iron.png"
	"""
	var icon_name = item_id.replace("_001", "").replace("_002", "") + ".png"
	return load_icon(icon_name)

static func get_default_icon() -> Texture2D:
	"""获取默认图标"""
	if not icon_cache.has("default"):
		if ResourceLoader.exists(DEFAULT_ICON_PATH):
			icon_cache["default"] = ResourceLoader.load(DEFAULT_ICON_PATH)
		else:
			# 创建程序化默认图标
			icon_cache["default"] = create_default_icon()
	return icon_cache["default"]

# ============ 程序化生成图标 ============

static func create_default_icon() -> ImageTexture:
	"""创建默认问号图标"""
	var size = IconSize.MEDIUM
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# 填充背景
	image.fill(Color(0.3, 0.3, 0.3, 1.0))
	
	# 这里可以绘制问号或其他图案
	# 简单示例: 绘制边框
	for i in range(size):
		image.set_pixel(i, 0, Color.WHITE)
		image.set_pixel(i, size - 1, Color.WHITE)
		image.set_pixel(0, i, Color.WHITE)
		image.set_pixel(size - 1, i, Color.WHITE)
	
	return ImageTexture.create_from_image(image)

static func create_rarity_icon(rarity: ItemBase.Rarity, size: int = IconSize.MEDIUM) -> ImageTexture:
	"""根据品质创建图标"""
	var color = get_rarity_color(rarity)
	return create_colored_icon(color, size)

static func create_colored_icon(color: Color, size: int = IconSize.MEDIUM) -> ImageTexture:
	"""创建纯色图标"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

static func create_gradient_icon(color1: Color, color2: Color, size: int = IconSize.MEDIUM) -> ImageTexture:
	"""创建渐变图标"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	for y in range(size):
		var t = float(y) / float(size)
		var color = color1.lerp(color2, t)
		for x in range(size):
			image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

static func create_circle_icon(color: Color, size: int = IconSize.MEDIUM, with_border: bool = true) -> ImageTexture:
	"""创建圆形图标"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0 - 2
	
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			
			if distance <= radius:
				# 内部填充
				var alpha = 1.0 - (distance / radius) * 0.2
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
			elif with_border and distance <= radius + 2:
				# 边框
				image.set_pixel(x, y, Color.WHITE)
	
	return ImageTexture.create_from_image(image)

static func create_item_type_icon(item_type: ItemBase.ItemType, size: int = IconSize.MEDIUM) -> ImageTexture:
	"""根据物品类型创建图标"""
	var color: Color
	match item_type:
		ItemBase.ItemType.CONSUMABLE:
			color = Color.GREEN
		ItemBase.ItemType.WEAPON:
			color = Color.RED
		ItemBase.ItemType.ARMOR:
			color = Color.STEEL_BLUE
		ItemBase.ItemType.TOOL:
			color = Color.ORANGE
		ItemBase.ItemType.MATERIAL:
			color = Color.SADDLE_BROWN
		_:
			color = Color.GRAY
	
	return create_circle_icon(color, size)

# ============ 工具函数 ============

static func get_rarity_color(rarity: ItemBase.Rarity) -> Color:
	"""获取品质颜色"""
	match rarity:
		ItemBase.Rarity.COMMON:
			return Color.WHITE
		ItemBase.Rarity.UNCOMMON:
			return Color(0.12, 1, 0) # 绿色
		ItemBase.Rarity.RARE:
			return Color(0, 0.44, 0.87) # 蓝色
		ItemBase.Rarity.EPIC:
			return Color(0.64, 0.21, 0.93) # 紫色
		ItemBase.Rarity.LEGENDARY:
			return Color(1, 0.65, 0) # 橙色
		_:
			return Color.GRAY

static func clear_cache() -> void:
	"""清空图标缓存"""
	icon_cache.clear()

static func get_cache_size() -> int:
	"""获取缓存中的图标数量"""
	return icon_cache.size()

# ============ 批量处理 ============

static func preload_icons(icon_names: Array[String]) -> void:
	"""预加载多个图标"""
	for name in icon_names:
		load_icon(name)

static func create_icon_atlas(icons: Array[Texture2D], atlas_size: Vector2i) -> ImageTexture:
	"""
	创建图标图集(将多个图标合并到一张大图)
	用于优化渲染性能
	"""
	var icon_size = IconSize.MEDIUM
	var cols = atlas_size.x
	var rows = atlas_size.y
	var total_width = cols * icon_size
	var total_height = rows * icon_size
	
	var atlas_image = Image.create(total_width, total_height, false, Image.FORMAT_RGBA8)
	
	for i in range(min(icons.size(), cols * rows)):
		var col = i % cols
		var row = i / cols
		var x = col * icon_size
		var y = row * icon_size
		
		# 获取图标图像
		if icons[i]:
			var icon_image = icons[i].get_image()
			# 复制到图集
			atlas_image.blit_rect(icon_image, Rect2i(0, 0, icon_size, icon_size), Vector2i(x, y))
	
	return ImageTexture.create_from_image(atlas_image)
