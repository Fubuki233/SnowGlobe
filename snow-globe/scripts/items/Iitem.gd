extends Node

var items_container = null
var registry: ItemRegistry = null

func _ready() -> void:
	items_container = get_node_or_null("/root/main/ItemsContainer")
	
	# 初始化物品注册器
	registry = ItemRegistry.new()
	add_child(registry)
	
	# 尝试加载已保存的物品数据
	if FileAccess.file_exists(ItemRegistry.SAVE_PATH):
		registry.load_from_file()
		print("已加载保存的物品模板和实例")

# ============ 模板创建方法 ============

func create_consumable_template(
	item_name: String,
	description: String,
	value: int,
	weight: float,
	rarity: ItemBase.Rarity,
	restore_health: int,
	is_stackable: bool = true,
	max_stack: int = 99,
	item_id: String = ""
) -> ConsumableItem:
	"""创建消耗品模板"""
	var template = ConsumableItem.new()
	template.item_id = item_id if not item_id.is_empty() else UUIDGenerator.generate_short_id()
	template.item_name = item_name
	template.description = description
	template.value = value
	template.weight = weight
	template.rarity = rarity
	template.restore_health = restore_health
	template.is_stackable = is_stackable
	template.max_stack = max_stack
	template.icon = ItemIconManager.load_icon_by_id(template.item_id)
	
	# 注册模板
	registry.register_template(template)
	print("创建模板: %s [%s]" % [template.item_name, template.item_id])
	
	return template

func create_base_template(
	item_name: String,
	description: String,
	value: int,
	weight: float,
	rarity: ItemBase.Rarity = ItemBase.Rarity.COMMON,
	is_stackable: bool = true,
	max_stack: int = 99,
	item_id: String = ""
) -> ItemBase:
	"""创建基础物品模板(如金币、材料)"""
	var template = ItemBase.new()
	template.item_id = item_id if not item_id.is_empty() else UUIDGenerator.generate_short_id()
	template.item_name = item_name
	template.description = description
	template.value = value
	template.weight = weight
	template.rarity = rarity
	template.is_stackable = is_stackable
	template.max_stack = max_stack
	template.icon = ItemIconManager.load_icon_by_id(template.item_id)
	
	# 注册模板
	registry.register_template(template)
	print("创建模板: %s [%s]" % [template.item_name, template.item_id])
	
	return template

func create_equipment_template(
	item_name: String,
	description: String,
	value: int,
	weight: float,
	equip_slot: EquipmentItem.EquipSlot,
	rarity: ItemBase.Rarity = ItemBase.Rarity.COMMON,
	armor: int = 0,
	damage: int = 0,
	durability: int = 100,
	strength_bonus: int = 0,
	dexterity_bonus: int = 0,
	intelligence_bonus: int = 0,
	item_id: String = ""
) -> EquipmentItem:
	"""创建装备物品模板"""
	var template = EquipmentItem.new()
	template.item_id = item_id if not item_id.is_empty() else UUIDGenerator.generate_short_id()
	template.item_name = item_name
	template.description = description
	template.value = value
	template.weight = weight
	template.rarity = rarity
	template.equip_slot = equip_slot
	template.armor = armor
	template.damage = damage
	template.durability = durability
	template.max_durability = durability
	template.strength_bonus = strength_bonus
	template.intelligence_bonus = intelligence_bonus
	template.icon = ItemIconManager.load_icon_by_id(template.item_id)
	
	# 注册模板
	registry.register_template(template)
	print("创建模板: %s [%s]" % [template.item_name, template.item_id])
	
	return template

# ============ 实例生成方法 ============

func spawn_instance(template_id: String, position: Vector2, count: int = 1) -> ItemInstance:
	"""根据模板ID创建实例并生成到地图"""
	if not items_container:
		push_error("ItemsContainer 未找到,无法生成物品")
		return null
	
	var instance = registry.create_instance(template_id, position, count)
	if not instance or not instance.template:
		push_error("无法创建实例,模板不存在: " + template_id)
		return null
	
	ItemSpawner.spawn_item(instance.template, position, items_container, count)
	print("生成实例: %s x%d at %s" % [instance.get_item_name(), count, position])
	
	return instance

func spawn_instance_to(template_id: String, position: Vector2, container: Node2D, count: int = 1) -> ItemInstance:
	"""根据模板ID创建实例并生成到指定容器"""
	var instance = registry.create_instance(template_id, position, count)
	if not instance or not instance.template:
		push_error("无法创建实例,模板不存在: " + template_id)
		return null
	
	ItemSpawner.spawn_item(instance.template, position, container, count)
	print("生成实例: %s x%d at %s" % [instance.get_item_name(), count, position])
	
	return instance

func remove_instance(instance_id: String):
	"""移除物品实例"""
	registry.remove_instance(instance_id)

# ============ 快捷方法:创建模板并生成实例 ============

func create_and_spawn_consumable(
	item_name: String,
	description: String,
	value: int,
	weight: float,
	rarity: ItemBase.Rarity,
	restore_health: int,
	position: Vector2,
	is_stackable: bool = true,
	max_stack: int = 99,
	count: int = 1,
	template_id: String = ""
) -> ItemInstance:
	"""创建消耗品模板并生成实例到地图"""
	var template = create_consumable_template(item_name, description, value, weight, rarity, restore_health, is_stackable, max_stack, template_id)
	return spawn_instance(template.item_id, position, count)

func create_and_spawn_base_item(
	item_name: String,
	description: String,
	value: int,
	weight: float,
	position: Vector2,
	rarity: ItemBase.Rarity = ItemBase.Rarity.COMMON,
	is_stackable: bool = true,
	max_stack: int = 99,
	count: int = 1,
	template_id: String = ""
) -> ItemInstance:
	"""创建基础物品模板并生成实例到地图"""
	var template = create_base_template(item_name, description, value, weight, rarity, is_stackable, max_stack, template_id)
	return spawn_instance(template.item_id, position, count)

func create_and_spawn_equipment(
	item_name: String,
	description: String,
	value: int,
	weight: float,
	position: Vector2,
	equip_slot: EquipmentItem.EquipSlot,
	rarity: ItemBase.Rarity = ItemBase.Rarity.COMMON,
	armor: int = 0,
	damage: int = 0,
	durability: int = 100,
	strength_bonus: int = 0,
	dexterity_bonus: int = 0,
	intelligence_bonus: int = 0,
	template_id: String = ""
) -> ItemInstance:
	"""创建装备模板并生成实例到地图"""
	var template = create_equipment_template(item_name, description, value, weight, equip_slot, rarity, armor, damage, durability, strength_bonus, dexterity_bonus, intelligence_bonus, template_id)
	return spawn_instance(template.item_id, position)

# ============ 持久化方法 ============

func save_all_items():
	"""保存所有已注册的物品到文件"""
	if registry:
		return registry.save_to_file()
	return false

func load_all_items():
	"""从文件加载物品"""
	if registry:
		return registry.load_from_file()
	return false

func load_and_spawn_items():
	"""加载物品数据并生成到地图上"""
	if not registry:
		push_error("物品注册器未初始化")
		return false
	
	if not items_container:
		push_error("ItemsContainer 未找到,无法生成物品")
		return false
	
	# 加载物品数据
	if not registry.load_from_file():
		print("没有找到保存的物品数据,或加载失败")
		return false
	
	print("\n=== 开始生成已加载的物品实例 ===")
	
	# 遍历所有已注册的物品实例
	var spawned_count = 0
	for instance in registry.get_all_instances():
		if instance.position != Vector2.ZERO and instance.template:
			ItemSpawner.spawn_item(instance.template, instance.position, items_container, instance.count)
			print("生成了: %s x%d at %s [实例:%s]" % [instance.get_item_name(), instance.count, instance.position, instance.instance_id])
			spawned_count += 1
		else:
			print("跳过: 实例 %s (无效位置或模板)" % instance.instance_id)
	
	print("=== 共生成 %d 个物品实例 ===\n" % spawned_count)
	return true

func get_template(template_id: String) -> ItemBase:
	"""通过ID获取物品模板"""
	if registry:
		return registry.get_template(template_id)
	return null

func get_instance(instance_id: String) -> ItemInstance:
	"""通过ID获取物品实例"""
	if registry:
		return registry.get_instance(instance_id)
	return null

func print_all_items():
	"""打印所有已注册的物品"""
	if registry:
		registry.print_registry()
