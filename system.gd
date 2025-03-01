extends Node

class_name StarSystem

### Join Functions

func marshal_network_state() -> Dictionary:
	var state = {}
	for node in get_children():
		if node.has_method("marshal_spawn_state"):
			state[node.name] = node.marshal_spawn_state()
	return state

func unmarshal_network_state(state: Dictionary):
	for node_id in state:
		spawn_entity(state[node_id])

func spawn_entity(state: Dictionary):
	var entity = load(state["#path"]).instantiate()
	entity.unmarshal_spawn_state(state)
	add_child(entity)
	
### Frame Functions

# TODO: Do this with a timer
func _physics_process(delta):
	if Util.is_server():
		dispatch_net_frame()
	else:
		prune_net_frames()
	

func dispatch_net_frame():
	var net_frame = marshal_frame_state()
	var server_time = Server.time()
	for player in get_player_ids():
		if player < 10:
			breakpoint
		receive_net_frame.rpc_id(player, server_time, net_frame)


var net_frames = []
	
class NetFrame:
	var time: float
	var state: Dictionary

	func _init(time: float, state: Dictionary):
		self.time = time
		self.state = state


func marshal_frame_state():
	var state = {}
	for node in get_children():
		if node.has_method("marshal_frame_state"):
			state[node.name] = node.marshal_frame_state()
	return state

func prune_net_frames():
	# Assumption: net frames are already sorted
	var time = Client.time_update()
	while len(net_frames) > 2:  # Don't prune us down to nothing, even if the frames are outdated
		if net_frames[1].time < time:  # We want one and only one net frame to be in the past
			net_frames.pop_front()
		else:
			break

@rpc("unreliable")
func receive_net_frame(time: float, state: Dictionary):
	if len(net_frames) == 0 or time > net_frames[-1].time:
		net_frames.append(NetFrame.new(time, state))

func get_net_frame(entity_name, offset):
	if len(net_frames) >= offset + 1:
		var frame = net_frames[offset]
		var state = frame.state
		var result = state.get(entity_name)
		if result:
			return NetFrame.new(frame.time, result)
		return null
	else:
		return null

func get_player_ids():
	# TODO: only players in-system
	return Server.get_rpc_player_ids()


class LerpHelper:
	# Calculates lerp/extrapolation results
	var entity: Node
	var time: float
	var past: NetFrame
	var future: NetFrame
	var lerp_factor: float
	var extrapolation_factor: float
	var can_lerp: bool
	var can_extrapolate: bool

	func _init(entity: Node, system: StarSystem):
		self.entity = entity
		self.past = system.get_net_frame(entity.name, 0)
		self.future = system.get_net_frame(entity.name, 1)
		self.time = Client.time()
		
		if (not future) or (not past):
			# At least two frames are required for lerping
			can_lerp = false
			can_extrapolate = false

		elif future.time > time: # Interpolate
			var frames = system.net_frames
			var time_range = future.time - past.time
			var time_offset = time - past.time
			lerp_factor = float(time_offset) / float(time_range)
			can_lerp = true
			can_extrapolate = false

		else: # Extrapolate
			# Future is in the past - extrapolate by dead reckoning
			extrapolation_factor = float(time - past.time) / float(future.time - past.time) - 1.00
			can_lerp = false
			can_extrapolate = true
		
	func calc_numeric(member: String): # No type hint because it's variable output
		if can_lerp:
			return lerp(past.state[member], future.state[member], lerp_factor)
		elif can_extrapolate:
			var known_delta = future.state[member] - past.state[member]
			return future.state[member] + (known_delta * extrapolation_factor)
		elif past:
			return past.state[member]
		else:
			return 0
			
	func calc_angle(member: String) -> float:
		if can_lerp:
			return lerp_angle(
				past.state[member], future.state[member], lerp_factor
			)
		elif can_extrapolate:
			var known_delta = future.state[member] - past.state[member]
			return fmod(future.state[member] + (known_delta * extrapolation_factor), PI * 2)
		elif past:
			return past.state[member]
		else:
			return 0.0

	func calc_boolean(member: String) -> bool:
		if can_lerp:
			return past.state[member] if lerp_factor < 0.5 else future.state[member]
		elif past:
			return past.state[member]
		else:
			return false
			
	func calc_vector(member: String) -> Vector2:
		if can_lerp:
			return past.state[member].lerp(future.state[member], lerp_factor)
		if can_extrapolate:
			var known_delta = future.state[member] - past.state[member]
			return future.state[member] + (known_delta * extrapolation_factor)
		elif past:
			return past.state[member]
		else:
			return Vector2(0,0)
