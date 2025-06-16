extends Node

var primary_weapon_types: Dictionary
var cycle_positions: Dictionary
var chain_mode: bool = true

@onready var parent = get_node("../")

func _ready():
	update_mapping.call_deferred()

func shoot_primary():
	if chain_mode:
		for type in primary_weapon_types:
			var type_cluster = primary_weapon_types[type]
			var current_weapon = type_cluster.weapons[
				type_cluster.cycle_position
			]
			#breakpoint
			if current_weapon.try_shoot():
				type_cluster.timer.start()
	else:
		for weapon in parent.primary_weapons:
			weapon.try_shoot()
		
func toggle_mode():
	chain_mode = not chain_mode

func update_mapping():
	for child in get_children():
		remove_child(child)
	
	primary_weapon_types = {}
	cycle_positions = {}
	
	for weapon in parent.primary_weapons:
		if weapon.type in primary_weapon_types:
			primary_weapon_types[weapon.type].weapons.append(weapon)
		else:
			primary_weapon_types[weapon.type] = {
				"weapons": [weapon],
				"cycle_position": 0
			}
	
	for type in primary_weapon_types:
		var weapon_count = len(primary_weapon_types[type].weapons)
		var timer = Timer.new()
		timer.one_shot = true
		timer.autostart = false
		var cooldown =  Data.weapons[type].reload * Util.TIME_FACTOR
		timer.wait_time = cooldown / weapon_count
		timer.timeout.connect(
			func cycle_weapon():
				primary_weapon_types[type].cycle_position = (primary_weapon_types[type].cycle_position + 1) % weapon_count
		)
		
		add_child(timer)
		primary_weapon_types[type].timer = timer
