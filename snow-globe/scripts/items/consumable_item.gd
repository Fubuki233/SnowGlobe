extends ItemBase
class_name ConsumableItem

"""
消耗品类 
"""

#=========================== 消耗品特有属性 ===========================
@export var restore_health: int = 0
@export var restore_energy: int = 0
@export var restore_hunger: int = 0
@export var restore_thirst: int = 0
@export var buff_duration: float = 0.0
@export var buff_effects: Dictionary = {}

func _init():
	super._init() # 调用父类的初始化
	item_type = ItemType.CONSUMABLE
	is_stackable = true
	max_stack = 99

func use(user: Node) -> bool:
	if not can_use():
		return false
	
	# 检查user是否有对应的属性
	if user.has("current_health") and restore_health > 0:
		user.current_health = min(user.current_health + restore_health, user.max_health)
		print("%s 恢复了 %d 生命值" % [user.npc_name, restore_health])
	
	if user.has("energy") and restore_energy > 0:
		user.energy = min(user.energy + restore_energy, user.max_energy)
		print("%s 恢复了 %d 能量" % [user.npc_name, restore_energy])
	
	if user.has("hunger") and restore_hunger > 0:
		user.hunger = min(user.hunger + restore_hunger, user.max_hunger)
		print("%s 恢复了 %d 饱食度" % [user.npc_name, restore_hunger])
	
	if user.has("thirst") and restore_thirst > 0:
		user.thirst = min(user.thirst + restore_thirst, user.max_thirst)
		print("%s 恢复了 %d 水分" % [user.npc_name, restore_thirst])
	
	# 应用buff效果
	if buff_duration > 0 and buff_effects.size() > 0:
		apply_buff(user)
	
	return true

func apply_buff(user: Node) -> void:
	"""应用增益效果"""
	print("对 %s 应用了增益效果,持续 %.1f 秒" % [user.npc_name, buff_duration])
	# 这里可以实现具体的buff逻辑

func get_item_info() -> Dictionary:
	var info = super.get_item_info() # 获取父类信息
	info["restore_health"] = restore_health
	info["restore_energy"] = restore_energy
	info["restore_hunger"] = restore_hunger
	info["restore_thirst"] = restore_thirst
	info["buff_duration"] = buff_duration
	return info

func get_tooltip_text() -> String:
	var text = super.get_tooltip_text()
	text += "\n[color=green]效果:[/color]\n"
	if restore_health > 0:
		text += "  恢复生命: +%d\n" % restore_health
	if restore_energy > 0:
		text += "  恢复能量: +%d\n" % restore_energy
	if restore_hunger > 0:
		text += "  恢复饱食: +%d\n" % restore_hunger
	if restore_thirst > 0:
		text += "  恢复水分: +%d\n" % restore_thirst
	return text
