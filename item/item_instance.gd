# item_instance.gd
class_name ItemInstance
extends RefCounted

var item_id: String
var display_name: String
var description: String
var texture: Texture2D
var max_stack: int
var item_type: String
var quantity: int = 1
var custom_data: Dictionary = {}

func setup_from_template(template: ItemData):
    item_id = template.item_id
    display_name = template.display_name
    description = template.description
    texture = template.texture
    max_stack = template.max_stack
    item_type = template.item_type
    custom_data = template.custom_properties.duplicate()

func can_stack_with(other: ItemInstance) -> bool:
    return item_id == other.item_id and quantity < max_stack

func stack_items(other: ItemInstance) -> int:
    if not can_stack_with(other):
        return 0
    
    var total = quantity + other.quantity
    if total <= max_stack:
        quantity = total
        other.quantity = 0
        return other.quantity
    else:
        var transferred = max_stack - quantity
        quantity = max_stack
        other.quantity -= transferred
        return transferred

func to_dict() -> Dictionary:
    return {
        "item_id": item_id,
        "display_name": display_name,
        "quantity": quantity,
        "max_stack": max_stack,
        "item_type": item_type
    }