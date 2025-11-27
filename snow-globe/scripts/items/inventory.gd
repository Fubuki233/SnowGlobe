extends Node
class_name Inventory

"""
背包/物品栏系统
"""

signal item_added(item: ItemBase, count: int)
signal item_removed(item: ItemBase, count: int)
signal inventory_full()
signal inventory_changed()

@export var max_slots: int = 20
@export var max_weight: float = 100.0

class ItemSlot:
	var item: ItemBase = null
	var count: int = 0
	
	func is_empty() -> bool:
		return item == null or count <= 0
	
	func can_stack_with(other_item: ItemBase) -> bool:
		if item == null:
			return true
		if item.item_id != other_item.item_id:
			return false
		if not item.is_stackable:
			return false
		return count < item.max_stack
	
	func add(new_item: ItemBase, amount: int) -> int:
		if item == null:
			item = new_item
			count = min(amount, new_item.max_stack)
			return count
		
		if item.item_id == new_item.item_id and item.is_stackable:
			var space = item.max_stack - count
			var add_amount = min(amount, space)
			count += add_amount
			return add_amount
		
		return 0
	
	func remove(amount: int) -> int:
		var remove_amount = min(amount, count)
		count -= remove_amount
		if count <= 0:
			item = null
			count = 0
		return remove_amount

# 物品槽位数组
var slots: Array[ItemSlot] = []

func _init():
	# 初始化槽位
	for i in range(max_slots):
		slots.append(ItemSlot.new())

func add_item(item: ItemBase, count: int = 1) -> bool:
	"""
	添加物品到背包
	返回是否成功添加
	"""
	var remaining = count
	
	# 先尝试堆叠到现有槽位
	if item.is_stackable:
		for slot in slots:
			if slot.item and slot.item.item_id == item.item_id:
				var added = slot.add(item, remaining)
				remaining -= added
				if remaining <= 0:
					item_added.emit(item, count)
					inventory_changed.emit()
					return true
	
	# 再尝试放入空槽位
	for slot in slots:
		if slot.is_empty():
			var added = slot.add(item, remaining)
			remaining -= added
			if remaining <= 0:
				item_added.emit(item, count)
				inventory_changed.emit()
				return true
	
	# 背包满了
	if remaining > 0:
		inventory_full.emit()
		if remaining < count:
			# 部分添加成功
			item_added.emit(item, count - remaining)
			inventory_changed.emit()
		return false
	
	return true

func remove_item(item: ItemBase, count: int = 1) -> bool:
	"""
	从背包移除物品
	返回是否成功移除
	"""
	var remaining = count
	
	for slot in slots:
		if slot.item and slot.item.item_id == item.item_id:
			var removed = slot.remove(remaining)
			remaining -= removed
			if remaining <= 0:
				item_removed.emit(item, count)
				inventory_changed.emit()
				return true
	
	return remaining <= 0

func remove_item_at_slot(slot_index: int, count: int = 1) -> bool:
	"""从指定槽位移除物品"""
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var slot = slots[slot_index]
	if slot.is_empty():
		return false
	
	var removed_item = slot.item
	var removed = slot.remove(count)
	
	if removed > 0:
		item_removed.emit(removed_item, removed)
		inventory_changed.emit()
		return true
	
	return false

func has_item(item: ItemBase, count: int = 1) -> bool:
	"""检查是否有足够数量的物品"""
	var total = 0
	for slot in slots:
		if slot.item and slot.item.item_id == item.item_id:
			total += slot.count
			if total >= count:
				return true
	return false

func get_item_count(item: ItemBase) -> int:
	"""获取物品总数量"""
	var total = 0
	for slot in slots:
		if slot.item and slot.item.item_id == item.item_id:
			total += slot.count
	return total

func get_total_weight() -> float:
	"""获取当前总重量"""
	var total = 0.0
	for slot in slots:
		if not slot.is_empty():
			total += slot.item.weight * slot.count
	return total

func is_overweight() -> bool:
	"""检查是否超重"""
	return get_total_weight() > max_weight

func get_empty_slots() -> int:
	"""获取空槽位数量"""
	var count = 0
	for slot in slots:
		if slot.is_empty():
			count += 1
	return count

func get_all_items() -> Array[Dictionary]:
	"""获取所有物品信息"""
	var items: Array[Dictionary] = []
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot.is_empty():
			items.append({
				"slot_index": i,
				"item": slot.item,
				"count": slot.count
			})
	return items

func clear() -> void:
	"""清空背包"""
	for slot in slots:
		slot.item = null
		slot.count = 0
	inventory_changed.emit()

func sort_by_type() -> void:
	"""按类型排序"""
	# 提取所有非空物品
	var items_data: Array[Dictionary] = []
	for slot in slots:
		if not slot.is_empty():
			items_data.append({"item": slot.item, "count": slot.count})
	
	# 清空槽位
	for slot in slots:
		slot.item = null
		slot.count = 0
	
	# 按类型排序
	items_data.sort_custom(func(a, b): return a.item.item_type < b.item.item_type)
	
	# 重新填充
	var index = 0
	for data in items_data:
		if index < slots.size():
			slots[index].item = data.item
			slots[index].count = data.count
			index += 1
	
	inventory_changed.emit()

func sort_by_value() -> void:
	"""按价值排序"""
	var items_data: Array[Dictionary] = []
	for slot in slots:
		if not slot.is_empty():
			items_data.append({"item": slot.item, "count": slot.count})
	
	for slot in slots:
		slot.item = null
		slot.count = 0
	
	items_data.sort_custom(func(a, b): return a.item.value > b.item.value)
	
	var index = 0
	for data in items_data:
		if index < slots.size():
			slots[index].item = data.item
			slots[index].count = data.count
			index += 1
	
	inventory_changed.emit()
