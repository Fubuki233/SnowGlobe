class_name BlockBase
extends Node2D

# 这是一个基础方块脚本
# 你可以在这里定义所有方块通用的逻辑

func _ready() -> void:
	pass

func interact() -> void:
	print("Interacted with block: ", name)
