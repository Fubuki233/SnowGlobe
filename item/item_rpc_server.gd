# item_rpc_server.gd
extends Node

@onready var item_manager: ItemTemplateManager = $ItemTemplateManager

func _ready():
    # 注册到RPC系统
    if has_node("/root/RPCServer"):
        var rpc_server = get_node("/root/RPCServer")
        rpc_server.register_instance("item_manager", self)
        print("[ItemSystem] RPC服务器已注册")

# RPC 方法
func register_item(item_data: Dictionary) -> Dictionary:
    return item_manager.rpc_register_item(item_data)

func update_item(item_id: String, item_data: Dictionary) -> Dictionary:
    return item_manager.rpc_update_item(item_id, item_data)

func remove_item(item_id: String) -> Dictionary:
    return item_manager.rpc_remove_item(item_id)

func get_item(item_id: String) -> Dictionary:
    return item_manager.rpc_get_item(item_id)

func get_all_items() -> Dictionary:
    return item_manager.rpc_get_all_items()

func create_item_instance(item_id: String, quantity: int = 1) -> Dictionary:
    var instance = item_manager.create_item_instance(item_id, quantity)
    if instance:
        return {"success": true, "instance": instance.to_dict()}
    else:
        return {"success": false, "error": "创建物品实例失败"}