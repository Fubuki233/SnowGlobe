class_name ItemRegistry
extends Node

"""
物品注册器 - 管理物品模板和物品实例
功能:
- 管理物品模板(ItemBase)
- 管理物品实例(ItemInstance)
- 序列化/反序列化
- 保存/加载到文件
"""

signal template_registered(template_id: String, template: ItemBase)
signal template_unregistered(template_id: String)
signal instance_created(instance_id: String, instance: ItemInstance)
signal instance_removed(instance_id: String)

# 物品模板注册表 {template_id: ItemBase}
var item_templates: Dictionary = {}

# 物品实例注册表 {instance_id: ItemInstance}
var item_instances: Dictionary = {}

# 保存路径
const SAVE_PATH = "res://items_data.json"

# ============ 模板管理 ============

func register_template(template: ItemBase) -> bool:
	"""注册物品模板"""
	if not template or template.item_id.is_empty():
		push_error("无法注册: 模板为空或没有ID")
		return false
	
	if item_templates.has(template.item_id):
		push_warning("模板ID已存在,将覆盖: " + template.item_id)
	
	item_templates[template.item_id] = template
	template_registered.emit(template.item_id, template)
	print("注册模板: %s [%s]" % [template.item_name, template.item_id])
	return true

func unregister_template(template_id: String) -> bool:
	"""注销物品模板"""
	if not item_templates.has(template_id):
		push_warning("模板ID不存在: " + template_id)
		return false
	
	item_templates.erase(template_id)
	template_unregistered.emit(template_id)
	print("注销模板: " + template_id)
	return true

func get_template(template_id: String) -> ItemBase:
	"""通过ID获取物品模板"""
	return item_templates.get(template_id, null)

func get_all_templates() -> Array:
	"""获取所有物品模板"""
	return item_templates.values()

# ============ 实例管理 ============

func create_instance(template_id: String, position: Vector2, count: int = 1) -> ItemInstance:
	"""创建物品实例"""
	var template = get_template(template_id)
	if not template:
		push_error("模板不存在: " + template_id)
		return null
	
	var instance = ItemInstance.new(template_id, position, count)
	instance.template = template # 设置模板引用
	
	item_instances[instance.instance_id] = instance
	instance_created.emit(instance.instance_id, instance)
	print("创建实例: %s x%d at %s [实例ID: %s]" % [template.item_name, count, position, instance.instance_id])
	
	return instance

func remove_instance(instance_id: String) -> bool:
	"""移除物品实例"""
	if not item_instances.has(instance_id):
		push_warning("实例ID不存在: " + instance_id)
		return false
	
	item_instances.erase(instance_id)
	instance_removed.emit(instance_id)
	print("移除实例: " + instance_id)
	return true

func get_instance(instance_id: String) -> ItemInstance:
	"""通过ID获取物品实例"""
	return item_instances.get(instance_id, null)

func get_all_instances() -> Array:
	"""获取所有物品实例"""
	return item_instances.values()

func get_instances_by_template(template_id: String) -> Array:
	"""获取某个模板的所有实例"""
	var result = []
	for instance in item_instances.values():
		if instance.template_id == template_id:
			result.append(instance)
	return result

# ============ 序列化 ============

func serialize_template(template: ItemBase) -> Dictionary:
	"""将物品模板序列化为字典"""
	var data = {
		"item_id": template.item_id,
		"item_name": template.item_name,
		"description": template.description,
		"weight": template.weight,
		"value": template.value,
		"max_stack": template.max_stack,
		"is_stackable": template.is_stackable,
		"item_type": ItemBase.ItemType.keys()[template.item_type],
		"rarity": ItemBase.Rarity.keys()[template.rarity],
		"tags": template.tags,
		"class_type": template.get_class()
	}
	
	# 根据类型添加特定字段
	if template is ConsumableItem:
		data["consumable"] = {
			"restore_health": template.restore_health,
			"restore_energy": template.restore_energy,
			"restore_hunger": template.restore_hunger,
			"restore_thirst": template.restore_thirst,
			"buff_duration": template.buff_duration,
			"buff_effects": template.buff_effects
		}
	
	elif template is EquipmentItem:
		data["equipment"] = {
			"equip_slot": EquipmentItem.EquipSlot.keys()[template.equip_slot],
			"armor": template.armor,
			"damage": template.damage,
			"durability": template.durability,
			"max_durability": template.max_durability,
			"strength_bonus": template.strength_bonus,
			"agility_bonus": template.agility_bonus,
			"intelligence_bonus": template.intelligence_bonus,
			"endurance_bonus": template.endurance_bonus
		}
	
	return data

func deserialize_template(data: Dictionary) -> ItemBase:
	"""从字典反序列化物品模板"""
	var template: ItemBase
	
	# 根据类型创建实例
	var class_type = data.get("class_type", "ItemBase")
	match class_type:
		"ConsumableItem":
			template = ConsumableItem.new()
			if data.has("consumable"):
				var c = data["consumable"]
				template.restore_health = c.get("restore_health", 0)
				template.restore_energy = c.get("restore_energy", 0)
				template.restore_hunger = c.get("restore_hunger", 0)
				template.restore_thirst = c.get("restore_thirst", 0)
				template.buff_duration = c.get("buff_duration", 0.0)
				template.buff_effects = c.get("buff_effects", {})
		
		"EquipmentItem":
			template = EquipmentItem.new()
			if data.has("equipment"):
				var e = data["equipment"]
				var slot_name = e.get("equip_slot", "CHEST")
				template.equip_slot = EquipmentItem.EquipSlot[slot_name]
				template.armor = e.get("armor", 0)
				template.damage = e.get("damage", 0)
				template.durability = e.get("durability", 100)
				template.max_durability = e.get("max_durability", 100)
				template.strength_bonus = e.get("strength_bonus", 0)
				template.agility_bonus = e.get("agility_bonus", 0)
				template.intelligence_bonus = e.get("intelligence_bonus", 0)
				template.endurance_bonus = e.get("endurance_bonus", 0)
		
		_:
			template = ItemBase.new()
	
	# 设置基础属性
	template.item_id = data.get("item_id", "")
	template.item_name = data.get("item_name", "未命名")
	template.description = data.get("description", "")
	template.weight = data.get("weight", 0.0)
	template.value = data.get("value", 0)
	template.max_stack = data.get("max_stack", 1)
	template.is_stackable = data.get("is_stackable", false)
	
	# 设置枚举
	var type_name = data.get("item_type", "MISC")
	template.item_type = ItemBase.ItemType[type_name]
	
	var rarity_name = data.get("rarity", "COMMON")
	template.rarity = ItemBase.Rarity[rarity_name]
	
	template.icon = ItemIconManager.load_icon_by_id(template.item_id)
	
	return template

# ============ 持久化 ============

func save_to_file(file_path: String = SAVE_PATH) -> bool:
	"""保存模板和实例到文件"""
	var save_data = {
		"version": "2.0",
		"timestamp": Time.get_unix_time_from_system(),
		"template_count": item_templates.size(),
		"instance_count": item_instances.size(),
		"templates": [],
		"instances": []
	}
	
	# 序列化所有模板
	for template in item_templates.values():
		save_data["templates"].append(serialize_template(template))
	
	# 序列化所有实例
	for instance in item_instances.values():
		save_data["instances"].append(instance.serialize())
	
	# 写入文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("无法创建保存文件: " + file_path)
		return false
	
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("✓ 保存了 %d 个模板和 %d 个实例到: %s" % [save_data["template_count"], save_data["instance_count"], file_path])
	return true

func load_from_file(file_path: String = SAVE_PATH, clear_existing: bool = true) -> bool:
	"""从文件加载模板和实例"""
	if not FileAccess.file_exists(file_path):
		push_warning("保存文件不存在: " + file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("无法打开保存文件: " + file_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("JSON 解析失败: " + json.get_error_message())
		return false
	
	var save_data = json.data
	if not save_data is Dictionary:
		push_error("保存数据格式错误")
		return false
	
	if clear_existing:
		item_templates.clear()
		item_instances.clear()
		print("清空现有数据")
	
	# 加载模板
	var templates_data = save_data.get("templates", [])
	for template_data in templates_data:
		var template = deserialize_template(template_data)
		if template:
			item_templates[template.item_id] = template
	
	# 加载实例
	var instances_data = save_data.get("instances", [])
	for instance_data in instances_data:
		var instance = ItemInstance.deserialize(instance_data)
		if instance:
			# 关联模板
			instance.template = get_template(instance.template_id)
			item_instances[instance.instance_id] = instance
	
	print("✓ 加载了 %d 个模板和 %d 个实例" % [item_templates.size(), item_instances.size()])
	return true

# ============ 查询方法 ============

func find_templates_by_type(type: ItemBase.ItemType) -> Array:
	"""查找指定类型的所有模板"""
	var result = []
	for template in item_templates.values():
		if template.item_type == type:
			result.append(template)
	return result

func find_templates_by_rarity(rarity: ItemBase.Rarity) -> Array:
	"""查找指定稀有度的所有模板"""
	var result = []
	for template in item_templates.values():
		if template.rarity == rarity:
			result.append(template)
	return result

# ============ 统计和调试 ============

func print_registry():
	"""打印注册表内容"""
	print("\n=== 物品注册表 ===")
	print("模板数量: %d" % item_templates.size())
	print("实例数量: %d" % item_instances.size())
	
	if item_templates.size() > 0:
		print("\n--- 模板列表 ---")
		for template in item_templates.values():
			print("  [%s] %s (稀有度: %s)" % [template.item_id, template.item_name, ItemBase.Rarity.keys()[template.rarity]])
	
	if item_instances.size() > 0:
		print("\n--- 实例列表 ---")
		for instance in item_instances.values():
			var template_name = instance.get_item_name()
			print("  [%s] %s x%d @ %s (模板: %s)" % [instance.instance_id, template_name, instance.count, instance.position, instance.template_id])
	
	print("==================\n")
