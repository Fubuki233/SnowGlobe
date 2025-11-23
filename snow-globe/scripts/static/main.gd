extends Node

var python_server_pid: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_python_server()

func start_python_server() -> void:
	var script_path = "scripts/static/godot_rpc_server.py"
	var full_path = ProjectSettings.globalize_path("res://" + script_path)
	
	print("启动 Python RPC 服务器...")
	var args = [full_path]
	python_server_pid = OS.create_process("python", args)
	
	if python_server_pid > 0:
		print("Python 服务器已启动 (PID: ", python_server_pid, ")")
	else:
		push_error("Python 服务器启动失败")

# 停止 Python 服务器
func stop_python_server() -> void:
	if python_server_pid > 0:
		OS.kill(python_server_pid)
		print("Python 服务器已停止")
		python_server_pid = 0

# 游戏退出时清理
func _exit_tree() -> void:
	stop_python_server()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
