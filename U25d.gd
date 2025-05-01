extends Node

func raise(two_d_vec: Vector2) -> Vector3:
	return Vector3(two_d_vec.x, 0, two_d_vec.y)
	
func raise_to_level(two_d_vec: Vector2, three_vec: Vector3) -> Vector3:
	return Vector3(two_d_vec.x, three_vec.y, two_d_vec.y)

func flatten(three_d_vec: Vector3) -> Vector2:
	return Vector2(three_d_vec.x, three_d_vec.z)
	
func flatten_rotation(object: Node3D) -> float:
	return object.global_transform.basis.get_rotation_quaternion().get_euler().y

func raise_rotation(rotation: float):
	return Basis(Vector3(0,1,0), rotation)
