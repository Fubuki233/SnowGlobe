extends Node2D
class_name AIWeapon

"""
AI 生成的武器基础脚本
这个脚本会被挂载到 weapon_preset.tscn 的根节点
"""

# 基础信息
@export var display_name: String = "未命名武器"
@export_multiline var description: String = "这是一件普通的武器"

# 武器基础属性（可由 AI JSON 配置）
@export var damage: int = 10
@export var fire_damage: int = 0
@export var ice_damage: int = 0
@export var poison_damage: int = 0
@export var durability: int = 100
@export var max_durability: int = 100
@export var rarity: String = "common"
@export var price: int = 100
@export var weight: float = 1.0

# 武器特殊属性
@export var attack_speed: float = 1.0
@export var critical_chance: float = 0.05
@export var critical_damage: float = 1.5

# 属性修改效果（装备时生效）- 移动属性
@export var speed_bonus: float = 0.0
@export var path_speed_bonus: float = 0.0
@export var running_speed_bonus: float = 0.0

# 基础能力值加成
@export var strength_bonus: int = 0
@export var agility_bonus: int = 0
@export var intelligence_bonus: int = 0
@export var charisma_bonus: int = 0
@export var endurance_bonus: int = 0
@export var luck_bonus: int = 0
@export var perception_bonus: int = 0
@export var wisdom_bonus: int = 0

# 技能属性加成
@export var mental_strength_bonus: int = 0
@export var social_skills_bonus: int = 0
@export var combat_skills_bonus: int = 0
@export var crafting_skills_bonus: int = 0
@export var survival_skills_bonus: int = 0
@export var stealth_skills_bonus: int = 0
@export var cooking_bonus: int = 0

# 当前使用者
var current_user: Node = null

func _ready() -> void:
	print("武器已创建: 伤害=%d, 稀有度=%s" % [damage, rarity])

func use(user: Node = null) -> void:
	"""使用武器（攻击）"""
	if user:
		current_user = user
	
	if current_user:
		print("%s 使用武器攻击! 总伤害: %d" % [current_user.npc_name if "npc_name" in current_user else "未知", get_total_damage()])
		# 消耗耐久
		durability = max(0, durability - 1)
		if durability == 0:
			print("武器已损坏！")
	else:
		print("使用武器攻击! 总伤害: %d" % get_total_damage())

func equip(user: Node) -> void:
	"""装备武器到使用者"""
	if not user:
		push_error("无效的使用者")
		return
	
	# 卸下旧武器
	if current_user:
		unequip()
	
	current_user = user
	
	# 应用属性加成 - 移动属性
	if speed_bonus > 0 and "speed" in user:
		user.speed += speed_bonus
	
	if path_speed_bonus > 0 and "path_speed" in user:
		user.path_speed += path_speed_bonus
	
	if running_speed_bonus > 0 and "running_speed" in user:
		user.running_speed += running_speed_bonus
	
	# 基础能力值
	if strength_bonus > 0 and "strength" in user:
		user.strength += strength_bonus
	
	if agility_bonus > 0 and "agility" in user:
		user.agility += agility_bonus
	
	if intelligence_bonus > 0 and "intelligence" in user:
		user.intelligence += intelligence_bonus
	
	if charisma_bonus > 0 and "charisma" in user:
		user.charisma += charisma_bonus
	
	if endurance_bonus > 0 and "endurance" in user:
		user.endurance += endurance_bonus
	
	if luck_bonus > 0 and "luck" in user:
		user.luck += luck_bonus
	
	if perception_bonus > 0 and "perception" in user:
		user.perception += perception_bonus
	
	if wisdom_bonus > 0 and "wisdom" in user:
		user.wisdom += wisdom_bonus
	
	# 技能属性
	if mental_strength_bonus > 0 and "mental_strength" in user:
		user.mental_strength += mental_strength_bonus
	
	if social_skills_bonus > 0 and "social_skills" in user:
		user.social_skills += social_skills_bonus
	
	if combat_skills_bonus > 0 and "combat_skills" in user:
		user.combat_skills += combat_skills_bonus
	
	if crafting_skills_bonus > 0 and "crafting_skills" in user:
		user.crafting_skills += crafting_skills_bonus
	
	if survival_skills_bonus > 0 and "survival_skills" in user:
		user.survival_skills += survival_skills_bonus
	
	if stealth_skills_bonus > 0 and "stealth_skills" in user:
		user.stealth_skills += stealth_skills_bonus
	
	if cooking_bonus > 0 and "cooking" in user:
		user.cooking += cooking_bonus
	
	print("%s 装备了武器: %s" % [
		user.npc_name if "npc_name" in user else "未知",
		name
	])

func unequip() -> void:
	"""卸下武器"""
	if not current_user:
		return
	
	# 移除属性加成 - 移动属性
	if speed_bonus > 0 and "speed" in current_user:
		current_user.speed -= speed_bonus
	
	if path_speed_bonus > 0 and "path_speed" in current_user:
		current_user.path_speed -= path_speed_bonus
	
	if running_speed_bonus > 0 and "running_speed" in current_user:
		current_user.running_speed -= running_speed_bonus
	
	# 基础能力值
	if strength_bonus > 0 and "strength" in current_user:
		current_user.strength -= strength_bonus
	
	if agility_bonus > 0 and "agility" in current_user:
		current_user.agility -= agility_bonus
	
	if intelligence_bonus > 0 and "intelligence" in current_user:
		current_user.intelligence -= intelligence_bonus
	
	if charisma_bonus > 0 and "charisma" in current_user:
		current_user.charisma -= charisma_bonus
	
	if endurance_bonus > 0 and "endurance" in current_user:
		current_user.endurance -= endurance_bonus
	
	if luck_bonus > 0 and "luck" in current_user:
		current_user.luck -= luck_bonus
	
	if perception_bonus > 0 and "perception" in current_user:
		current_user.perception -= perception_bonus
	
	if wisdom_bonus > 0 and "wisdom" in current_user:
		current_user.wisdom -= wisdom_bonus
	
	# 技能属性
	if mental_strength_bonus > 0 and "mental_strength" in current_user:
		current_user.mental_strength -= mental_strength_bonus
	
	if social_skills_bonus > 0 and "social_skills" in current_user:
		current_user.social_skills -= social_skills_bonus
	
	if combat_skills_bonus > 0 and "combat_skills" in current_user:
		current_user.combat_skills -= combat_skills_bonus
	
	if crafting_skills_bonus > 0 and "crafting_skills" in current_user:
		current_user.crafting_skills -= crafting_skills_bonus
	
	if survival_skills_bonus > 0 and "survival_skills" in current_user:
		current_user.survival_skills -= survival_skills_bonus
	
	if stealth_skills_bonus > 0 and "stealth_skills" in current_user:
		current_user.stealth_skills -= stealth_skills_bonus
	
	if cooking_bonus > 0 and "cooking" in current_user:
		current_user.cooking -= cooking_bonus
	
	print("%s 卸下了武器: %s" % [
		current_user.npc_name if "npc_name" in current_user else "未知",
		name
	])
	
	current_user = null

func get_user() -> Node:
	"""获取当前使用者"""
	return current_user

func get_total_damage() -> int:
	"""获取总伤害"""
	return damage + fire_damage + ice_damage + poison_damage

func repair(amount: int) -> void:
	"""修复耐久度"""
	durability = min(durability + amount, max_durability)
	print("武器已修复，当前耐久: %d/%d" % [durability, max_durability])
