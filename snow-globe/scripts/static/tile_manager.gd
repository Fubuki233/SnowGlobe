extends TileMapLayer

func get_tile_name(tile_pos: Vector2i) -> String:
	var tile_data = get_cell_tile_data(tile_pos)
	if tile_data:
		var custom_name = tile_data.get_custom_data("Name")
		if custom_name != null:
			return str(custom_name)
	return ""

func _ready() -> void:
	pass
