extends Control


func _on_join_pressed():
	Client.init($VBoxContainer/HostName.text, $VBoxContainer/Alias.text)
	get_tree().change_scene_to_file("res://Universe.tscn")


func _on_cancel_pressed():
	get_tree().change_scene_to_file("res://menu/MainMenu.tscn")
