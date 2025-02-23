extends Control


func _on_start_pressed():
	Server.init_local($VBoxContainer/Alias.text)
	Client.init_local($VBoxContainer/Alias.text)
	get_tree().change_scene_to_file("res://Universe.tscn")


func _on_cancel_pressed():
	get_tree().change_scene_to_file("res://menu/MainMenu.tscn")
