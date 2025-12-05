extends "res://scripts/blocks/block_base.gd"

# 这是一个具体的陷阱方块示例

func _ready() -> void:
	super._ready()
	print("陷阱方块已生成在位置: ", global_position)
	# 这里可以添加初始化逻辑，比如播放动画

func _process(delta: float) -> void:
	# 示例：简单的旋转效果
	rotation += delta * 2.0

func interact() -> void:
	print("小心！这是一个陷阱！")
	# 这里可以添加触发陷阱的逻辑
