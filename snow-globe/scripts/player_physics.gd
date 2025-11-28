extends CharacterBody2D
signal hit
signal player_moved(new_position: Vector2)
@export var id = "player_1"

#=========================== 枚举定义 ===========================
enum AgeGroup {CHILD, TEEN, ADULT, ELDER}
enum Gender {MALE, FEMALE}

#=========================== 基础信息 ===========================
@export var npc_name = "DefaultNPC"
@export var age: AgeGroup = AgeGroup.CHILD
@export var gender: Gender = Gender.MALE

#=========================== 移动属性 ===========================
@export var speed = 256.0
@export var path_speed = 256.0
@export var running_speed = 400.0

#=========================== 生命属性 ===========================
@export var current_health = 100
@export var max_health = 100
@export var hunger = 10
@export var max_hunger = 10
@export var energy = 10
@export var max_energy = 10
@export var thirst = 10
@export var max_thirst = 10

#=========================== 基础能力值 ===========================
@export var intelligence = 1
@export var strength = 1
@export var agility = 1
@export var charisma = 1
@export var endurance = 1
@export var luck = 1
@export var perception = 1
@export var wisdom = 1

#=========================== 技能属性 ===========================
@export var mental_strength = 1
@export var social_skills = 1
@export var combat_skills = 1
@export var crafting_skills = 1
@export var survival_skills = 1
@export var stealth_skills = 1
@export var cooking = 1

#=========================== 生存状态 ===========================
@export var is_alive = true
@export var is_hungry = false
@export var is_thirsty = false
@export var is_injured = false
@export var is_tired = false
@export var is_sick = false

#=========================== 情绪状态 ===========================
@export var is_stressed = false

#=========================== 移动状态 ===========================
@export var is_moving = false
@export var is_wandering = false

#=========================== 战斗状态 ===========================
@export var is_attacking = false
@export var is_stealthing = false

#=========================== 社交状态 ===========================
@export var is_talking = false
@export var is_trading = false

#=========================== 工作状态 ===========================
@export var is_working = false
@export var is_crafting = false
@export var is_building = false
@export var is_cooking = false
@export var is_researching = false

#=========================== 资源采集状态 ===========================
@export var is_gathering = false
@export var is_fishing = false
@export var is_hunting = false
@export var is_mining = false
@export var is_woodcutting = false
@export var is_farming = false

#=========================== 探索状态 ===========================
@export var is_exploring = false

#=========================== 休息状态 ===========================
@export var is_resting = false
@export var is_sleeping = false

#=========================== 娱乐状态 ===========================
@export var is_playing = false

#=========================== 综合状态 ===========================
@export var is_busy = false
#===================================================================

var is_moving_to_target = false
var target_path: PackedVector2Array = []
var current_path_index = 0

# 背包系统
var inventory = null

func _ready() -> void:
	GodotRPC.register_instance(id, self)
	# 连接 Python 触发的信号
	player_moved.connect(_on_player_moved)
	z_index = 10
	
	# 初始化背包
	inventory = Inventory.new()
	inventory.max_slots = 20
	inventory.max_weight = 100.0
	inventory.item_added.connect(_on_item_added)
	inventory.item_removed.connect(_on_item_removed)
	inventory.inventory_full.connect(_on_inventory_full)
	add_child(inventory)
	
func get_status():
	"""返回玩家状态"""
	return {
		"id": id,
		"position": {"x": position.x, "y": position.y},
		"velocity": {"x": velocity.x, "y": velocity.y}
	}

# =========================== 数据获取方法 ===========================

func get_basic_info() -> Dictionary:
	"""获取基础信息"""
	return {
		"id": id,
		"npc_name": npc_name,
		"age": AgeGroup.keys()[age],
		"gender": Gender.keys()[gender]
	}

func get_movement_attributes() -> Dictionary:
	"""获取移动属性"""
	return {
		"speed": speed,
		"path_speed": path_speed,
		"running_speed": running_speed
	}

func get_vital_attributes() -> Dictionary:
	"""获取生命属性"""
	return {
		"current_health": current_health,
		"max_health": max_health,
		"hunger": hunger,
		"max_hunger": max_hunger,
		"energy": energy,
		"max_energy": max_energy,
		"thirst": thirst,
		"max_thirst": max_thirst
	}

func get_base_stats() -> Dictionary:
	"""获取基础能力值"""
	return {
		"intelligence": intelligence,
		"strength": strength,
		"agility": agility,
		"charisma": charisma,
		"endurance": endurance,
		"luck": luck,
		"perception": perception,
		"wisdom": wisdom
	}

func get_skill_attributes() -> Dictionary:
	"""获取技能属性"""
	return {
		"mental_strength": mental_strength,
		"social_skills": social_skills,
		"combat_skills": combat_skills,
		"crafting_skills": crafting_skills,
		"survival_skills": survival_skills,
		"stealth_skills": stealth_skills,
		"cooking": cooking
	}

func get_survival_status() -> Dictionary:
	"""获取生存状态"""
	return {
		"is_alive": is_alive,
		"is_hungry": is_hungry,
		"is_thirsty": is_thirsty,
		"is_injured": is_injured,
		"is_tired": is_tired,
		"is_sick": is_sick
	}

func get_emotional_status() -> Dictionary:
	"""获取情绪状态"""
	return {
		"is_stressed": is_stressed
	}

func get_movement_status() -> Dictionary:
	"""获取移动状态"""
	return {
		"is_moving": is_moving,
		"is_wandering": is_wandering
	}

func get_combat_status() -> Dictionary:
	"""获取战斗状态"""
	return {
		"is_attacking": is_attacking,
		"is_stealthing": is_stealthing
	}

func get_social_status() -> Dictionary:
	"""获取社交状态"""
	return {
		"is_talking": is_talking,
		"is_trading": is_trading
	}

func get_work_status() -> Dictionary:
	"""获取工作状态"""
	return {
		"is_working": is_working,
		"is_crafting": is_crafting,
		"is_building": is_building,
		"is_cooking": is_cooking,
		"is_researching": is_researching
	}

func get_gathering_status() -> Dictionary:
	"""获取资源采集状态"""
	return {
		"is_gathering": is_gathering,
		"is_fishing": is_fishing,
		"is_hunting": is_hunting,
		"is_mining": is_mining,
		"is_woodcutting": is_woodcutting,
		"is_farming": is_farming
	}

func get_exploration_status() -> Dictionary:
	"""获取探索状态"""
	return {
		"is_exploring": is_exploring
	}

func get_rest_status() -> Dictionary:
	"""获取休息状态"""
	return {
		"is_resting": is_resting,
		"is_sleeping": is_sleeping
	}

func get_entertainment_status() -> Dictionary:
	"""获取娱乐状态"""
	return {
		"is_playing": is_playing
	}

func get_general_status() -> Dictionary:
	"""获取综合状态"""
	return {
		"is_busy": is_busy
	}

func get_all_attributes() -> Dictionary:
	"""获取所有属性"""
	return {
		"basic_info": get_basic_info(),
		"movement_attributes": get_movement_attributes(),
		"vital_attributes": get_vital_attributes(),
		"base_stats": get_base_stats(),
		"skill_attributes": get_skill_attributes()
	}

func get_all_status() -> Dictionary:
	"""获取所有状态"""
	return {
		"survival_status": get_survival_status(),
		"emotional_status": get_emotional_status(),
		"movement_status": get_movement_status(),
		"combat_status": get_combat_status(),
		"social_status": get_social_status(),
		"work_status": get_work_status(),
		"gathering_status": get_gathering_status(),
		"exploration_status": get_exploration_status(),
		"rest_status": get_rest_status(),
		"entertainment_status": get_entertainment_status(),
		"general_status": get_general_status()
	}

func get_complete_data() -> Dictionary:
	"""获取完整的NPC数据(包括所有属性和状态)"""
	return {
		"attributes": get_all_attributes(),
		"status": get_all_status(),
		"position": {"x": position.x, "y": position.y},
		"velocity": {"x": velocity.x, "y": velocity.y}
	}


func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false

func reset():
	"""重置所有属性和状态到默认值"""
	# 重置基础信息
	npc_name = "DefaultNPC"
	age = AgeGroup.CHILD
	gender = Gender.MALE
	
	# 重置移动属性
	speed = 256.0
	path_speed = 256.0
	running_speed = 400.0
	
	# 重置生命属性
	current_health = max_health
	hunger = max_hunger
	energy = max_energy
	thirst = max_thirst
	
	# 重置基础能力值
	intelligence = 1
	strength = 1
	agility = 1
	charisma = 1
	endurance = 1
	luck = 1
	perception = 1
	wisdom = 1
	
	# 重置技能属性
	mental_strength = 1
	social_skills = 1
	combat_skills = 1
	crafting_skills = 1
	survival_skills = 1
	stealth_skills = 1
	cooking = 1
	
	# 重置生存状态
	is_alive = true
	is_hungry = false
	is_thirsty = false
	is_injured = false
	is_tired = false
	is_sick = false
	
	# 重置情绪状态
	is_stressed = false
	
	# 重置移动状态
	is_moving = false
	is_wandering = false
	
	# 重置战斗状态
	is_attacking = false
	is_stealthing = false
	
	# 重置社交状态
	is_talking = false
	is_trading = false
	
	# 重置工作状态
	is_working = false
	is_crafting = false
	is_building = false
	is_cooking = false
	is_researching = false
	
	# 重置资源采集状态
	is_gathering = false
	is_fishing = false
	is_hunting = false
	is_mining = false
	is_woodcutting = false
	is_farming = false
	
	# 重置探索状态
	is_exploring = false
	
	# 重置休息状态
	is_resting = false
	is_sleeping = false
	
	# 重置娱乐状态
	is_playing = false
	
	# 重置综合状态
	is_busy = false
	
	# 重置移动相关变量
	target_path = PackedVector2Array()
	current_path_index = 0
	velocity = Vector2.ZERO


func move_to_random_position():
	"""移动到地图上的随机位置"""
	var tilemap = get_node("/root/main/TileMapLayer")
	if not tilemap:
		print("找不到 TileMapLayer")
		return
	
	var target_grid = tilemap.get_random_walkable_position()
	var current_grid = tilemap.local_to_map(global_position)

	target_path = tilemap.get_astar_path(current_grid, target_grid)
	
	if target_path.size() > 0:
		is_moving = true
		current_path_index = 0
		is_wandering = true
		print("开始移动到网格: ", target_grid, " 路径长度: ", target_path.size())
	else:
		print("无法找到路径")

func move_to_position(pos: Array):
	"""移动到指定网格位置"""
	var x = pos[0]
	var y = pos[1]

	var tilemap = get_node("/root/main/TileMapLayer")
	if not tilemap:
		print("找不到 TileMapLayer")
		return
		
	var target_grid = Vector2i(x, y)
	var current_grid = tilemap.local_to_map(global_position)
	target_path = tilemap.get_astar_path(current_grid, target_grid)
	
	if target_path.size() > 0:
		is_moving = true
		current_path_index = 0
		print("开始移动到网格: ", target_grid, " 路径长度: ", target_path.size())
	else:
		print("无法找到路径")

func _physics_process(_delta: float) -> void:
	if is_moving:
		# 自动移动模式
		move_along_path()
	else:
		# 手动控制模式
		manual_control()

func move_along_path():
	"""沿着路径移动"""
	if current_path_index >= target_path.size():
		is_moving = false
		velocity = Vector2.ZERO
		$AnimatedSprite2D.stop()
		print("到达目标!")
		is_wandering = false
		is_moving = false
		return
	
	var target = target_path[current_path_index]
	var direction = (target - global_position).normalized()
	var distance = global_position.distance_to(target)
		
	if distance < 2:
		current_path_index += 1
		emit_signal("player_moved", global_position)
	else:
		velocity = direction * path_speed
		$AnimatedSprite2D.play()
		emit_signal("player_moved", global_position)
	move_and_slide()

func manual_control():
	"""手动控制移动"""
	# 获取输入方向
	var input_direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_down"):
		input_direction.y += 1
	if Input.is_action_pressed("move_up"):
		input_direction.y -= 1

	# 设置速度
	if input_direction.length() > 0:
		velocity = input_direction.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.stop()

	move_and_slide()

func _on_body_entered(_body):
	hide()
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true)

func _on_player_moved(new_position: Vector2):
	print("Player moved to: ", new_position)

# ============ 物品系统方法 ============

func add_item_to_inventory(item: ItemBase, count: int = 1) -> bool:
	"""供 ItemWorld 调用的拾取方法"""
	if inventory:
		return inventory.add_item(item, count)
	return false

func pickup_item(item: ItemBase, count: int = 1) -> bool:
	"""拾取物品"""
	return add_item_to_inventory(item, count)

func _on_item_added(item: ItemBase, count: int):
	"""物品添加到背包时的回调"""
	print("[%s] 获得了: %s x%d" % [npc_name, item.item_name, count])

func _on_item_removed(item: ItemBase, count: int):
	"""物品从背包移除时的回调"""
	print("[%s] 失去了: %s x%d" % [npc_name, item.item_name, count])

func _on_inventory_full():
	"""背包满了的回调"""
	print("[%s] 背包已满!" % npc_name)
