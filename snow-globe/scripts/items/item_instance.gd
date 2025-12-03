class_name ItemInstance
extends Resource

"""
物品实例 - 表示地图上的一个物品
每个实例都有自己的:
- instance_id: 实例唯一ID
- position: 地图位置
- count: 堆叠数量
- template_id: 关联的物品模板ID
"""

@export var instance_id: String = "" # 实例ID
@export var template_id: String = "" # 物品模板ID
@export var position: Vector2 = Vector2.ZERO # 地图位置
@export var count: int = 1 # 数量

# 运行时引用(不序列化)
var template: ItemBase = null # 物品模板引用

func _init(p_template_id: String = "", p_position: Vector2 = Vector2.ZERO, p_count: int = 1):
	instance_id = UUIDGenerator.generate_uuid()
	template_id = p_template_id
	position = p_position
	count = p_count

func get_item_name() -> String:
	"""获取物品名称"""
	if template:
		return template.item_name
	return "未知物品"

func get_item_info() -> Dictionary:
	"""获取物品信息"""
	var info = {
		"instance_id": instance_id,
		"template_id": template_id,
		"position": position,
		"count": count
	}
	
	if template:
		info.merge(template.get_item_info())
	
	return info

func serialize() -> Dictionary:
	"""序列化为字典"""
	return {
		"instance_id": instance_id,
		"template_id": template_id,
		"position": {"x": position.x, "y": position.y},
		"count": count
	}

static func deserialize(data: Dictionary) -> ItemInstance:
	"""从字典反序列化"""
	var instance = ItemInstance.new()
	instance.instance_id = data.get("instance_id", "")
	instance.template_id = data.get("template_id", "")
	
	var pos_data = data.get("position", {"x": 0, "y": 0})
	instance.position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
	
	instance.count = data.get("count", 1)
	
	return instance
