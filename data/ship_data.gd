extends Resource
class_name ShipData

@export var id: String
@export var max_speed: int = 300
@export var accel: int = 300
@export var turn: int = 45
@export var name: String = ""
@export var make: String = ""

func display_name():
	return " ".join([make, name])
