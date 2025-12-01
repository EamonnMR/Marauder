extends Resource
class_name ShipData

@export var id: String
@export var max_speed: int = 300
@export var accel: int = 300
@export var turn: int = 45
@export var name: String = ""
@export var make: String = ""
@export var graphics: PackedScene
@export var max_shields: int = 10
@export var max_health: int = 10
@export var mass: int = 10
@export var weapon_config: Dictionary[String, String]
@export var pdc_can_target: bool
@export var faction: String = ""
var faction_data

func display_name():
	return " ".join([make, name])
