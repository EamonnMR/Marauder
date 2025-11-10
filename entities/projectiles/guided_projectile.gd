extends Projectile

var target

@onready var turn = data.guided_turn_rate * Util.TURN_FACTOR
@onready var parent: StarSystem = get_node("../")

func _physics_process(delta):
	if Util.is_server():
		if is_instance_valid(target):
			var turn = get_frame_turn(delta)
			print("Turn: ", turn)
			rotation.y += turn
			velocity = U25d.raise(Vector2(data.speed * Util.SPEED_FACTOR, 0).rotated(-rotation.y))
		else:
			target = null
		super(delta)
	else:
		do_lerp_update()




func marshal_spawn_state() -> Dictionary:
	var super_state = super()
	super_state["target"] = target.get_path() if target else null
	return super_state

func unmarshal_spawn_state(state):
	super(state)
	target = get_node(state.target) if state.target else null
	
func marshal_frame_state() -> Dictionary:
	return {
		"origin": Util.flatten_25d(transform.origin),
		"rotation": rotation.y
	}
	breakpoint
	#.merged(
	#	$Health.marshal_frame_state()
	#)

func do_lerp_update():
	var lerp_helper = StarSystem.LerpHelper.new(self, parent)
	if lerp_helper.can_lerp:
		transform.origin = Util.raise_25d(lerp_helper.calc_vector("origin"))
		rotation.y = lerp_helper.calc_angle("rotation")
		#$Health.health = lerp_helper.calc_numeric("health")
		#$Health.shields = lerp_helper.calc_numeric("shields")
	else:
		print("Can't lerp")

func server_set_target(new_target: Node3D):
	set_target(new_target)	
	for player in Server.get_rpc_player_ids():
		client_set_target.rpc_id(player, new_target.get_path() if new_target else "", Server.time())


@rpc("reliable", "authority")
func client_set_target(new_target_path, appointed_time):
	Client.delay_until(appointed_time)
	if new_target_path:
		target = get_node(new_target_path)
	else:
		target = null
	set_target(target)
	
func set_target(new_target):
	target = new_target
	#target_updated.emit(target)

func get_frame_turn(delta: float) -> float:
	var at = Util.flatten_25d(target.transform.origin)
	var origin_2d = Util.flatten_25d(global_transform.origin)
	var rot_2d = Util.flatten_rotation(self)
	var max_move = turn * delta
	var impulse = Util.constrained_point(
		origin_2d,
		rot_2d,
		max_move,
		at
	)
	return impulse[0]

func _should_exclude_impact(body):
	return not (body == target)
