# item_data.gd
class_name ItemData
extends Resource

@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var texture: Texture2D
@export var max_stack: int = 1
@export var item_type: String = "misc"
@export var rarity: String = "common"
@export var custom_properties: Dictionary = {}

func _init(p_id: String = "", p_name: String = "", p_desc: String = ""):
    item_id = p_id
    display_name = p_name
    description = p_desc

func to_dict() -> Dictionary:
    return {
        "item_id": item_id,
        "display_name": display_name,
        "description": description,
        "max_stack": max_stack,
        "item_type": item_type,
        "rarity": rarity,
        "custom_properties": custom_properties
    }

static func from_dict(data: Dictionary) -> ItemData:
    var item = ItemData.new()
    item.item_id = data.get("item_id", "")
    item.display_name = data.get("display_name", "")
    item.description = data.get("description", "")
    item.max_stack = data.get("max_stack", 1)
    item.item_type = data.get("item_type", "misc")
    item.rarity = data.get("rarity", "common")
    item.custom_properties = data.get("custom_properties", {})
    return item