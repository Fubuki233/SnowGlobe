extends ItemBase
class_name AdvancedItem

"""
高级物品
"""

var components: Array[ItemComponent] = []

func _init():
	super._init()

func add_component(component: ItemComponent) -> void:
	component.owner_item = self
	components.append(component)
	print("为 %s 添加了组件: %s" % [item_name, component.get_class()])

func remove_component(component: ItemComponent) -> void:
	components.erase(component)

func get_component(component_type: String) -> ItemComponent:
	for comp in components:
		if comp.get_class() == component_type:
			return comp
	return null

func update(delta: float) -> void:
	for component in components:
		component.update(delta)

func use(user: Node) -> bool:
	for component in components:
		component.on_use(user)
	return super.use(user)

func on_acquire(acquirer: Node) -> void:
	for component in components:
		component.on_acquire(acquirer)

func on_drop(dropper: Node) -> void:
	for component in components:
		component.on_drop(dropper)
