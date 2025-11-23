extends Node

"""
Godot RPC 客户端 - 只提供方法调用功能
极简设计，自动连接到 Python RPC 服务器
"""

var ws_client: WebSocketPeer
var connected: bool = false
var registered_instances: Dictionary = {} # {id: instance}

func _ready():
	print("[GodotRPC] 初始化")
	connect_to_server()

func _process(_delta):
	if ws_client:
		ws_client.poll()
		
		var state = ws_client.get_ready_state()
		
		if state == WebSocketPeer.STATE_OPEN:
			if not connected:
				connected = true
				print("[GodotRPC] 已连接到服务器")
				send_ready()
			
			# 接收消息
			while ws_client.get_available_packet_count() > 0:
				var packet = ws_client.get_packet()
				var message = packet.get_string_from_utf8()
				handle_message(message)
		
		elif state == WebSocketPeer.STATE_CLOSED:
			if connected:
				connected = false
				print("[GodotRPC] 连接断开，5秒后重连...")
				await get_tree().create_timer(5.0).timeout
				connect_to_server()

func connect_to_server():
	"""连接到服务器"""
	ws_client = WebSocketPeer.new()
	var err = ws_client.connect_to_url("ws://localhost:8765")
	if err != OK:
		print("[GodotRPC] 连接失败: ", err)

func send_ready():
	"""发送就绪信号"""
	send_message({
		"type": "godot_ready"
	})

func send_message(data: Dictionary):
	"""发送消息"""
	if ws_client and ws_client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var json_string = JSON.stringify(data)
		ws_client.send_text(json_string)

func handle_message(message: String):
	"""处理接收到的消息"""
	var json = JSON.new()
	var parse_result = json.parse(message)
	
	if parse_result != OK:
		print("[GodotRPC] JSON 解析错误")
		return
	
	var data = json.data
	var msg_type = data.get("type")
	
	match msg_type:
		"ready_ack":
			print("[GodotRPC] 服务器确认连接")
		
		"call_method":
			# 调用方法
			var call_id = data.get("call_id")
			var instance_id = data.get("instance_id")
			var method_name = data.get("method_name")
			var args = data.get("args", [])
			
			var result = call_instance_method(instance_id, method_name, args)
			
			# 返回结果
			send_message({
				"type": "method_result",
				"call_id": call_id,
				"instance_id": instance_id,
				"method_name": method_name,
				"success": result.success,
				"result": result.value,
				"error": result.error
			})

func register_instance(id: String, instance: Node):
	"""注册实例"""
	registered_instances[id] = instance
	print("[GodotRPC] 注册实例: ", id)

func get_instance(id: String) -> Node:
	"""获取注册的实例"""
	if id in registered_instances:
		return registered_instances[id]
	return null

func call_instance_method(instance_id: String, method_name: String, args: Array) -> Dictionary:
	"""调用实例方法"""
	if instance_id not in registered_instances:
		return {
			"success": false,
			"error": "实例不存在: " + instance_id,
			"value": null
		}
	
	var instance = registered_instances[instance_id]
	
	if not instance.has_method(method_name):
		return {
			"success": false,
			"error": "方法不存在: " + method_name,
			"value": null
		}
	
	# 调用方法
	var result
	if args.size() == 0:
		result = instance.call(method_name)
	else:
		result = instance.callv(method_name, args)
	
	print("[GodotRPC] ", instance_id, ".", method_name, "(", args, ") -> ", result)
	
	return {
		"success": true,
		"error": null,
		"value": result
	}
