extends ItemBase
class_name EquipmentItem

"""
装备类
"""

#=========================== 装备槽位 ===========================
enum EquipSlot {
	HEAD, # 头部
	CHEST, # 胸部
	LEGS, # 腿部
	FEET, # 脚部
	HANDS, # 手部
	MAIN_HAND, # 主手
	OFF_HAND, # 副手
	ACCESSORY # 饰品
}
@export var equip_slot: EquipSlot = EquipSlot.CHEST

#=========================== 装备属性 ===========================
@export var armor: int = 0
@export var damage: int = 0
@export var durability: int = 100
@export var max_durability: int = 100

#=========================== 属性加成 ===========================
@export var strength_bonus: int = 0
@export var agility_bonus: int = 0
@export var intelligence_bonus: int = 0
@export var endurance_bonus: int = 0

func _init():
	super._init()
	item_type = ItemType.EQUIPMENT
	is_stackable = false
	max_stack = 1

func use(user: Node) -> bool:
	if not can_use():
		return false
	
	# 这里应该调用装备系统
	print("%s 装备了 %s" % [user.npc_name if user.has("npc_name") else "玩家", item_name])
	return true

func can_use() -> bool:
	return durability > 0

func repair(amount: int) -> void:
	durability = min(durability + amount, max_durability)
	print("%s 修理了 %d 点耐久度" % [item_name, amount])

func take_damage(amount: int) -> void:
	durability = max(0, durability - amount)
	if durability == 0:
		print("%s 已损坏!" % item_name)

func get_item_info() -> Dictionary:
	var info = super.get_item_info()
	info["equip_slot"] = EquipSlot.keys()[equip_slot]
	info["armor"] = armor
	info["damage"] = damage
	info["durability"] = durability
	info["max_durability"] = max_durability
	info["bonuses"] = get_stat_bonuses()
	return info

func get_stat_bonuses() -> Dictionary:
	return {
		"strength": strength_bonus,
		"agility": agility_bonus,
		"intelligence": intelligence_bonus,
		"endurance": endurance_bonus
	}

func get_tooltip_text() -> String:
	"""获取装备提示文本"""
	var text = super.get_tooltip_text()
	text += "\n[color=yellow]装备槽位:[/color] %s\n" % EquipSlot.keys()[equip_slot]
	text += "[color=cyan]耐久度:[/color] %d/%d\n" % [durability, max_durability]
	
	if armor > 0:
		text += "[color=green]护甲:[/color] +%d\n" % armor
	if damage > 0:
		text += "[color=red]伤害:[/color] +%d\n" % damage
	
	var bonuses = get_stat_bonuses()
	if bonuses.values().any(func(v): return v > 0):
		text += "\n[color=yellow]属性加成:[/color]\n"
		for stat in bonuses:
			if bonuses[stat] > 0:
				text += "  %s: +%d\n" % [stat.capitalize(), bonuses[stat]]
	
	return text
