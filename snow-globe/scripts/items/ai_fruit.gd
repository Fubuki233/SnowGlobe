extends AIConsumable
class_name AIFruit

"""
AI 生成的果实类
继承自 AIConsumable，支持食用和种植功能
"""

# ==================== 种植相关属性 ====================
@export_group("种植属性")
@export var is_plantable: bool = true # 是否可种植
@export var plant_scene_path: String = "" # 对应植物的场景路径
@export var growth_time: float = 60.0 # 生长时间（秒）
@export var required_farming_skill: int = 0 # 需要的农业技能等级

# 种植环境需求
@export var required_soil_type: String = "壤土" # 需要的土壤类型
@export var min_temperature: float = 10.0 # 最低温度
@export var max_temperature: float = 30.0 # 最高温度

# 关联的植物实例（动态加载）
var linked_plant_template: PackedScene = null

func _ready() -> void:
	super._ready()
	print("果实已创建: %s (可种植: %s)" % [display_name, is_plantable])
	
	# 预加载植物场景
	if is_plantable and plant_scene_path != "":
		_load_plant_template()

func _load_plant_template():
	"""加载关联的植物场景模板"""
	if ResourceLoader.exists(plant_scene_path):
		linked_plant_template = load(plant_scene_path)
		if linked_plant_template:
			print("   已加载植物模板: %s" % plant_scene_path)
		else:
			push_warning("   无法加载植物场景: %s" % plant_scene_path)
	else:
		push_warning("   植物场景不存在: %s" % plant_scene_path)

# ==================== 种植功能 ====================

func can_plant(character: Node) -> bool:
	"""检查角色是否能种植此果实"""
	if not is_plantable:
		return false
	
	# 检查是否在背包中
	if not is_in_inventory(character):
		print("[种植]  果实不在背包中")
		return false
	
	# 检查是否有植物模板
	if not linked_plant_template and plant_scene_path != "":
		_load_plant_template()
	
	if not linked_plant_template:
		print("[种植]  未配置植物场景")
		return false
	
	# 检查农业技能
	if "survival_skills" in character:
		if character.survival_skills < required_farming_skill:
			print("[种植]  农业技能不足 (需要: %d, 当前: %d)" %
				[required_farming_skill, character.survival_skills])
			return false
	
	return true

func plant(character: Node, position: Vector2 = Vector2.ZERO) -> Node:
	"""
	种植果实
	character: 种植的角色
	position: 种植位置（世界坐标，默认为角色位置）
	返回: 生成的植物节点，失败返回 null
	"""
	if not can_plant(character):
		return null
	
	# 确定种植位置
	var plant_position = position
	if plant_position == Vector2.ZERO:
		plant_position = character.global_position
	
	# 从背包移除果实
	if "inventory" in character and character.inventory:
		if not character.inventory.remove_item(display_name, 1):
			print("[种植]  从背包移除果实失败")
			return null
	
	# 实例化植物
	var plant_instance = linked_plant_template.instantiate()
	if not plant_instance:
		print("[种植]  实例化植物失败")
		# 失败时退还果实
		if "inventory" in character and character.inventory:
			character.inventory.add_item(self, 1)
		return null
	
	# 设置植物位置
	plant_instance.global_position = plant_position
	
	# 设置植物初始状态
	if plant_instance is AIPlant:
		plant_instance.current_stage = 0
		# 可以从果实继承一些属性
		if "rarity" in plant_instance:
			plant_instance.rarity = rarity
	
	# 添加到场景树
	var game_world = _find_game_world()
	if game_world:
		game_world.add_child(plant_instance)
	else:
		# 如果找不到游戏世界节点，添加到根节点
		character.get_tree().root.add_child(plant_instance)
	
	var character_name = character.npc_name if "npc_name" in character else character.name
	print("[种植]  %s 在 (%.0f, %.0f) 种植了 %s" %
		[character_name, plant_position.x, plant_position.y, display_name])
	
	# 触发种植技能提升
	if "survival_skills" in character:
		character.survival_skills += 1
		print("   农业技能提升: %d" % character.survival_skills)
	
	return plant_instance

func _find_game_world() -> Node:
	"""查找游戏世界节点（通常是 Node2D 或类似节点）"""
	var root = get_tree().root if get_tree() else null
	if not root:
		return null
	
	# 尝试查找名为 "Node2D" 或 "GameWorld" 的节点
	for child in root.get_children():
		var node2d = child.get_node_or_null("Node2D")
		if node2d:
			return node2d
		
		# 直接返回第一个 Node2D 类型的子节点
		if child is Node2D and child.name != "CanvasLayer":
			return child
	
	return null

# ==================== 重写使用方法 ====================

func use(user: Node = null) -> void:
	"""使用果实（食用或种植）"""
	if not user:
		super.use(user)
		return
	
	var user_name = user.npc_name if "npc_name" in user else "未知"
	
	# 检查是否可以种植
	if is_plantable and can_plant(user):
		print("\n[提示] %s 可以食用或种植 %s" % [user_name, display_name])
		print("  - 使用 eat() 方法食用")
		print("  - 使用 plant() 方法种植")
	else:
		# 不可种植，直接食用
		eat(user)

func eat(user: Node) -> void:
	"""食用果实（调用父类的使用方法）"""
	super.use(user)

# ==================== 便捷方法 ====================

func get_plant_info() -> Dictionary:
	"""获取关联植物的信息"""
	return {
		"is_plantable": is_plantable,
		"plant_scene_path": plant_scene_path,
		"has_template": linked_plant_template != null,
		"growth_time": growth_time,
		"required_skill": required_farming_skill,
		"soil_type": required_soil_type
	}
