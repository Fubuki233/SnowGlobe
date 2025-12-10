extends Node
class_name InventorySystem

"""
背包系统
基于角色力量值计算承重上限: max_weight = 10 * strength
支持存储 res://scripts/items 下的所有物品类型
"""

signal inventory_changed(item_data: Dictionary)

# 背包容量
var max_weight: float = 0.0 # 最大承重 = 10 * strength
var current_weight: float = 0.0 # 当前重量

# 背包存储 {item_id: {item: Node, quantity: int, weight: float}}
var items: Dictionary = {}

# 物品类型映射
const ITEM_TYPES = {
	"weapon": preload("res://scripts/items/ai_weapon.gd"),
	"plant": preload("res://scripts/items/ai_plant.gd"),
	"consumable": preload("res://scripts/items/ai_consumable.gd")
}

func _init(strength: int = 1):
	"""初始化背包,基于力量值设置承重上限"""
	update_max_weight(strength)
	print("[背包系统] 初始化完成 | 最大承重: %.1f kg" % max_weight)

func update_max_weight(strength: int):
	"""更新最大承重 (基于力量值)"""
	max_weight = strength * 10.0
	print("[背包系统] 承重上限更新: %.1f kg (力量: %d)" % [max_weight, strength])

func can_add_item(weight: float, quantity: int = 1) -> bool:
	"""检查是否能添加物品"""
	var total_weight = weight * quantity
	return (current_weight + total_weight) <= max_weight

func add_item(item: Node, quantity: int = 1) -> bool:
	"""
	添加物品到背包
	item: 物品节点 (AIWeapon, AIPlant, AIConsumable)
	quantity: 数量
	返回: 是否成功添加
	"""
	if not item:
		print("[背包系统]  添加失败: 物品为空")
		return false
	
	# 获取物品重量
	var item_weight: float = 0.0
	if "weight" in item:
		item_weight = item.weight
	else:
		print("[背包系统]  物品没有 weight 属性,默认为 0.0")
	
	# 检查承重
	if not can_add_item(item_weight, quantity):
		print("[背包系统]  超重! 当前: %.1f kg, 需要: %.1f kg, 上限: %.1f kg" %
			[current_weight, item_weight * quantity, max_weight])
		return false
	
	# 获取物品 ID
	var item_id = _get_item_id(item)
	
	# 检查是否已存在
	if items.has(item_id):
		# 堆叠物品
		items[item_id]["quantity"] += quantity
		items[item_id]["weight"] = items[item_id]["quantity"] * item_weight
	else:
		# 新增物品
		items[item_id] = {
			"item": item,
			"quantity": quantity,
			"weight": item_weight * quantity,
			"unit_weight": item_weight,
			"type": _get_item_type(item)
		}
	
	# 更新总重量
	current_weight += item_weight * quantity
	
	print("[背包系统]  添加成功: %s x%d | 重量: %.1f kg | 总重: %.1f / %.1f kg" %
		[_get_item_display_name(item), quantity, item_weight * quantity, current_weight, max_weight])
	
	# 触发信号并打印背包内容
	_print_inventory()
	emit_signal("inventory_changed", get_inventory_data())
	
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	"""
	移除物品
	item_id: 物品 ID
	quantity: 移除数量
	返回: 是否成功移除
	"""
	if not items.has(item_id):
		print("[背包系统]  移除失败: 未找到物品 ID '%s'" % item_id)
		return false
	
	var item_data = items[item_id]
	
	if item_data["quantity"] < quantity:
		print("[背包系统]  移除失败: 数量不足 (拥有: %d, 需要: %d)" % [item_data["quantity"], quantity])
		return false
	
	# 减少数量
	item_data["quantity"] -= quantity
	var weight_removed = item_data["unit_weight"] * quantity
	current_weight -= weight_removed
	
	# 如果数量为 0,移除物品
	if item_data["quantity"] <= 0:
		items.erase(item_id)
		print("[背包系统]  移除成功: %s (全部) | 减少重量: %.1f kg" %
			[item_id, weight_removed])
	else:
		item_data["weight"] = item_data["quantity"] * item_data["unit_weight"]
		print("[背包系统]  移除成功: %s x%d | 剩余: %d | 减少重量: %.1f kg" %
			[item_id, quantity, item_data["quantity"], weight_removed])
	
	# 触发信号并打印背包内容
	_print_inventory()
	emit_signal("inventory_changed", get_inventory_data())
	
	return true

func has_item(item_id: String, quantity: int = 1) -> bool:
	"""检查是否拥有指定数量的物品"""
	if not items.has(item_id):
		return false
	return items[item_id]["quantity"] >= quantity

func get_item_quantity(item_id: String) -> int:
	"""获取物品数量"""
	if items.has(item_id):
		return items[item_id]["quantity"]
	return 0

func get_inventory_data() -> Dictionary:
	"""获取背包数据摘要"""
	return {
		"max_weight": max_weight,
		"current_weight": current_weight,
		"weight_percent": (current_weight / max_weight * 100.0) if max_weight > 0 else 0.0,
		"item_count": items.size(),
		"items": items.duplicate()
	}

func clear_inventory():
	"""清空背包"""
	items.clear()
	current_weight = 0.0
	print("[背包系统] 背包已清空")
	emit_signal("inventory_changed", get_inventory_data())

func _print_inventory():
	"""打印背包内容到控制台"""
	print("\n" + "=".repeat(60))
	print("[背包内容] 重量: %.1f / %.1f kg (%.1f%%) | 物品种类: %d" %
		[current_weight, max_weight,
		(current_weight / max_weight * 100.0) if max_weight > 0 else 0.0,
		items.size()])
	print("-".repeat(60))
	
	if items.is_empty():
		print("  (空)")
	else:
		var index = 1
		for item_id in items.keys():
			var item_data = items[item_id]
			var item = item_data["item"]
			print("  %d. %s x%d | 类型: %s | 重量: %.1f kg" %
				[index, _get_item_display_name(item), item_data["quantity"],
				item_data["type"], item_data["weight"]])
			index += 1
	
	print("=".repeat(60) + "\n")

# ==================== 私有辅助方法 ====================

func _get_item_id(item: Node) -> String:
	"""获取物品唯一 ID"""
	if "display_name" in item:
		return item.display_name
	return item.name

func _get_item_display_name(item: Node) -> String:
	"""获取物品显示名称"""
	if "display_name" in item:
		return item.display_name
	return item.name

func _get_item_type(item: Node) -> String:
	"""获取物品类型"""
	if item is AIWeapon:
		return "weapon"
	elif item is AIPlant:
		return "plant"
	elif item is AIConsumable:
		return "consumable"
	else:
		return "unknown"
