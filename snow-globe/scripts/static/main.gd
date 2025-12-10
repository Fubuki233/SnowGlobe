extends Node

var python_server_pid: int = 0
var TileManager = preload("res://scripts/static/tile_manager.gd")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_python_server()
	
	# 测试 AI 物品加载系统
	test_ai_item_system()
	
	# 延迟测试物品使用（等待场景加载完成）
	await get_tree().create_timer(1.0).timeout
	test_item_usage()
	backpack_system_test()
	#if not Iitem.load_and_spawn_items():
		#sssssssscreate_example_items()
func backpack_system_test() -> void:
	"""测试背包系统"""
	print("\n========== 测试背包系统 ==========\n")
	
	# 获取玩家实例 - 使用健壮的查找方式
	var player = null
	
	# 尝试路径 1: Node2D/player/Player
	var node2d = get_node_or_null("Node2D")
	if node2d:
		var player_container = node2d.get_node_or_null("player")
		if player_container:
			player = player_container.get_node_or_null("Player")
	
	# 尝试路径 2: player/Player
	if not player:
		var player_container = get_node_or_null("player")
		if player_container:
			player = player_container.get_node_or_null("Player")
	
	# 尝试路径 3: 直接查找 CharacterBody2D
	if not player:
		player = get_node_or_null("CharacterBody2D")
	
	if not player:
		print("未找到玩家节点，跳过背包系统测试")
		return
	
	print("找到玩家节点: ", player.name)
	print("当前力量值: ", player.strength)

	# 添加物品到背包
	var sword = AIWeapon.new()
	sword.display_name = "铁剑"
	sword.weight = 2.5
	player.add_to_inventory(sword, 1) # 添加 1 把铁剑

	# 检查物品
	if player.has_item_in_inventory("铁剑", 1):
		print(" 拥有铁剑!")

	# 移除物品
	player.remove_from_inventory("铁剑", 1)

	# 查看背包信息
	var info = player.get_inventory_info()
	print("当前重量: ", info.current_weight, " / ", info.max_weight)

	# 打印完整背包内容
	player.print_inventory()

	# 提升力量值后更新承重
	player.strength = 5
	player.update_inventory_capacity() # 承重上限变为 50 kg
	
	print("\n========== 背包系统测试完成 ==========\n")
func test_ai_item_system() -> void:
	"""测试 AI 物品加载系统"""
	print("\n========== 测试 AI 物品系统 ==========\n")
	
	# 1. 创建测试目录
	var ai_items_dir = "user://ai_items/"
	if not DirAccess.dir_exists_absolute(ai_items_dir):
		DirAccess.make_dir_recursive_absolute(ai_items_dir)
	
	# 2. 创建测试 JSON 配置
	create_test_ai_items()
	
	# 3. 加载 AI 生成的武器
	var weapon = AIItemLoader.load_ai_item("user://ai_items/flame_sword.json")
	if weapon:
		weapon.position = Vector2(400, 200)
		add_child(weapon)
		print(" 已加载 AI 武器到场景")
	
	# 4. 加载 AI 生成的药水
	var potion = AIItemLoader.load_ai_item("user://ai_items/health_potion.json")
	if potion:
		potion.position = Vector2(550, 200)
		add_child(potion)
		print(" 已加载 AI 药水到场景")
	
	# 5. 批量加载所有 AI 物品
	var all_items = AIItemLoader.load_all_from_directory(ai_items_dir)
	print(" 从目录加载了 %d 个 AI 物品" % all_items.size())
	
	# 排列显示（除了前面已加载的）
	for i in range(2, all_items.size()):
		all_items[i].position = Vector2(300 + i * 100, 350)
		add_child(all_items[i])
	
	# 6. 加载 AI 生成的植物（多生长阶段动画）
	test_ai_plant()
	
	print("\n========================================\n")

func create_test_ai_items() -> void:
	"""创建测试用的 AI 物品 JSON 配置"""
	
	# AI 生成的火焰之剑
	var flame_sword = {
		"item_id": "flame_sword_001",
		"display_name": "烈焰之剑",
		"description": "被火焰之力加持的魔法剑",
		"texture_path": "res://icon.svg",
		"preset_type": "weapon",
		"parameters": {
			"damage": 120,
			"fire_damage": 60,
			"durability": 300,
			"rarity": "epic",
			"price": 3500,
			"weight": 4.2,
			"critical_chance": 0.15,
			# 装备属性加成
			"strength_bonus": 10,
			"agility_bonus": 5,
			"combat_skills_bonus": 8
		},
		"collision": {
			"enabled": true,
			"type": "circle",
			"radius": 40.0,
			"layer": 8,
			"mask": 1
		},
		"components": {
			"ParticleEffect": true
		}
	}
	
	# AI 生成的生命药水
	var health_potion = {
		"item_id": "health_potion_001",
		"display_name": "高级生命药水",
		"description": "恢复大量生命值的珍贵药水",
		"texture_path": "res://icon.svg",
		"preset_type": "consumable",
		"parameters": {
			"healing_amount": 200,
			"energy_amount": 50,
			"hunger_restore": 30,
			"thirst_restore": 40,
			"buff_duration": 10.0,
			"buff_type": "力量提升",
			"strength_buff": 5,
			"agility_buff": 3,
			"is_permanent_buff": false,
			"remove_stress": true,
			"rarity": "rare",
			"price": 150,
			"stack_size": 50
		},
		"collision": {
			"enabled": true,
			"type": "circle",
			"radius": 25.0,
			"layer": 8,
			"mask": 1
		},
		"components": {
			"ParticleEffect": true
		}
	}
	
	# AI 生成的冰霜法杖
	var ice_staff = {
		"item_id": "ice_staff_001",
		"display_name": "寒冰法杖",
		"description": "释放冰霜魔法的强大法杖",
		"texture_path": "res://icon.svg",
		"preset_type": "weapon",
		"parameters": {
			"damage": 80,
			"ice_damage": 100,
			"durability": 250,
			"rarity": "legendary",
			"price": 5000,
			"weight": 2.5
		},
		"collision": {
			"enabled": true,
			"type": "auto",
			"layer": 8,
			"mask": 1
		},
		"components": {
			"ParticleEffect": true
		}
	}
	
	# 保存 JSON 文件
	_save_item_json("user://ai_items/flame_sword.json", flame_sword)
	_save_item_json("user://ai_items/health_potion.json", health_potion)
	_save_item_json("user://ai_items/ice_staff.json", ice_staff)
	
	# 添加一个使用网络图片的物品示例
	var network_item = {
		"item_id": "network_gem_001",
		"display_name": "网络宝石",
		"description": "从网络加载的神秘宝石",
		"texture_path": "https://picsum.photos/128/128", # 示例：随机图片 API (JPEG 格式)
		"preset_type": "consumable",
		"parameters": {
			"healing_amount": 0,
			"energy_amount": 100,
			"rarity": "epic",
			"price": 999
		},
		"collision": {
			"enabled": true,
			"type": "circle",
			"radius": 30.0,
			"layer": 8,
			"mask": 1
		},
		"components": {
			"ParticleEffect": true
		}
	}
	_save_item_json("user://ai_items/network_gem.json", network_item)
	
	print("已创建 4 个测试 AI 物品配置（包含 1 个网络图片示例）")

func _save_item_json(path: String, data: Dictionary) -> void:
	"""保存物品配置为 JSON 文件"""
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("已保存 JSON 文件: %s" % path)
	else:
		push_error("无法保存 JSON: %s" % path)

func test_ai_plant() -> void:
	"""测试 AI 生成的植物加载（多生长阶段动画）"""
	print("\n--- 测试 AI 植物系统 ---")
	
	# 扫描 res://Assets/Items/plants/ 目录下的所有植物
	var plants_dir = "res://Assets/Items/plants/"
	var dir = DirAccess.open(plants_dir)
	
	if not dir:
		print(" 植物目录不存在: %s" % plants_dir)
		return
	
	# 获取所有子目录（每个子目录代表一个植物）
	var plant_folders = []
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			plant_folders.append(folder_name)
		folder_name = dir.get_next()
	dir.list_dir_end()
	
	if plant_folders.is_empty():
		print(" 未找到任何植物配置")
		print("  请先使用 SnowWeave 的植物生成功能生成植物动画")
		return
	
	print(" 找到 %d 个植物: %s" % [plant_folders.size(), plant_folders])
	
	# 获取玩家位置
	var player_node = get_node_or_null("Node2D/player/Player")
	var player_pos = Vector2(47, 358) # 默认玩家位置
	if player_node:
		player_pos = player_node.global_position
	
	# 获取 Node2D 用于添加植物
	var game_world = get_node_or_null("Node2D")
	if not game_world:
		print(" Node2D 未找到，将添加到 main")
		game_world = self
	
	# 加载每个植物
	var spacing = 120 # 植物之间的间距
	for i in range(plant_folders.size()):
		var plant_name = plant_folders[i]
		# 查找配置文件：优先 {plant_name}_config.json，否则 {plant_name}.json
		var config_path = plants_dir + plant_name + "/" + plant_name + "_config.json"
		if not FileAccess.file_exists(config_path):
			config_path = plants_dir + plant_name + "/" + plant_name + ".json"
		
		if not FileAccess.file_exists(config_path):
			print(" 植物配置文件不存在: %s" % plant_name)
			continue
		
		# 加载 AI 植物
		var plant = AIItemLoader.load_ai_item(config_path)
		if plant:
			# 将植物排列在玩家右边
			plant.position = player_pos + Vector2(100 + i * spacing, 0)
			game_world.add_child(plant)
			print(" 已加载 AI 植物: %s, 位置: %s" % [plant_name, plant.position])
			
			# 如果植物支持生长，设置自动生长测试
			if plant.has_method("grow"):
				var delay = 2.0 + i * 1.0 # 每个植物间隔1秒开始生长
				_setup_auto_grow(plant, plant_name, delay)
		else:
			print(" 加载植物失败: %s" % plant_name)

func _setup_auto_grow(plant: Node, plant_name: String, initial_delay: float) -> void:
	"""设置植物自动生长"""
	# 延迟开始生长
	var timer = get_tree().create_timer(initial_delay)
	timer.timeout.connect(func():
		print("  >> [%s] 触发生长..." % plant_name)
		plant.grow()
		
		# 继续生长（每2秒一次）
		_continue_growing(plant, plant_name, 1)
	)

func _continue_growing(plant: Node, plant_name: String, stage: int) -> void:
	"""持续生长到最大阶段"""
	if not is_instance_valid(plant):
		return
	
	# 检查是否还能生长
	var max_stage = plant.get("growth_stages")
	if max_stage and stage < max_stage:
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(plant):
				print("  >> [%s] 生长到阶段 %d" % [plant_name, stage + 1])
				plant.grow()
				_continue_growing(plant, plant_name, stage + 1)
		)

func test_item_usage() -> void:
	"""测试物品使用和属性修改"""
	print("\n========== 测试物品使用系统 ==========\n")
	
	# 获取玩家 - 按场景树结构查找
	var player = null
	
	# 尝试路径 1: Node2D/player/Player
	var node2d = get_node_or_null("Node2D")
	if node2d:
		var player_container = node2d.get_node_or_null("player")
		if player_container:
			player = player_container.get_node_or_null("Player")
	
	# 尝试路径 2: player/Player
	if not player:
		var player_container = get_node_or_null("player")
		if player_container:
			player = player_container.get_node_or_null("Player")
	
	# 尝试路径 3: 直接查找 CharacterBody2D
	if not player:
		player = get_node_or_null("CharacterBody2D")
	
	if not player:
		print("未找到玩家节点，跳过测试")
		return
	
	print("玩家初始属性:")
	print("  生命值: %d/%d" % [player.current_health, player.max_health])
	print("  能量: %d/%d" % [player.energy, player.max_energy])
	print("  力量: %d" % player.strength)
	print("  敏捷: %d" % player.agility)
	print("  战斗技能: %d" % player.combat_skills)
	
	# 1. 测试消耗品
	print("\n--- 测试使用药水 ---")
	var potion = get_node_or_null("health_potion_001")
	if potion and potion.has_method("use"):
		# 先降低生命值来测试
		player.current_health = 50
		print("降低生命值到: %d" % player.current_health)
		
		# 使用药水
		potion.use(player)
		print("使用后生命值: %d/%d" % [player.current_health, player.max_health])
	
	# 2. 测试武器装备
	print("\n--- 测试装备武器 ---")
	var weapon = get_node_or_null("flame_sword_001")
	if weapon and weapon.has_method("equip"):
		weapon.equip(player)
		print("装备后属性:")
		print("  力量: %d" % player.strength)
		print("  敏捷: %d" % player.agility)
		print("  战斗技能: %d" % player.combat_skills)
		
		# 测试攻击
		print("\n--- 测试武器攻击 ---")
		weapon.use()
		weapon.use()
		weapon.use()
		
		# 卸下武器
		print("\n--- 卸下武器 ---")
		weapon.unequip()
		print("卸下后属性:")
		print("  力量: %d" % player.strength)
		print("  敏捷: %d" % player.agility)
		print("  战斗技能: %d" % player.combat_skills)
	
	print("\n========================================\n")
	

func start_python_server() -> void:
	var script_path = "scripts/static/godot_rpc_server.py"
	var full_path = ProjectSettings.globalize_path("res://" + script_path)
	
	print("启动 Python RPC 服务器...")
	var args = [full_path]
	python_server_pid = OS.create_process("python", args)
	
	if python_server_pid > 0:
		print("Python 服务器已启动 (PID: ", python_server_pid, ")")
	else:
		push_error("Python 服务器启动失败")

func stop_python_server() -> void:
	if python_server_pid > 0:
		OS.kill(python_server_pid)
		print("Python 服务器已停止")
		python_server_pid = 0

func _exit_tree() -> void:
	stop_python_server()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
