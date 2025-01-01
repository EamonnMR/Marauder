extends Node

class_name StarSystem

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
