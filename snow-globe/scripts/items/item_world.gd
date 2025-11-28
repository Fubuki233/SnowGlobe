extends Node2D
class_name ItemWorld

"""
地图上的物品实体
负责在游戏世界中显示和交互物品
"""

signal item_picked_up(item: ItemBase, picker: Node)

# 物品数据
@export var item_data: ItemBase = null
@export var stack_count: int = 1

# 视觉设置
@export var bob_height: float = 5.0 # 上下浮动高度
@export var bob_speed: float = 2.0 # 浮动速度
@export var rotation_speed: float = 1.0 # 旋转速度

# 拾取设置
@export var pickup_radius: float = 50.0
@export var magnetic_radius: float = 100.0 # 磁力吸引范围
@export var magnetic_speed: float = 200.0 # 被吸引速度
@export var auto_pickup: bool = false # 自动拾取

# 内部变量
var time: float = 0.0
var initial_y: float = 0.0
var is_being_attracted: bool = false
var attraction_target: Node2D = null

# 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_area: Area2D = $Area2D
@onready var label: Label = $Label

func _ready() -> void:
	initial_y = position.y
	
	# 设置图标
	if item_data and item_data.icon:
		sprite.texture = item_data.icon
	
	# 设置标签
	update_label()
	
	# 连接信号
	if collision_area:
		collision_area.body_entered.connect(_on_body_entered)
		collision_area.body_exited.connect(_on_body_exited)
	
	# 设置碰撞范围
	if collision_area and collision_area.has_node("CollisionShape2D"):
		var collision_shape = collision_area.get_node("CollisionShape2D")
		if collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = pickup_radius

func _process(delta: float) -> void:
	time += delta
	
	if is_being_attracted and attraction_target:
		# 被吸引向目标移动
		var direction = (attraction_target.global_position - global_position).normalized()
		global_position += direction * magnetic_speed * delta
		
		# 检查是否足够接近
		if global_position.distance_to(attraction_target.global_position) < 10.0:
			pickup_item(attraction_target)
	else:
		# 浮动效果
		position.y = initial_y + sin(time * bob_speed) * bob_height
	
	# 旋转效果
	sprite.rotation += rotation_speed * delta

func update_label() -> void:
	"""更新显示标签"""
	if not label or not item_data:
		return
	
	if stack_count > 1:
		label.text = "%s x%d" % [item_data.item_name, stack_count]
	else:
		label.text = item_data.item_name
	
	# 根据品质设置颜色
	match item_data.rarity:
		ItemBase.Rarity.COMMON:
			label.modulate = Color.WHITE
		ItemBase.Rarity.UNCOMMON:
			label.modulate = Color.GREEN
		ItemBase.Rarity.RARE:
			label.modulate = Color.BLUE
		ItemBase.Rarity.EPIC:
			label.modulate = Color.PURPLE
		ItemBase.Rarity.LEGENDARY:
			label.modulate = Color.ORANGE

func _on_body_entered(body: Node2D) -> void:
	"""有物体进入拾取范围"""
	if body.has_method("pickup_item") or body.has_method("add_item_to_inventory"):
		if auto_pickup:
			pickup_item(body)
		else:
			# 显示拾取提示
			show_pickup_hint(true)

func _on_body_exited(body: Node2D) -> void:
	"""物体离开拾取范围"""
	if body == attraction_target:
		is_being_attracted = false
		attraction_target = null
	show_pickup_hint(false)

func show_pickup_hint(should_show: bool) -> void:
	"""显示/隐藏拾取提示"""
	if label:
		label.visible = should_show

func start_attraction(target: Node2D) -> void:
	"""开始被吸引向目标"""
	is_being_attracted = true
	attraction_target = target

func pickup_item(picker: Node2D) -> void:
	"""拾取物品"""
	if not item_data:
		queue_free()
		return
	
	# 尝试添加到拾取者的背包
	var success = false
	
	if picker.has_method("add_item_to_inventory"):
		success = picker.add_item_to_inventory(item_data, stack_count)
	elif picker.has_method("pickup_item"):
		success = picker.pickup_item(item_data, stack_count)
	else:
		# 默认处理：发出信号
		item_picked_up.emit(item_data, picker)
		success = true
	
	if success:
		# 播放拾取音效
		play_pickup_effect()
		# 移除物品
		queue_free()

func play_pickup_effect() -> void:
	"""播放拾取特效"""
	# 这里可以添加粒子效果、音效等
	print("拾取了: %s x%d" % [item_data.item_name, stack_count])

func set_item(item: ItemBase, count: int = 1) -> void:
	"""设置物品数据"""
	item_data = item
	stack_count = count
	if is_node_ready():
		if item.icon:
			sprite.texture = item.icon
		update_label()
