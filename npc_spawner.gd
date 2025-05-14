extends Node

func _ready():
	if not Util.is_server():
		queue_free()

func _on_timer_timeout():
	var system: StarSystem = get_node("../")
	var npc_count = len(get_tree().get_nodes_in_group("npcs"))
	if npc_count <= system.max_npcs:
		Server.spawn_npc()
