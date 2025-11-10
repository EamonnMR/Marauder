extends Node

var PORT = 2600

var LEGACY_FPS = 47.0 # 30?

var SPEED_FACTOR = LEGACY_FPS/100.0 # Meters / second

var ACCEL_FACTOR = 1/1.66 # Meters / second / second

var TURN_FACTOR = deg_to_rad(3) # Radians / second

var TIME_FACTOR = 1/LEGACY_FPS

func anglemod(angle: float) -> float:
	return fmod(angle, PI * 2)

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

func closest(choices, position: Vector2) -> Node3D:
	return distance_ordered(choices, position)[0]
	
func distance_ordered(choices, position: Vector2) -> Array:
	# Warning: side effects
	choices.sort_custom(
		func distance_comparitor(lval: Node3D, rval: Node3D):
			# For sorting other nodes by how close they are
			
			var ldist =  Util.flatten_25d(lval.global_transform.origin).distance_to(position)
			var rdist = Util.flatten_25d(rval.global_transform.origin).distance_to(position)
			return ldist < rdist
	)
	return choices

func constrained_point(source_position: Vector2, current_rotation: float,
		max_turn: float, target_position: Vector2) -> Array:
	# For finding the right direction and amount to turn when your rotation speed is limited
	var ideal_face = (target_position - source_position).angle()
	ideal_face = PI * 2 - ideal_face
	var ideal_turn = get_ideal_turn_for_ideal_face(ideal_face, current_rotation, max_turn)
	return [ideal_turn, ideal_face]
	
func get_ideal_turn_for_ideal_face(ideal_face, current_rotation, max_turn) -> float:
	var ideal_turn = anglemod(ideal_face - current_rotation)
	if(ideal_turn > PI):
		ideal_turn = anglemod(ideal_turn - 2 * PI)

	elif(ideal_turn < -1 * PI):
		ideal_turn = anglemod(ideal_turn + 2 * PI)
	
	max_turn = sign(ideal_turn) * max_turn  # Ideal turn in the right direction
	
	if(abs(ideal_turn) > abs(max_turn)):
		return max_turn
	else:
		return ideal_turn

func lead_correct_position(projectile_velocity: float, origin_position: Vector2, origin_velocity: Vector2, target_velocity: Vector2, target_position: Vector2) -> Vector2:
	# Simplified 'first order' leading via https://www.gamedev.net/tutorials/programming/math-and-physics/leading-the-target-r4223/
	# TODO: This could be better
	var relative_vel = target_velocity - origin_velocity
	var travel_time = target_position.distance_to(origin_position) / projectile_velocity
	return relative_vel * travel_time + target_position

enum DISPOSITION {
	FRIENDLY,
	HOSTILE,
	NEUTRAL,
	ABANDONED
}

var DISPOSITION_COLORS = {
	Util.DISPOSITION.FRIENDLY: Color(0,1,0),
	Util.DISPOSITION.HOSTILE: Color(1,0,0),
	Util.DISPOSITION.NEUTRAL: Color(1,1,0),
	Util.DISPOSITION.ABANDONED: Color(0.5,0.5,0.5)
}

enum QUADRANT {
	FRONT,
	LEFT,
	RIGHT,
	REAR
}


func relative_quadrant(position: Vector2, rotation: float, subject: Vector2):
	var rel_position: Vector2 = subject - position
	rel_position = rel_position.rotated(rotation)
	var angle = anglemod(rel_position.angle() + PI * 2)
	print("rel_position", rel_position, " angle: ", rad_to_deg(angle))
	if angle < deg_to_rad(45):
		print("FRONT")
		return QUADRANT.FRONT
	elif angle < deg_to_rad(135):
		print("RIGHT")
		return QUADRANT.RIGHT
	elif angle < deg_to_rad(225):
		print("REAR")
		return QUADRANT.REAR
	elif angle < deg_to_rad(315):
		print("LEFT")
		return QUADRANT.LEFT
	else:
		print("FRONT")
		return QUADRANT.FRONT


func item_screen_box_side_length(object):
	var scale = Client.system().camera().size / 10 # TODO: Pull from camera
	if not object:
		return 0
	if object.has_method("screen_box_side_length"):
		var sbsl = object.screen_box_side_length()# / scale
		return sbsl
	#elif "screen_box_side_length" in object:
		#return object.screen_box_side_length / scale
	#else:
		#return 300 / scale
	return 0

func random_select(iterable):
	return iterable[randi() % iterable.size()]

func point_defense_can_hit(scene):
	scene.set_collision_layer_value(4, true)
