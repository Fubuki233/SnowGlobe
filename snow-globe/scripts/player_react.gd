@tool
extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass #

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_button_pressed():
	var player = get_node("Player")
	if player and player.has_method("move_to_random_position"):
		player.move_to_random_position()
	else:
		print("找不到 Player 或方法")
