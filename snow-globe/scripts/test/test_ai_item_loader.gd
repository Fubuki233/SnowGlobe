extends Node2D

"""
AI 物品加载器测试脚本
演示如何使用 AIItemLoader 加载 AI 生成的物品
"""

func _ready() -> void:
	# 等待一帧确保场景树完全初始化
	await get_tree().process_frame
	
	print("\n========== AI 物品加载器测试 ==========\n")
	
	# 测试 1: 生成示例 JSON
	test_generate_example_json()
	
	# 测试 2: 加载单个 AI 物品
	test_load_single_item()
	
	# 测试 3: 批量加载
	test_batch_load()
	
	# 测试 4: 从目录加载所有物品
	# test_load_from_directory()

func test_generate_example_json() -> void:
	print("=== 测试 1: 生成示例 JSON ===")
	
	# 确保目录存在
	var dir_path = "user://ai_items/"
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	
	# 生成示例 JSON
	var json_path = dir_path + "example_weapon.json"
	AIItemLoader.generate_example_json(json_path)
	
	print("")

func test_load_single_item() -> void:
	print("=== 测试 2: 加载单个 AI 物品 ===")
	
	# 加载示例物品
	var item = AIItemLoader.load_ai_item("user://ai_items/example_weapon.json")
	
	if item:
		# 设置位置并添加到场景
		item.position = Vector2(300, 200)
		add_child(item)
		
		# 如果是武器，调用其方法
		if item is AIWeapon:
			var weapon = item as AIWeapon
			print("\n物品属性:")
			print("  伤害: %d" % weapon.damage)
			print("  火焰伤害: %d" % weapon.fire_damage)
			print("  稀有度: %s" % weapon.rarity)
			print("  价格: %d" % weapon.price)
			
			weapon.use()
	else:
		print("加载失败")
	
	print("")

func test_batch_load() -> void:
	print("=== 测试 3: 批量加载（需要先创建多个 JSON）===")
	
	# 创建多个测试 JSON
	create_test_items()
	
	# 批量加载
	var json_paths = [
		"user://ai_items/test_sword.json",
		"user://ai_items/test_potion.json"
	]
	
	var items = AIItemLoader.load_ai_items_batch(json_paths)
	
	print("成功加载 %d 个物品" % items.size())
	
	# 排列显示
	for i in range(items.size()):
		items[i].position = Vector2(200 + i * 150, 400)
		add_child(items[i])
	
	print("")

func create_test_items() -> void:
	"""创建测试用的 JSON 文件"""
	
	# 测试剑
	var sword_config = {
		"item_id": "test_sword",
		"display_name": "测试之剑",
		"texture_path": "res://icon.svg",
		"preset_type": "weapon",
		"parameters": {
			"damage": 100,
			"fire_damage": 25,
			"rarity": "rare",
			"price": 2000
		},
		"components": {
			"ParticleEffect": true,
			"GlowEffect": true
		}
	}
	
	# 测试药水
	var potion_config = {
		"item_id": "test_potion",
		"display_name": "测试药水",
		"texture_path": "res://icon.svg",
		"preset_type": "consumable",
		"parameters": {
			"healing_amount": 100,
			"energy_amount": 50,
			"rarity": "common",
			"price": 50
		},
		"components": {
			"ParticleEffect": false
		}
	}
	
	# 保存 JSON
	_save_json("user://ai_items/test_sword.json", sword_config)
	_save_json("user://ai_items/test_potion.json", potion_config)

func _save_json(path: String, data: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
