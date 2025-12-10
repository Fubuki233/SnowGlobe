extends Node2D
class_name AIConsumable

"""
AI 生成的消耗品基础脚本
"""

# 基础信息
@export var display_name: String = "未命名消耗品"
@export_multiline var description: String = "这是一件普通的消耗品"

# 消耗品属性
@export var healing_amount: int = 50
@export var energy_amount: int = 0
@export var buff_duration: float = 0.0
@export var buff_type: String = ""
@export var stack_size: int = 99
@export var rarity: String = "common"
@export var price: int = 50

# 属性增益（临时或永久）
@export var hunger_restore: int = 0
@export var thirst_restore: int = 0

# 移动属性增益
@export var speed_buff: float = 0.0
@export var path_speed_buff: float = 0.0
@export var running_speed_buff: float = 0.0

# 基础能力值增益
@export var strength_buff: int = 0
@export var agility_buff: int = 0
@export var intelligence_buff: int = 0
@export var charisma_buff: int = 0
@export var endurance_buff: int = 0
@export var luck_buff: int = 0
@export var perception_buff: int = 0
@export var wisdom_buff: int = 0

# 技能属性增益
@export var mental_strength_buff: int = 0
@export var social_skills_buff: int = 0
@export var combat_skills_buff: int = 0
@export var crafting_skills_buff: int = 0
@export var survival_skills_buff: int = 0
@export var stealth_skills_buff: int = 0
@export var cooking_buff: int = 0

@export var is_permanent_buff: bool = false

# 状态效果（治疗/解除）
@export var cure_poison: bool = false
@export var cure_sickness: bool = false
@export var remove_stress: bool = false
@export var cure_injury: bool = false
@export var cure_tiredness: bool = false

# 状态设置（强制改变状态）
@export var set_resting: bool = false
@export var set_energized: bool = false

# 当前使用者
var current_user: Node = null
var buff_timer: Timer = null

func _ready() -> void:
	print("消耗品已创建: 治疗=%d, 能量=%d" % [healing_amount, energy_amount])

# ==================== 背包检测方法 ====================

func is_in_inventory(character: Node = null) -> bool:
	"""检测物品是否在角色背包中"""
	if character:
		# 检测指定角色的背包
		if "inventory" in character and character.inventory:
			return character.inventory.has_item(display_name, 1)
		return false
	else:
		# 检测所有角色的背包
		return get_owner_character() != null

func get_owner_character() -> Node:
	"""获取拥有此物品的角色（遍历场景树查找）"""
	var root = get_tree().root if get_tree() else null
	if not root:
		return null
	
	var characters = _find_all_characters(root)
	for character in characters:
		if "inventory" in character and character.inventory:
			if character.inventory.has_item(display_name, 1):
				return character
	return null

func get_quantity_in_inventory(character: Node) -> int:
	"""获取物品在指定角色背包中的数量"""
	if not character or not "inventory" in character or not character.inventory:
		return 0
	return character.inventory.get_item_quantity(display_name)

func _find_all_characters(node: Node) -> Array:
	"""递归查找所有角色节点（拥有 inventory 属性的节点）"""
	var characters = []
	if "inventory" in node:
		characters.append(node)
	
	for child in node.get_children():
		characters.append_array(_find_all_characters(child))
	
	return characters

func use(user: Node = null) -> void:
	"""使用消耗品"""
	if not user:
		print("使用消耗品! 治疗: %d, 能量: %d" % [healing_amount, energy_amount])
		return
	
	current_user = user
	var user_name = user.npc_name if "npc_name" in user else "未知"
	
	print("%s 使用了消耗品: %s" % [user_name, name])
	
	# 1. 恢复生命值
	if healing_amount > 0 and "current_health" in user:
		var old_health = user.current_health
		user.current_health = min(user.current_health + healing_amount, user.max_health)
		print("   生命值: %d → %d (+%d)" % [old_health, user.current_health, user.current_health - old_health])
	
	# 2. 恢复能量
	if energy_amount > 0 and "energy" in user:
		var old_energy = user.energy
		user.energy = min(user.energy + energy_amount, user.max_energy)
		print("   能量: %d → %d (+%d)" % [old_energy, user.energy, user.energy - old_energy])
	
	# 3. 恢复饥饿度
	if hunger_restore > 0 and "hunger" in user:
		var old_hunger = user.hunger
		user.hunger = min(user.hunger + hunger_restore, user.max_hunger)
		print("   饥饿度: %d → %d (+%d)" % [old_hunger, user.hunger, user.hunger - old_hunger])
		if "is_hungry" in user:
			user.is_hungry = false
	
	# 4. 恢复口渴度
	if thirst_restore > 0 and "thirst" in user:
		var old_thirst = user.thirst
		user.thirst = min(user.thirst + thirst_restore, user.max_thirst)
		print("   口渴度: %d → %d (+%d)" % [old_thirst, user.thirst, user.thirst - old_thirst])
		if "is_thirsty" in user:
			user.is_thirsty = false
	
	# 5. 治疗状态异常
	if cure_poison and "is_sick" in user:
		user.is_sick = false
		print("   治疗中毒")
	
	if cure_sickness and "is_sick" in user:
		user.is_sick = false
		print("   治疗疾病")
	
	if remove_stress and "is_stressed" in user:
		user.is_stressed = false
		print("   消除压力")
	
	if cure_injury and "is_injured" in user:
		user.is_injured = false
		print("   治疗伤势")
	
	if cure_tiredness and "is_tired" in user:
		user.is_tired = false
		print("   消除疲劳")
	
	# 6. 设置特殊状态
	if set_resting and "is_resting" in user:
		user.is_resting = true
		print("   进入休息状态")
	
	if set_energized and "is_tired" in user:
		user.is_tired = false
		if "energy" in user:
			user.energy = user.max_energy
		print("   充满活力")
	
	# 7. 应用属性增益
	if is_permanent_buff:
		_apply_permanent_buffs(user)
	elif buff_duration > 0:
		_apply_temporary_buffs(user)
	
	print(" 消耗品使用完成")

func _apply_permanent_buffs(user: Node) -> void:
	"""应用永久属性加成"""
	print("   应用永久属性增益")
	
	# 移动属性
	if speed_buff > 0 and "speed" in user:
		user.speed += speed_buff
		print("    移动速度 +%.1f" % speed_buff)
	
	if path_speed_buff > 0 and "path_speed" in user:
		user.path_speed += path_speed_buff
		print("    路径速度 +%.1f" % path_speed_buff)
	
	if running_speed_buff > 0 and "running_speed" in user:
		user.running_speed += running_speed_buff
		print("    奔跑速度 +%.1f" % running_speed_buff)
	
	# 基础能力值
	if strength_buff > 0 and "strength" in user:
		user.strength += strength_buff
		print("    力量 +%d" % strength_buff)
	
	if agility_buff > 0 and "agility" in user:
		user.agility += agility_buff
		print("    敏捷 +%d" % agility_buff)
	
	if intelligence_buff > 0 and "intelligence" in user:
		user.intelligence += intelligence_buff
		print("    智力 +%d" % intelligence_buff)
	
	if charisma_buff > 0 and "charisma" in user:
		user.charisma += charisma_buff
		print("    魅力 +%d" % charisma_buff)
	
	if endurance_buff > 0 and "endurance" in user:
		user.endurance += endurance_buff
		print("    耐力 +%d" % endurance_buff)
	
	if luck_buff > 0 and "luck" in user:
		user.luck += luck_buff
		print("    幸运 +%d" % luck_buff)
	
	if perception_buff > 0 and "perception" in user:
		user.perception += perception_buff
		print("    感知 +%d" % perception_buff)
	
	if wisdom_buff > 0 and "wisdom" in user:
		user.wisdom += wisdom_buff
		print("    智慧 +%d" % wisdom_buff)
	
	# 技能属性
	if mental_strength_buff > 0 and "mental_strength" in user:
		user.mental_strength += mental_strength_buff
		print("    精神强度 +%d" % mental_strength_buff)
	
	if social_skills_buff > 0 and "social_skills" in user:
		user.social_skills += social_skills_buff
		print("    社交技能 +%d" % social_skills_buff)
	
	if combat_skills_buff > 0 and "combat_skills" in user:
		user.combat_skills += combat_skills_buff
		print("    战斗技能 +%d" % combat_skills_buff)
	
	if crafting_skills_buff > 0 and "crafting_skills" in user:
		user.crafting_skills += crafting_skills_buff
		print("    制作技能 +%d" % crafting_skills_buff)
	
	if survival_skills_buff > 0 and "survival_skills" in user:
		user.survival_skills += survival_skills_buff
		print("    生存技能 +%d" % survival_skills_buff)
	
	if stealth_skills_buff > 0 and "stealth_skills" in user:
		user.stealth_skills += stealth_skills_buff
		print("    潜行技能 +%d" % stealth_skills_buff)
	
	if cooking_buff > 0 and "cooking" in user:
		user.cooking += cooking_buff
		print("    烹饪技能 +%d" % cooking_buff)

func _apply_temporary_buffs(user: Node) -> void:
	"""应用临时属性加成"""
	print("   获得增益效果: %s (持续 %.1f 秒)" % [buff_type if buff_type else "属性提升", buff_duration])
	
	# 移动属性
	if speed_buff > 0 and "speed" in user:
		user.speed += speed_buff
		print("    移动速度 +%.1f" % speed_buff)
	
	if path_speed_buff > 0 and "path_speed" in user:
		user.path_speed += path_speed_buff
		print("    路径速度 +%.1f" % path_speed_buff)
	
	if running_speed_buff > 0 and "running_speed" in user:
		user.running_speed += running_speed_buff
		print("    奔跑速度 +%.1f" % running_speed_buff)
	
	# 基础能力值
	if strength_buff > 0 and "strength" in user:
		user.strength += strength_buff
		print("    力量 +%d" % strength_buff)
	
	if agility_buff > 0 and "agility" in user:
		user.agility += agility_buff
		print("    敏捷 +%d" % agility_buff)
	
	if intelligence_buff > 0 and "intelligence" in user:
		user.intelligence += intelligence_buff
		print("    智力 +%d" % intelligence_buff)
	
	if charisma_buff > 0 and "charisma" in user:
		user.charisma += charisma_buff
		print("    魅力 +%d" % charisma_buff)
	
	if endurance_buff > 0 and "endurance" in user:
		user.endurance += endurance_buff
		print("    耐力 +%d" % endurance_buff)
	
	if luck_buff > 0 and "luck" in user:
		user.luck += luck_buff
		print("    幸运 +%d" % luck_buff)
	
	if perception_buff > 0 and "perception" in user:
		user.perception += perception_buff
		print("    感知 +%d" % perception_buff)
	
	if wisdom_buff > 0 and "wisdom" in user:
		user.wisdom += wisdom_buff
		print("    智慧 +%d" % wisdom_buff)
	
	# 技能属性
	if mental_strength_buff > 0 and "mental_strength" in user:
		user.mental_strength += mental_strength_buff
		print("    精神强度 +%d" % mental_strength_buff)
	
	if social_skills_buff > 0 and "social_skills" in user:
		user.social_skills += social_skills_buff
		print("    社交技能 +%d" % social_skills_buff)
	
	if combat_skills_buff > 0 and "combat_skills" in user:
		user.combat_skills += combat_skills_buff
		print("    战斗技能 +%d" % combat_skills_buff)
	
	if crafting_skills_buff > 0 and "crafting_skills" in user:
		user.crafting_skills += crafting_skills_buff
		print("    制作技能 +%d" % crafting_skills_buff)
	
	if survival_skills_buff > 0 and "survival_skills" in user:
		user.survival_skills += survival_skills_buff
		print("    生存技能 +%d" % survival_skills_buff)
	
	if stealth_skills_buff > 0 and "stealth_skills" in user:
		user.stealth_skills += stealth_skills_buff
		print("    潜行技能 +%d" % stealth_skills_buff)
	
	if cooking_buff > 0 and "cooking" in user:
		user.cooking += cooking_buff
		print("    烹饪技能 +%d" % cooking_buff)
	
	# 创建计时器来移除 buff
	if buff_timer:
		buff_timer.queue_free()
	
	buff_timer = Timer.new()
	add_child(buff_timer)
	buff_timer.wait_time = buff_duration
	buff_timer.one_shot = true
	buff_timer.timeout.connect(_remove_temporary_buffs.bind(user))
	buff_timer.start()

func _remove_temporary_buffs(user: Node) -> void:
	"""移除临时属性加成"""
	if not user or not is_instance_valid(user):
		return
	
	var user_name = user.npc_name if "npc_name" in user else "未知"
	print("%s 的增益效果已结束" % user_name)
	
	# 移动属性
	if speed_buff > 0 and "speed" in user:
		user.speed -= speed_buff
	
	if path_speed_buff > 0 and "path_speed" in user:
		user.path_speed -= path_speed_buff
	
	if running_speed_buff > 0 and "running_speed" in user:
		user.running_speed -= running_speed_buff
	
	# 基础能力值
	if strength_buff > 0 and "strength" in user:
		user.strength -= strength_buff
	
	if agility_buff > 0 and "agility" in user:
		user.agility -= agility_buff
	
	if intelligence_buff > 0 and "intelligence" in user:
		user.intelligence -= intelligence_buff
	
	if charisma_buff > 0 and "charisma" in user:
		user.charisma -= charisma_buff
	
	if endurance_buff > 0 and "endurance" in user:
		user.endurance -= endurance_buff
	
	if luck_buff > 0 and "luck" in user:
		user.luck -= luck_buff
	
	if perception_buff > 0 and "perception" in user:
		user.perception -= perception_buff
	
	if wisdom_buff > 0 and "wisdom" in user:
		user.wisdom -= wisdom_buff
	
	# 技能属性
	if mental_strength_buff > 0 and "mental_strength" in user:
		user.mental_strength -= mental_strength_buff
	
	if social_skills_buff > 0 and "social_skills" in user:
		user.social_skills -= social_skills_buff
	
	if combat_skills_buff > 0 and "combat_skills" in user:
		user.combat_skills -= combat_skills_buff
	
	if crafting_skills_buff > 0 and "crafting_skills" in user:
		user.crafting_skills -= crafting_skills_buff
	
	if survival_skills_buff > 0 and "survival_skills" in user:
		user.survival_skills -= survival_skills_buff
	
	if stealth_skills_buff > 0 and "stealth_skills" in user:
		user.stealth_skills -= stealth_skills_buff
	
	if cooking_buff > 0 and "cooking" in user:
		user.cooking -= cooking_buff
	
	if buff_timer:
		buff_timer.queue_free()
		buff_timer = null

func get_user() -> Node:
	"""获取当前使用者"""
	return current_user
