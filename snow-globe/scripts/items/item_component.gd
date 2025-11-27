extends Node
class_name ItemComponent

"""
物品组件基类 - 组合
"""

var owner_item: ItemBase = null

func _init(item: ItemBase = null):
	owner_item = item

func on_acquire(acquirer: Node) -> void:
	pass

func on_drop(dropper: Node) -> void:
	pass

func on_use(user: Node) -> void:
	pass

func update(delta: float) -> void:
	pass
