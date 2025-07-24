extends Control


func _on_start_pressed():
	Server.init_local()
	Client.init_local($VBoxContainer/Alias.text, $VBoxContainer/ShipListDrop.get_selection())
	get_tree().change_scene_to_file("res://Universe.tscn")


func _on_cancel_pressed():
	get_tree().change_scene_to_file("res://menu/MainMenu.tscn")
