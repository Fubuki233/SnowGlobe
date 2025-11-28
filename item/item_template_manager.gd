# item_template_manager.gd
extends Node
class_name ItemTemplateManager

signal item_registered(item_id: String, item_data: ItemData)
signal item_updated(item_id: String, item_data: ItemData)
signal item_removed(item_id: String)

var _item_templates: Dictionary = {}
var _item_factories: Dictionary = {}

func _ready():
    # 注册内置物品类型工厂
    register_item_factory("base", _create_base_item)
    register_item_factory("weapon", _create_weapon_item)
    register_item_factory("consumable", _create_consumable_item)
    print("[ItemSystem] 物品模板管理器已初始化")

func register_item_template(item_data: ItemData) -> bool:
    if item_data.item_id.is_empty():
        push_error("物品ID不能为空")
        return false
    
    if _item_templates.has(item_data.item_id):
        push_warning("物品ID已存在: " + item_data.item_id)
        return false
    
    _item_templates[item_data.item_id] = item_data
    print("[ItemSystem] 注册物品: ", item_data.item_id)
    item_registered.emit(item_data.item_id, item_data)
    return true

func update_item_template(item_id: String, item_data: ItemData) -> bool:
    if not _item_templates.has(item_id):
        push_error("物品不存在: " + item_id)
        return false
    
    _item_templates[item_id] = item_data
    print("[ItemSystem] 更新物品: ", item_id)
    item_updated.emit(item_id, item_data)
    return true

func remove_item_template(item_id: String) -> bool:
    if not _item_templates.has(item_id):
        return false
    
    _item_templates.erase(item_id)
    print("[ItemSystem] 移除物品: ", item_id)
    item_removed.emit(item_id)
    return true

func get_item_template(item_id: String) -> ItemData:
    return _item_templates.get(item_id)

func get_all_templates() -> Dictionary:
    return _item_templates.duplicate()

func create_item_instance(item_id: String, quantity: int = 1) -> ItemInstance:
    var template = get_item_template(item_id)
    if not template:
        push_error("物品模板不存在: " + item_id)
        return null
    
    var factory_func = _item_factories.get(template.item_type, _create_base_item)
    var instance = factory_func.call(template)
    instance.quantity = min(quantity, template.max_stack)
    return instance

func register_item_factory(item_type: String, factory_func: Callable):
    _item_factories[item_type] = factory_func
    print("[ItemSystem] 注册物品工厂: ", item_type)

# 内置工厂函数
func _create_base_item(template: ItemData) -> ItemInstance:
    var instance = ItemInstance.new()
    instance.setup_from_template(template)
    return instance

func _create_weapon_item(template: ItemData) -> WeaponItem:
    var instance = WeaponItem.new()
    instance.setup_from_template(template)
    instance.damage = template.custom_properties.get("damage", 0)
    instance.attack_speed = template.custom_properties.get("attack_speed", 1.0)
    return instance

func _create_consumable_item(template: ItemData) -> ConsumableItem:
    var instance = ConsumableItem.new()
    instance.setup_from_template(template)
    instance.effect_type = template.custom_properties.get("effect_type", "heal")
    instance.effect_value = template.custom_properties.get("effect_value", 0)
    return instance

# RPC 方法
func rpc_register_item(item_data_dict: Dictionary) -> Dictionary:
    var item_data = ItemData.from_dict(item_data_dict)
    var success = register_item_template(item_data)
    return {"success": success, "item_id": item_data.item_id}

func rpc_update_item(item_id: String, item_data_dict: Dictionary) -> Dictionary:
    var item_data = ItemData.from_dict(item_data_dict)
    var success = update_item_template(item_id, item_data)
    return {"success": success}

func rpc_remove_item(item_id: String) -> Dictionary:
    var success = remove_item_template(item_id)
    return {"success": success}

func rpc_get_item(item_id: String) -> Dictionary:
    var template = get_item_template(item_id)
    if template:
        return {"success": true, "item_data": template.to_dict()}
    else:
        return {"success": false, "error": "物品不存在"}

func rpc_get_all_items() -> Dictionary:
    var all_items = {}
    for item_id in _item_templates:
        all_items[item_id] = _item_templates[item_id].to_dict()
    return {"success": true, "items": all_items}