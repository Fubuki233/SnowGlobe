extends CharacterBody2D
signal hit
signal player_moved(new_position: Vector2)
@export var id = "player_1"
@export var speed = 256.0
@export var path_speed = 256.0

var is_moving_to_target = false
var target_path: PackedVector2Array = []
var current_path_index = 0

func _ready() -> void:
	GodotRPC.register_instance(id, self)
	# 连接 Python 触发的信号
	player_moved.connect(_on_player_moved)
	z_index = 10
	var camera = $Camera2D
	if camera:
		camera.make_current()
		camera.position_smoothing_enabled = true
	
func get_status():
	"""返回玩家状态"""
	return {
		"id": id,
		"position": {"x": position.x, "y": position.y},
		"velocity": {"x": velocity.x, "y": velocity.y}
	}


func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false

func move_to_random_position():
	"""移动到地图上的随机位置"""
	var tilemap = get_node("/root/main/TileMapLayer")
	if not tilemap:
		print("找不到 TileMapLayer")
		return
	
	# 获取随机目标位置(世界坐标)
	var target_grid = tilemap.get_random_walkable_position()
	var current_grid = tilemap.local_to_map(global_position)
	
	# 计算路径(使用网格坐标)
	target_path = tilemap.get_astar_path(current_grid, target_grid)
	
	if target_path.size() > 0:
		is_moving_to_target = true
		current_path_index = 0
		print("开始移动到网格: ", target_grid, " 路径长度: ", target_path.size())
	else:
		print("无法找到路径")

func move_to_position(pos: Array):
	"""移动到指定网格位置"""
	var x = pos[0]
	var y = pos[1]

	var tilemap = get_node("/root/main/TileMapLayer")
	if not tilemap:
		print("找不到 TileMapLayer")
		return
		
	var target_grid = Vector2i(x, y)
	var current_grid = tilemap.local_to_map(global_position)
	target_path = tilemap.get_astar_path(current_grid, target_grid)
	
	if target_path.size() > 0:
		is_moving_to_target = true
		current_path_index = 0
		print("开始移动到网格: ", target_grid, " 路径长度: ", target_path.size())
	else:
		print("无法找到路径")

func _physics_process(_delta: float) -> void:
	if is_moving_to_target:
		# 自动移动模式
		move_along_path()
	else:
		# 手动控制模式
		manual_control()

func move_along_path():
	"""沿着路径移动"""
	if current_path_index >= target_path.size():
		is_moving_to_target = false
		velocity = Vector2.ZERO
		$AnimatedSprite2D.stop()
		print("到达目标!")
		return
	
	var target = target_path[current_path_index]
	var direction = (target - global_position).normalized()
	var distance = global_position.distance_to(target)
		
	if distance < 5: # 到达当前路径点
		current_path_index += 1
		emit_signal("player_moved", global_position)
	else:
		velocity = direction * path_speed
		$AnimatedSprite2D.play()
		emit_signal("player_moved", global_position)
	move_and_slide()

func manual_control():
	"""手动控制移动"""
	# 获取输入方向
	var input_direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_down"):
		input_direction.y += 1
	if Input.is_action_pressed("move_up"):
		input_direction.y -= 1

	# 设置速度
	if input_direction.length() > 0:
		velocity = input_direction.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.stop()

	move_and_slide()

func _on_body_entered(_body):
	hide()
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true)

func _on_player_moved(new_position: Vector2):
	print("Player moved to: ", new_position)
