extends Node

class_name Universe

func _ready():
	for peer in [Server, Client]:
		peer.universe_loaded.emit.call_deferred()
