extends Node2D
class_name AIPlant

"""
AI 生成的植物基础脚本
支持完整的植物生命周期、生长、采集系统
"""

# ==================== 基础信息 ====================
@export var display_name: String = "未命名植物"
@export_multiline var description: String = "这是一株普通的植物"

# ==================== 基础参数 ====================
@export_enum("草", "树", "仙人掌") var plant_type: String = "草"
@export var growth_stages: int = 4
@export var current_stage: int = 0
@export var has_fruit: bool = false
@export var lifespan: float = 100.0 # 游戏刻或小时
@export var death_texture_path: String = ""

# 产物配置
@export var harvest_products: Array[String] = [] # 采集产物
@export var chop_products: Array[String] = [] # 砍伐产物（仅树类）

# ==================== 生长环境 ====================
@export_group("生长环境")
@export_enum("沙土", "壤土", "岩石") var soil_type: String = "壤土"
@export var humidity_min: float = 30.0
@export var humidity_max: float = 70.0
@export var temperature_min: float = 10.0
@export var temperature_max: float = 30.0

# ==================== 果实相关 ====================
@export_group("果实属性")
@export var fruit_mature_stage: int = -1 # 果实成熟阶段（-1 表示无果实）
@export_enum("自动掉落", "采集后获得") var fruit_drop_mechanism: String = "采集后获得"
@export var fruit_item_id: String = "" # 果实物品 ID

# ==================== 采集与交互 ====================
@export_group("采集交互")
@export_enum("无需工具", "镰刀", "斧头", "锄头") var tool_required: String = "无需工具"
@export var harvest_times: int = 1 # 可采集次数（0 = 无限）
@export var harvest_cooldown: float = 0.0 # 采集冷却时间
@export var special_event: String = "" # 特殊交互事件

# ==================== 枯死与生命周期 ====================
@export_group("生命周期")
@export_enum("寿命耗尽", "季节结束", "环境不适") var death_condition: String = "寿命耗尽"
@export var remains: String = "" # 残留物（树桩、干草等）
@export var is_dead: bool = false

# ==================== 特殊属性 ====================
@export_group("特殊属性")
@export_enum("普通", "稀有", "史诗") var rarity: String = "普通"
@export_enum("药材", "食材", "建材", "观赏") var usage: String = "观赏"
@export var regeneration: bool = false # 再生能力

# ==================== 内部状态 ====================
var age: float = 0.0 # 当前年龄
var growth_timer: float = 0.0
var harvested_count: int = 0
var cooldown_timer: float = 0.0
var animated_sprite: AnimatedSprite2D = null

func _ready() -> void:
	print("植物已创建: %s (类型: %s, 生长阶段: %d)" % [name, plant_type, growth_stages])
	
	# 查找 AnimatedSprite2D 节点
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		animated_sprite = _find_node_by_type(self, AnimatedSprite2D)
	
	# 设置初始阶段
	_update_visual_stage()

func _process(delta: float) -> void:
	if is_dead:
		return
	
	# 更新年龄
	age += delta
	
	# 检查是否达到寿命
	if lifespan > 0 and age >= lifespan:
		_die()
		return
	
	# 生长逻辑（简化版，实际可根据环境条件调整）
	if current_stage < growth_stages - 1:
		growth_timer += delta
		var stage_duration = lifespan / growth_stages if lifespan > 0 else 10.0
		if growth_timer >= stage_duration:
			_grow_to_next_stage()
			growth_timer = 0.0
	
	# 果实自动掉落逻辑
	if has_fruit and fruit_drop_mechanism == "自动掉落" and current_stage >= fruit_mature_stage:
		_auto_drop_fruit(delta)
	
	# 采集冷却计时
	if cooldown_timer > 0:
		cooldown_timer -= delta

func _grow_to_next_stage() -> void:
	"""进入下一个生长阶段"""
	if current_stage >= growth_stages - 1:
		return
	
	current_stage += 1
	_update_visual_stage()
	print("%s 进入生长阶段 %d/%d" % [name, current_stage + 1, growth_stages])
	
	# 检查是否到达果实成熟阶段
	if has_fruit and current_stage == fruit_mature_stage:
		print("%s 的果实已成熟！" % name)

func _update_visual_stage() -> void:
	"""更新植物外观到当前阶段"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	# 尝试播放对应阶段的动画
	var anim_name = "stage_%d" % (current_stage + 1)
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.animation = anim_name
		animated_sprite.play()
	else:
		# 如果没有对应动画，尝试使用默认动画
		if animated_sprite.sprite_frames.has_animation("default"):
			animated_sprite.animation = "default"
			animated_sprite.frame = min(current_stage, animated_sprite.sprite_frames.get_frame_count("default") - 1)

func harvest(harvester: Node = null) -> Array:
	"""采集植物"""
	if is_dead:
		print("%s 已经枯死，无法采集" % name)
		return []
	
	# 检查采集次数限制
	if harvest_times > 0 and harvested_count >= harvest_times:
		print("%s 已达到最大采集次数" % name)
		return []
	
	# 检查冷却时间
	if cooldown_timer > 0:
		print("%s 采集冷却中，剩余时间: %.1f 秒" % [name, cooldown_timer])
		return []
	
	# 检查工具需求
	if tool_required != "无需工具" and harvester:
		if not _has_required_tool(harvester):
			print("需要工具: %s" % tool_required)
			return []
	
	var products = []
	
	# 收集果实（如果有）
	if has_fruit and current_stage >= fruit_mature_stage and fruit_drop_mechanism == "采集后获得":
		if not fruit_item_id.is_empty():
			products.append(fruit_item_id)
			print("采集到果实: %s" % fruit_item_id)
	
	# 收集采集产物
	products.append_array(harvest_products)
	
	harvested_count += 1
	cooldown_timer = harvest_cooldown
	
	print("%s 采集完成，获得: %s" % [name, products])
	
	# 如果是一次性采集，采集后死亡
	if harvest_times == 1:
		_die()
	
	return products

func chop(chopper: Node = null) -> Array:
	"""砍伐植物（仅树类）"""
	if plant_type != "树":
		print("只有树木才能被砍伐")
		return []
	
	if is_dead:
		print("%s 已经枯死" % name)
		return []
	
	# 检查工具（砍伐通常需要斧头）
	if chopper and not _has_required_tool(chopper, "斧头"):
		print("砍伐需要斧头")
		return []
	
	var products = chop_products.duplicate()
	
	print("%s 被砍伐，获得: %s" % [name, products])
	_die()
	
	return products

func _die() -> void:
	"""植物枯死"""
	if is_dead:
		return
	
	is_dead = true
	print("%s 已枯死 (原因: %s)" % [name, death_condition])
	
	# 应用枯死贴图
	if not death_texture_path.is_empty():
		_apply_death_texture()
	
	# 生成残留物
	if not remains.is_empty():
		_spawn_remains()
	
	# 如果有再生能力，可以在此添加重生逻辑
	if regeneration:
		# TODO: 添加重生逻辑
		pass

func _apply_death_texture() -> void:
	"""应用枯死贴图"""
	var texture = load(death_texture_path) as Texture2D
	if texture and animated_sprite:
		# 停止动画，显示枯死贴图
		animated_sprite.stop()
		var sprite = get_node_or_null("Sprite2D")
		if not sprite:
			sprite = Sprite2D.new()
			add_child(sprite)
		sprite.texture = texture
		if animated_sprite:
			animated_sprite.visible = false

func _spawn_remains() -> void:
	"""生成残留物（树桩、干草等）"""
	print("生成残留物: %s" % remains)
	# TODO: 实例化残留物节点

func _auto_drop_fruit(delta: float) -> void:
	"""自动掉落果实逻辑"""
	# TODO: 实现果实自动掉落
	pass

func _has_required_tool(user: Node, required_tool: String = "") -> bool:
	"""检查用户是否有所需工具"""
	var tool = required_tool if not required_tool.is_empty() else tool_required
	
	if tool == "无需工具":
		return true
	
	# 检查用户背包中是否有所需工具
	if "inventory" in user:
		# TODO: 实现背包检查逻辑
		return true
	
	return false

func _find_node_by_type(root: Node, node_type) -> Node:
	"""递归查找特定类型的节点"""
	for child in root.get_children():
		if is_instance_of(child, node_type):
			return child
		var found = _find_node_by_type(child, node_type)
		if found:
			return found
	return null

func get_info() -> Dictionary:
	"""获取植物信息"""
	return {
		"name": name,
		"type": plant_type,
		"stage": "%d/%d" % [current_stage + 1, growth_stages],
		"age": age,
		"lifespan": lifespan,
		"is_dead": is_dead,
		"has_fruit": has_fruit,
		"can_harvest": harvest_times == 0 or harvested_count < harvest_times,
		"rarity": rarity,
		"usage": usage
	}
