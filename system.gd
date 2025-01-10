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
	return Server.players.keys()
