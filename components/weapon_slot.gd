extends Node3D

class_name WeaponSlot

@export var turret: bool
@export var type: WeaponData
#@onready var parent: Spaceship = get_node("../../")
var parent: Spaceship


var weapon_graphic: Node3D
var turret_graphic: Node3D
var weapon: Node3D

var turn = PI*2

func _ready():
	parent = get_node("../../")
	
func _process(delta):
	if type.is_turreted():
		if type.guidance_type == WeaponData.GUIDANCE_TYPE.TURRET:
			do_turret_aim()
		elif type.guidance_type == WeaponData.GUIDANCE_TYPE.FRONT_QUADRANT:
			do_front_quadrant_aim()

func do_turret_aim():
	if is_instance_valid(parent.target):
		var aimpoint = U25d.flatten(parent.target.global_position)
		var aim = $EulerAimHelper.get_euler_aim(aimpoint)
		$Turret.rotation.y = aim.y + PI/2
		$Turret/Pivot.rotation.x = aim.x
	else:
		$Turret.rotation.y = 0 #deg_to_rad(90)
		$Turret/Pivot.rotation.z = 0# deg_to_rad(90)

func do_front_quadrant_aim():
	if is_instance_valid(parent.target) and target_quadrant() == Util.QUADRANT.FRONT:
		var aimpoint = U25d.flatten(parent.target.global_position)
		var aim = $EulerAimHelper.get_euler_aim(aimpoint)
		$Turret.rotation.y = aim.y + PI/2
		$Turret/Pivot.rotation.x = aim.x
	else:
		$Turret.rotation.y = 0
		$Turret/Pivot.rotation.z = 0
	
func remove_weapon():
	for element in [
		weapon, weapon_graphic, turret_graphic#, $Controller
	]:
		if is_instance_valid(element):
			element.queue_free()
	type = null

func add_weapon(data: WeaponData):
	type = data
	parent = get_node("../../")
	weapon = preload("res://components/Weapon.tscn").instantiate()
	weapon.parent = parent
	weapon_graphic = data.graphics.instantiate()
	if type.is_turreted():
		#var controller = preload("res://components/TurretController.tscn").instantiate()
		#add_child(controller)
		#controller.name = "Controller"
		turret_graphic = weapon_graphic.get_node("Turret")
		weapon_graphic.remove_child(turret_graphic)
		$Turret/Pivot.add_child(weapon)
		$Turret/Pivot.add_child(weapon_graphic)
		$Turret.add_child(turret_graphic)
	else:
		add_child(weapon)
		add_child(weapon_graphic)
	parent.add_weapon(weapon)

func get_weapon():
	return get_children()[0]
	
func has_weapon():
	return len(get_children()) == 1

func target_quadrant() -> Util.QUADRANT:
	# WARNING: Only call this if the target is valid
	return Util.relative_quadrant(
		Util.flatten_25d(global_position),
		Util.flatten_rotation(parent),
		Util.flatten_25d(parent.target.position)
	)
