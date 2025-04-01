extends Node

func _ready():
	if not Util.is_server():
		queue_free()

func _on_timer_timeout():
	Server.spawn_npc()
