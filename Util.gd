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

func raise_25d(two_d_vec: Vector2) -> Vector3:
	return Vector3(two_d_vec.x, 0, two_d_vec.y)

func flatten_25d(three_d_vec: Vector3) -> Vector2:
	return Vector2(three_d_vec.x, three_d_vec.z)
	
func flatten_rotation(object: Node3D) -> float:
	return object.global_transform.basis.get_rotation_quaternion().get_euler().y
