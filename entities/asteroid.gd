extends StaticBody3D

var group: String

func _ready():
	add_to_group(group)
	add_to_group("cover")

	# add_to_group("radar")

func marshal_spawn_state() -> Dictionary:
	return {
		"name": name,
		"origin": global_transform.origin,
		"group": group,
		"#path": get_scene_file_path(),
	}

func unmarshal_spawn_state(state):
	name = state.name
	transform.origin = state.origin
	group = state.group
