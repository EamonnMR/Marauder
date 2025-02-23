extends Node

var PORT = 2600

func system_time() -> float:
	return Time.get_unix_time_from_system()
	#return Time.get_unix_time_from_datetime_string(Time.get_time_string_from_system())
#
func is_client():
	return multiplayer.get_unique_id() > 1
#
func is_server():
	return multiplayer.get_unique_id() == 1

func is_local():
	return is_server()
#
#func is_headless():
	## TODO: How to determine this?
	#return false
