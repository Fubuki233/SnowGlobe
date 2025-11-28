extends ItemComponent
class_name GlowingComponent


@export var glow_color: Color = Color.WHITE
@export var glow_intensity: float = 1.0
@export var pulse_speed: float = 1.0

var time: float = 0.0

func _init(item: ItemBase = null):
	super._init(item)

func update(delta: float) -> void:
	time += delta * pulse_speed
	var current_intensity = glow_intensity * (0.5 + 0.5 * sin(time))

func on_acquire(acquirer: Node) -> void:
	print("获得了发光物品: %s (颜色: %s)" % [owner_item.item_name, glow_color])
