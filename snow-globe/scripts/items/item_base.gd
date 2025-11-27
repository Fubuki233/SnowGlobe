extends Resource
class_name ItemBase

"""
物品基类 - 所有物品的父类
使用 Resource 作为基类,可以序列化保存
"""

#=========================== 基础属性 ===========================
@export var item_id: String = ""
@export var item_name: String = "未命名物品"
@export var description: String = "暂无描述"
@export var icon: Texture2D = null
@export var weight: float = 0.0
@export var value: int = 0
@export var max_stack: int = 1
@export var is_stackable: bool = false

#=========================== 物品类型 ===========================
enum ItemType {
	MISC, # 杂物
	CONSUMABLE, # 消耗品
	EQUIPMENT, # 装备
	WEAPON, # 武器
	ARMOR, # 护甲
	TOOL, # 工具
	MATERIAL, # 材料
	QUEST # 任务物品
}
@export var item_type: ItemType = ItemType.MISC

#=========================== 物品品质 ===========================
enum Rarity {
	COMMON, # 普通(白色)
	UNCOMMON, # 不常见(绿色)
	RARE, # 稀有(蓝色)
	EPIC, # 史诗(紫色)
	LEGENDARY # 传说(橙色)
}
@export var rarity: Rarity = Rarity.COMMON

#=========================== 标签系统 ===========================
@export var tags: Array[String] = []

func _init():
	"""初始化"""
	pass

func get_item_info() -> Dictionary:
	"""获取物品基本信息"""
	return {
		"item_id": item_id,
		"item_name": item_name,
		"description": description,
		"weight": weight,
		"value": value,
		"max_stack": max_stack,
		"is_stackable": is_stackable,
		"item_type": ItemType.keys()[item_type],
		"rarity": Rarity.keys()[rarity],
		"tags": tags
	}

func has_tag(tag: String) -> bool:
	"""检查是否有指定标签"""
	return tag in tags

func add_tag(tag: String) -> void:
	"""添加标签"""
	if not has_tag(tag):
		tags.append(tag)

func remove_tag(tag: String) -> void:
	"""移除标签"""
	if has_tag(tag):
		tags.erase(tag)

func use(user: Node) -> bool:
	"""
	使用物品 - 基类默认实现
	子类应该重写此方法
	"""
	print("使用了: ", item_name)
	return false

func can_use() -> bool:
	"""检查是否可以使用"""
	return true

func get_tooltip_text() -> String:
	"""获取提示文本"""
	var text = "[b]%s[/b]\n" % item_name
	text += "%s\n" % description
	text += "品质: %s\n" % Rarity.keys()[rarity]
	text += "价值: %d 金币\n" % value
	text += "重量: %.1f\n" % weight
	return text
