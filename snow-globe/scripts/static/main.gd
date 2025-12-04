extends Node

var python_server_pid: int = 0
var TileManager = preload("res://scripts/static/tile_manager.gd")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_python_server()
	TilemapImporter.import_to_existing_tileset(
		"res://Assets/Environments/static_layer.tres",
		"res://Assets/Environments/clay.png",
		true,
		"",
		"",
		{"description": "粘土", "category": "terrain"},
		true
	)
	TilemapImporter.place_tile_by_id(
		get_tree().get_current_scene().get_node("Node2D/UpperLayerObstacle"),
		"clay",
		Vector2i(5, 5)
	)
	var tm = get_tree().get_current_scene().get_node("Node2D/UpperLayerObstacle")
	if tm:
		for tile_pos in tm.get_used_cells():
			var tile_name = tm.get_tile_name(tile_pos)
			print("Tile at ", tile_pos, " has name: ", tile_name)
	if not Iitem.load_and_spawn_items():
		create_example_items()
	

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

func create_example_items() -> void:
	"""创建示例物品数据"""
	print("\n=== 创建示例物品 ===")
	
	# 1. 生命药水 - 在地图不同位置放3瓶
	print("\n--- 创建生命药水模板 ---")
	Iitem.create_consumable_template(
		"生命药水",
		"恢复50点生命值",
		10,
		1.0,
		ItemBase.Rarity.COMMON,
		50,
		true,
		99,
		"potion_health"
	)
	Iitem.spawn_instance("potion_health", Vector2(200, 100), 1)
	Iitem.spawn_instance("potion_health", Vector2(250, 150), 3)
	Iitem.spawn_instance("potion_health", Vector2(300, 200), 5)
	
	# 2. 金币 - 在地图上散落多堆
	print("\n--- 创建金币模板 ---")
	Iitem.create_base_template(
		"金币",
		"闪闪发光的金币",
		1,
		0.01,
		ItemBase.Rarity.COMMON,
		true,
		999,
		"gold_coin"
	)
	Iitem.spawn_instance("gold_coin", Vector2(150, 100), 50)
	Iitem.spawn_instance("gold_coin", Vector2(400, 150), 30)
	Iitem.spawn_instance("gold_coin", Vector2(500, 200), 100)
	Iitem.spawn_instance("gold_coin", Vector2(350, 250), 75)
	
	# 3. 铁剑 - 两把铁剑在不同位置
	print("\n--- 创建铁剑模板 ---")
	Iitem.create_equipment_template(
		"铁剑",
		"一把普通的铁剑,适合初学者使用",
		100,
		2.5,
		EquipmentItem.EquipSlot.MAIN_HAND,
		ItemBase.Rarity.UNCOMMON,
		0,
		15,
		100,
		2,
		0,
		0,
		"sword_iron"
	)
	Iitem.spawn_instance("sword_iron", Vector2(450, 100))
	Iitem.spawn_instance("sword_iron", Vector2(550, 150))
	
	# 4. 皮革护甲
	print("\n--- 创建皮革护甲模板 ---")
	Iitem.create_equipment_template(
		"皮革护甲",
		"轻便的皮革护甲,提供基础防护",
		80,
		3.0,
		EquipmentItem.EquipSlot.CHEST,
		ItemBase.Rarity.COMMON,
		10,
		0,
		100,
		0,
		1,
		0,
		"armor_leather"
	)
	Iitem.spawn_instance("armor_leather", Vector2(300, 300))
	
	# 5. 传说宝石 - 稀有物品
	print("\n--- 创建传说宝石模板 ---")
	Iitem.create_base_template(
		"传说宝石",
		"散发着神秘光芒的珍贵宝石",
		1000,
		0.1,
		ItemBase.Rarity.LEGENDARY,
		false,
		1,
		"gem_legendary"
	)
	Iitem.spawn_instance("gem_legendary", Vector2(600, 300))
	
	# 6. 能量药水
	print("\n--- 创建能量药水模板 ---")
	Iitem.create_consumable_template(
		"能量药水",
		"恢复100点能量值",
		25,
		1.2,
		ItemBase.Rarity.UNCOMMON,
		0,
		true,
		50,
		"potion_energy"
	)
	Iitem.spawn_instance("potion_energy", Vector2(250, 250), 2)
	
	Iitem.save_all_items()
	Iitem.print_all_items()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
