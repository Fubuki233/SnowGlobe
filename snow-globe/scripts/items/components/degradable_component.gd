extends ItemComponent
class_name DegradableComponent


@export var degradation_rate: float = 1.0 # 每秒降解量
@export var current_condition: float = 100.0
@export var max_condition: float = 100.0

func _init(item: ItemBase = null):
	super._init(item)

func update(delta: float) -> void:
	if current_condition > 0:
		current_condition = max(0, current_condition - degradation_rate * delta)
		if current_condition == 0:
			on_fully_degraded()

func on_fully_degraded() -> void:
	print("%s 已经完全降解!" % owner_item.item_name)

func repair(amount: float) -> void:
	current_condition = min(max_condition, current_condition + amount)

func get_condition_percentage() -> float:
	return (current_condition / max_condition) * 100.0
