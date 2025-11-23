extends Node3D

class_name WeaponSlot

@export var turret: bool
@export var type: String
@export var loaded_data: WeaponData
#@onready var parent: Spaceship = get_node("../../")
var parent: Spaceship


var weapon_graphic: Node3D
var turret_graphic: Node3D
var weapon: Node3D
var pdc_target = null
var in_range = false
# var turn = PI*2

func _ready():
	parent = get_node("../../")

func _physics_process(delta):
	if loaded_data and loaded_data.guidance_type == WeaponData.GUIDANCE_TYPE.PDC:
		_acquire_pdc_target()
		if _has_pdc_target() and in_range:
			weapon.try_shoot_bp()


func _process(delta):
	if loaded_data and loaded_data.is_turreted():
		match loaded_data.guidance_type:
			WeaponData.GUIDANCE_TYPE.TURRET:
				_process_turret_aim()
			WeaponData.GUIDANCE_TYPE.FRONT_QUADRANT:
				_process_front_quadrant_aim()
			WeaponData.GUIDANCE_TYPE.PDC:
				_process_pdc_aim()

func _process_turret_aim():
	if is_instance_valid(parent.target):
		var aimpoint = parent.get_target_lead_weapon(weapon.data)
		_aim_turret_at_point(aimpoint)
	else:
		_zero_turret_aim()

func _process_front_quadrant_aim():
	if is_instance_valid(parent.target) and target_quadrant() == Util.QUADRANT.FRONT:
		var aimpoint = U25d.flatten(parent.target.global_position)
	else:
		_zero_turret_aim()
		
func _zero_turret_aim():
	$Turret.rotation.y = 0
	$Turret/Pivot.rotation.z = 0
	
func _aim_turret_at_point(aimpoint):
	var aim = $EulerAimHelper.get_euler_aim(aimpoint)
	$Turret.rotation.y = aim.y + PI/2
	$Turret/Pivot.rotation.x = aim.x
		
func _process_pdc_aim():
	if not _has_pdc_target():
		_zero_turret_aim()
		in_range = false
		return
	var aimpoint = U25d.flatten(pdc_target.global_position)
	var aim_distance = U25d.flatten(global_position).distance_to(aimpoint)
	var effective_range = weapon.data.effective_range()
	if aim_distance > effective_range * 2:
		_zero_turret_aim()
		in_range = false
		return
	_aim_turret_at_point(aimpoint)
	
	if aim_distance < effective_range:
		in_range = true
	else:
		in_range = false


func remove_weapon():
	for element in [
		weapon, weapon_graphic, turret_graphic#, $Controller
	]:
		if is_instance_valid(element):
			element.queue_free()
	type = ""
	loaded_data = null

func add_weapon(type: String):
	self.type = type
	loaded_data = Data.weapons[type]
	parent = get_node("../../")
	weapon = preload("res://components/Weapon.tscn").instantiate()
	weapon.type = type
	weapon.parent = parent
	weapon_graphic = loaded_data.graphics.instantiate()
	if loaded_data.is_turreted():
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

func _acquire_pdc_target():
	# TODO: Maintain a list of hostile NPCs.
	var candidate_targets = get_tree().get_nodes_in_group(Util.PDC_TARGET_GROUP)
	if not candidate_targets:
		return false
	var targets = _filter_pdc_targets(candidate_targets)
	if len(targets) == 0:
		pdc_target = null
		return false
	pdc_target = Util.closest(
		targets,
		Util.flatten_25d(parent.global_transform.origin)
	)
	return true

func _has_pdc_target():
	return pdc_target and is_instance_valid(pdc_target)

func _filter_pdc_targets(candidate_targets):
	# Filter objects targeting the parent
	var targets = []
	for target in candidate_targets:
		if "target" in target and target.target == parent:
			targets.append(target)
	# TODO
	#if not targets: # Try any valid target
		#for target in candidate_targets:
			#if weapon.iff.should_exclude(target):
				#continue
			#targets.append(target)
				
	return targets
