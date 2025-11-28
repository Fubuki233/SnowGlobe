# weapon_item.gd
class_name WeaponItem
extends ItemInstance

var damage: int = 0
var attack_speed: float = 1.0
var weapon_type: String = "sword"

func to_dict() -> Dictionary:
    var data = super.to_dict()
    data["damage"] = damage
    data["attack_speed"] = attack_speed
    data["weapon_type"] = weapon_type
    return data

# consumable_item.gd
class_name ConsumableItem
extends ItemInstance

var effect_type: String = "heal"
var effect_value: float = 0.0

func to_dict() -> Dictionary:
    var data = super.to_dict()
    data["effect_type"] = effect_type
    data["effect_value"] = effect_value
    return data