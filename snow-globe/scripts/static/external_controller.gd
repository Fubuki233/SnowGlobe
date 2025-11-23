extends Node
@export var id = "external_controller"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GodotRPC.register_instance(id, self)


func move_to_position(instance_id: String, pos: Array):
	var instance = GodotRPC.get_instance(instance_id)
	if instance and instance.has_method("move_to_position"):
		instance.move_to_position(pos)
	else:
		print("找不到 ID 为 '", instance_id, "' 的实例或方法")