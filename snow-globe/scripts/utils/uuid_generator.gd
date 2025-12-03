class_name UUIDGenerator
extends RefCounted


static func generate_uuid() -> String:
	randomize()
	
	var uuid = ""
	for i in range(36):
		if i == 8 or i == 13 or i == 18 or i == 23:
			uuid += "-"
		elif i == 14:
			uuid += "4"
		elif i == 19:
			uuid += ["8", "9", "a", "b"][randi() % 4]
		else:
			uuid += "0123456789abcdef"[randi() % 16]
	
	return uuid

static func generate_short_id() -> String:
	randomize()
	var chars = "0123456789abcdefghijklmnopqrstuvwxyz"
	var id = ""
	for i in range(16):
		id += chars[randi() % chars.length()]
	return id

static func generate_numeric_id() -> String:
	randomize()
	return str(randi() % 999999 + 100000)

static func generate_timestamp_id() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 10000
	return "%d_%04d" % [timestamp, random_suffix]
