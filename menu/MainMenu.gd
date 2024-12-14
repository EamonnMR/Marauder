extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_singleplayer_pressed():
	get_tree().change_scene_to_file("res://Universe.tscn")

func _on_host_pressed():
	get_tree().change_scene_to_file("res://menu/HostMenu.tscn")

func _on_join_pressed():
	get_tree().change_scene_to_file("res://menu/JoinMenu.tscn")

func _on_quit_pressed():
	get_tree().quit()
