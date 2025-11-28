extends Node

"""
物品系统测试场景
在主场景中生成一些测试物品
"""

func _ready():
	# 等待场景完全加载
	await get_tree().process_frame
	
	# 获取物品容器
	var items_container = get_node_or_null("/root/main/ItemsContainer")
	if not items_container:
		print("警告: 找不到 ItemsContainer 节点")
		return
	
	print("\n=== 开始生成测试物品 ===")
	spawn_test_items(items_container)

func spawn_test_items(container: Node2D):
	"""生成一些测试物品"""
	
	# 创建测试物品1: 生命药水
	var potion = ConsumableItem.new()
	potion.item_id = "potion_health_001"
	potion.item_name = "生命药水"
	potion.description = "恢复50点生命值"
	potion.value = 25
	potion.weight = 0.2
	potion.rarity = ItemBase.Rarity.COMMON
	potion.restore_health = 50
	potion.is_stackable = true
	potion.max_stack = 99
	# 使用程序生成的图标(红色圆形)
	potion.icon = ItemIconManager.load_icon_by_id(potion.item_id)
	
	# 在位置 (200, 100) 生成
	ItemSpawner.spawn_item(potion, Vector2(200, 100), container)
	print("✓ 生成了: 生命药水 at (200, 100)")
	
	# 创建测试物品2: 金币
	var gold = ItemBase.new()
	gold.item_id = "gold_coin"
	gold.item_name = "金币"
	gold.description = "闪闪发光的金币"
	gold.value = 1
	gold.weight = 0.01
	gold.is_stackable = true
	gold.max_stack = 999
	gold.icon = ItemIconManager.load_icon_by_id(gold.item_id)
	
	ItemSpawner.spawn_item(gold, Vector2(300, 150), container, 50)
	print("✓ 生成了: 金币 x50 at (300, 150)")
	
	# 创建测试物品3: 铁剑
	var sword = EquipmentItem.new()
	sword.item_id = "sword_iron_001"
	sword.item_name = "铁剑"
	sword.description = "一把普通的铁剑"
	sword.value = 100
	sword.weight = 2.5
	sword.rarity = ItemBase.Rarity.UNCOMMON
	sword.equip_slot = EquipmentItem.EquipSlot.MAIN_HAND
	sword.damage = 15
	sword.strength_bonus = 2
	sword.icon = ItemIconManager.load_icon_by_id(sword.item_id)
	
	ItemSpawner.spawn_item(sword, Vector2(400, 100), container)
	print("✓ 生成了: 铁剑 at (400, 100)")
	
	# 创建测试物品4: 传说宝石
	var gem = ItemBase.new()
	gem.item_id = "gem_legendary"
	gem.item_name = "传说宝石"
	gem.description = "散发着神秘光芒"
	gem.value = 1000
	gem.weight = 0.1
	gem.rarity = ItemBase.Rarity.LEGENDARY
	gem.icon = ItemIconManager.load_icon_by_id(gem.item_id)
	
	ItemSpawner.spawn_item(gem, Vector2(250, 200), container)
	print("✓ 生成了: 传说宝石 at (250, 200)")
	
	print("=== 物品生成完成 ===\n")
	print("提示: 靠近物品自动拾取,或按 E 键拾取")
	print("提示: 物品会显示在地图上,带有浮动效果")
