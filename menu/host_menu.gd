extends Control

func _on_cancel_pressed():
	get_tree().change_scene_to_file("res://menu/MainMenu.tscn")

func _on_start_pressed():
	# TODO: Start Server
	get_tree().change_scene_to_file("res://Universe.tscn")
