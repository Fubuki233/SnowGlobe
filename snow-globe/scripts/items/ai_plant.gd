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
@export var fruit_scene_path: String = "" # 果实场景路径（AIFruit）
@export var fruit_yield: int = 1 # 每次采集获得的果实数量

# 关联的果实模板
var linked_fruit_template: PackedScene = null

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
@export var weight: float = 0.5 # 重量（kg）

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
	
	# 加载关联的果实模板
	if fruit_scene_path != "":
		_load_fruit_template()

func _load_fruit_template():
	"""加载关联的果实场景模板"""
	if ResourceLoader.exists(fruit_scene_path):
		linked_fruit_template = load(fruit_scene_path)
		if linked_fruit_template:
			print("  ✓ 植物已绑定果实: %s" % fruit_scene_path)
		else:
			push_warning("  ✗ 无法加载果实场景: %s" % fruit_scene_path)
	else:
		push_warning("  ✗ 果实场景不存在: %s" % fruit_scene_path)

# ==================== 背包检测方法 ====================

func is_in_inventory(character: Node = null) -> bool:
	"""检测物品是否在角色背包中"""
	if character:
		# 检测指定角色的背包
		if "inventory" in character and character.inventory:
			return character.inventory.has_item(display_name, 1)
		return false
	else:
		# 检测所有角色的背包
		return get_owner_character() != null

func get_owner_character() -> Node:
	"""获取拥有此物品的角色（遍历场景树查找）"""
	var root = get_tree().root if get_tree() else null
	if not root:
		return null
	
	var characters = _find_all_characters(root)
	for character in characters:
		if "inventory" in character and character.inventory:
			if character.inventory.has_item(display_name, 1):
				return character
	return null

func get_quantity_in_inventory(character: Node) -> int:
	"""获取物品在指定角色背包中的数量"""
	if not character or not "inventory" in character or not character.inventory:
		return 0
	return character.inventory.get_item_quantity(display_name)

func _find_all_characters(node: Node) -> Array:
	"""递归查找所有角色节点（拥有 inventory 属性的节点）"""
	var characters = []
	if "inventory" in node:
		characters.append(node)
	
	for child in node.get_children():
		characters.append_array(_find_all_characters(child))
	
	return characters

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

# 当前是否处于过渡动画状态
var _is_in_transition: bool = false
# idle 动画是否正在倒放
var _is_idle_reversed: bool = false
# 当前 idle 动画名称
var _current_idle_anim: String = ""

func _update_visual_stage() -> void:
	"""更新植物外观到当前阶段（播放过渡动画）"""
	if animated_sprite and animated_sprite.sprite_frames:
		# 确保信号只连接一次
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)
		
		# {植物id}_stage{X}_transition (过渡动画) / {植物id}_stage{X}_idle (循环动画)
		var transition_anim = "%s_stage%d_transition" % [name, current_stage + 1]
		var idle_anim = "%s_stage%d_idle" % [name, current_stage + 1]
		
		# 更新当前阶段的 idle 动画名称
		_current_idle_anim = idle_anim
		
		# 优先尝试新的 transition/idle 格式
		if animated_sprite.sprite_frames.has_animation(transition_anim):
			_is_in_transition = true
			_is_idle_reversed = false
			animated_sprite.animation = transition_anim
			animated_sprite.play()
			print("%s 播放过渡动画: %s" % [name, transition_anim])
			return
		elif animated_sprite.sprite_frames.has_animation(idle_anim):
			# 如果没有 transition 动画，直接播放 idle
			_start_idle_animation(idle_anim)
			return
		else:
			# 没有找到任何匹配的动画
			push_warning("%s: 未找到阶段 %d 的动画 (%s 或 %s)" % [name, current_stage + 1, transition_anim, idle_anim])

func _start_idle_animation(idle_anim: String) -> void:
	"""开始播放 idle 动画（乒乓循环的起点）"""
	_is_in_transition = false
	_is_idle_reversed = false
	_current_idle_anim = idle_anim
	animated_sprite.animation = idle_anim
	animated_sprite.frame = 0 # 确保从第一帧开始
	animated_sprite.play()
	print("%s 播放循环动画: %s" % [name, idle_anim])

func _on_animation_finished() -> void:
	"""动画播放完成回调"""
	if not animated_sprite:
		return
	
	var current_anim = animated_sprite.animation
	
	# 如果是过渡动画完成，切换到 idle
	if _is_in_transition:
		_is_in_transition = false
		if animated_sprite.sprite_frames.has_animation(_current_idle_anim):
			_start_idle_animation(_current_idle_anim)
		return
	
	# 如果是 idle 动画完成，进行乒乓循环
	if "_idle" in current_anim:
		_is_idle_reversed = not _is_idle_reversed
		var frame_count = animated_sprite.sprite_frames.get_frame_count(current_anim)
		if _is_idle_reversed:
			# 倒放：从最后一帧开始
			animated_sprite.frame = frame_count - 1
			animated_sprite.play_backwards()
		else:
			# 正放：从第一帧开始
			animated_sprite.frame = 0
			animated_sprite.play()

# 用于存储各阶段贴图（Sprite2D 回退方案，由 AIItemLoader 填充）
var stage_textures: Array[Texture2D] = []

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
	
	# 收集果实（如果有）- 生成果实实例并添加到背包
	if has_fruit and current_stage >= fruit_mature_stage and fruit_drop_mechanism == "采集后获得":
		if linked_fruit_template and harvester and "inventory" in harvester:
			# 实例化果实
			for i in range(fruit_yield):
				var fruit_instance = linked_fruit_template.instantiate()
				if fruit_instance:
					# 添加到采集者背包
					if harvester.inventory.add_item(fruit_instance, 1):
						products.append(fruit_instance.display_name)
						print("  ✓ 采集到果实: %s" % fruit_instance.display_name)
					else:
						# 背包满了，释放实例
						fruit_instance.queue_free()
						print("  ✗ 背包已满，无法收集果实")
		elif not fruit_item_id.is_empty():
			# 旧方式：仅返回ID
			products.append(fruit_item_id)
			print("采集到果实: %s" % fruit_item_id)
	
	# 收集采集产物
	products.append_array(harvest_products)
	
	harvested_count += 1
	cooldown_timer = harvest_cooldown
	
	var harvester_name = harvester.npc_name if harvester and "npc_name" in harvester else "未知"
	print("[采集] %s 采集了 %s，获得: %s" % [harvester_name, display_name, products])
	
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
