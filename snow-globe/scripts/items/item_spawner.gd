extends Node
class_name ItemSpawner

"""
物品生成器
用于在地图上生成物品
"""

# 物品场景预制体
const ITEM_WORLD_SCENE = preload("res://scripts/items/item_world.tscn")

# 如果没有预制体,使用代码创建
static func create_item_world_node() -> ItemWorld:
	"""创建物品世界节点"""
	var item_node = ItemWorld.new()
	
	# 创建精灵
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.modulate = Color(1, 1, 1, 0.9)
	item_node.add_child(sprite)
	
	# 创建碰撞区域
	var area = Area2D.new()
	area.name = "Area2D"
	area.collision_layer = 8
	area.collision_mask = 1
	item_node.add_child(area)
	
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var circle = CircleShape2D.new()
	circle.radius = 50.0
	collision.shape = circle
	area.add_child(collision)
	
	# 创建标签
	var label = Label.new()
	label.name = "Label"
	label.position = Vector2(-50, -40)
	label.size = Vector2(100, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_node.add_child(label)
	
	return item_node

static func spawn_item(item: ItemBase, world_position: Vector2, parent: Node, count: int = 1) -> ItemWorld:
	"""
	在指定位置生成物品
	
	参数:
		item: 物品数据
		world_position: 世界坐标位置
		parent: 父节点(通常是场景根节点)
		count: 堆叠数量
	
	返回:
		生成的ItemWorld节点
	"""
	var item_world: ItemWorld
	
	# 尝试使用预制体,否则代码创建
	if ResourceLoader.exists("res://scripts/items/item_world.tscn"):
		item_world = ITEM_WORLD_SCENE.instantiate()
	else:
		item_world = create_item_world_node()
	
	# 设置位置
	item_world.global_position = world_position
	
	# 设置物品数据
	item_world.set_item(item, count)
	
	# 添加到场景
	parent.add_child(item_world)
	
	return item_world

static func spawn_item_at_grid(item: ItemBase, grid_pos: Vector2i, tilemap: TileMapLayer, parent: Node, count: int = 1) -> ItemWorld:
	"""
	在指定网格位置生成物品
	
	参数:
		item: 物品数据
		grid_pos: 网格坐标
		tilemap: TileMapLayer引用
		parent: 父节点
		count: 堆叠数量
	"""
	var world_pos = tilemap.map_to_local(grid_pos)
	return spawn_item(item, world_pos, parent, count)

static func spawn_random_items(items: Array[ItemBase], count: int, area_rect: Rect2, parent: Node) -> Array[ItemWorld]:
	"""
	在指定区域随机生成多个物品
	
	参数:
		items: 物品数组
		count: 生成数量
		area_rect: 生成区域
		parent: 父节点
	
	返回:
		生成的所有ItemWorld节点数组
	"""
	var spawned_items: Array[ItemWorld] = []
	
	for i in range(count):
		var random_item = items[randi() % items.size()]
		var random_pos = Vector2(
			randf_range(area_rect.position.x, area_rect.position.x + area_rect.size.x),
			randf_range(area_rect.position.y, area_rect.position.y + area_rect.size.y)
		)
		
		var item_world = spawn_item(random_item, random_pos, parent)
		spawned_items.append(item_world)
	
	return spawned_items

static func drop_item_from_entity(item: ItemBase, entity: Node2D, parent: Node, count: int = 1, throw_force: float = 0.0) -> ItemWorld:
	"""
	从实体掉落物品(如怪物死亡掉落)
	
	参数:
		item: 物品数据
		entity: 掉落者
		parent: 父节点
		count: 数量
		throw_force: 抛出力度
	"""
	# 在实体位置生成物品,添加随机偏移
	var offset = Vector2(
		randf_range(-30, 30),
		randf_range(-30, 30)
	)
	var drop_pos = entity.global_position + offset
	
	var item_world = spawn_item(item, drop_pos, parent, count)
	
	# 如果有抛出力,可以添加抛物线效果
	if throw_force > 0:
		# 这里可以添加抛物线运动的代码
		pass
	
	return item_world
