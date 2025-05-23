extends CharacterBody3D

class_name Spaceship

var faction = "terran"
var type: String

var skin: String
@onready var parent: StarSystem = get_node("../")

var player_owner: int

var max_speed = 100
var accel = 0.01
var turn = 1
var max_bank = deg_to_rad(15)
var bank_speed = 2.5 / turn
var engagement_range: float = 0
var standoff: bool = false
var mass: float
@export var bank_factor = 1
@export var bank_axis = "x"

var screen_box_side_length: int

var chain_fire_mode = true
var lock_turrets = false

var linear_velocity = Vector2(0,0)
var primary_weapons = []
var secondary_weapons = []

var warping = false
var warping_in = false
var warp_speed_factor = 10

signal destroyed
signal weapons_changed

func _ready():
	#if not Data.ships[type]["screen_box_side_length"]:
	#	Data.ships[type]["screen_box_side_length"] = get_screen_box_side_length()
	# Data.ships[type].apply_to_node(self)
	# TODO: Better way to determine if it's the player
	add_to_group("radar")
	add_to_group("ships")
	
	$WeaponSlot.add_weapon(preload("res://components/Weapon.tscn").instantiate())
	
	if player_owner:
		var player_id = multiplayer.get_unique_id()
		faction = "player_owned"
		if player_owner == multiplayer.get_unique_id():
			$CameraFollower.remote_path = Client.system().camera_offset().get_path()
			#$CameraFollower.remote_path = Client.camera.get_node("../").get_path()
			#Client.ui_inventory.assign($Inventory, "Your inventory")

		add_to_group("players")
		ready_player_controller()
		
	else:
		add_to_group("npcs")
		add_to_group("faction-" + str(faction))
		ready_npc_controller()
	
	return
	#if self == Client.player:
		## add_child(preload("res://component/InteractionRange.tscn").instantiate())
		#if skin != "":
			#$Graphics.set_skin_data(Data.skins[skin])
	#else:
		#input_event.connect(_on_input_event_npc)
		#$Graphics.set_skin_data(Data.skins[Data.factions[faction].skin])
		#var weapon_config = Data.ships[type].weapon_config
		#for weapon_slot in weapon_config:
			#pass
			##get_node(weapon_slot).add_weapon(WeaponData.instantiate(weapon_config[weapon_slot]))
		#
	##
#func get_weapon_slots() -> Array[WeaponSlot]:
	#return []
	##var weapon_slots: Array[WeaponSlot] = []
	##for weapon_slot in get_children():
	##	if weapon_slot is WeaponSlot:
	##		weapon_slots.push_back(weapon_slot)
	##return weapon_slots

func _physics_process(delta):
	var previous_rotation = rotation.y
	if Util.is_server():
		linear_velocity = get_limited_velocity_with_thrust(delta)
		var rotation_impulse = $Controller.rotation_impulse * delta * turn
		rotation.y += rotation_impulse
		
		# warning-ignore:return_value_discarded
		set_velocity(U25d.raise(linear_velocity))
		move_and_slide()
		handle_shooting()
		#if not warping:
			#if warping_in:
				#if Util.out_of_system_radius(self, Util.PLAY_AREA_RADIUS / 2):
					#warping_in = false
			#else:
				#Util.wrap_to_play_radius(self)
	else:
		do_lerp_update()
	
	
	var rotation_diff = 0
	if previous_rotation != rotation.y:
		rotation_diff = rotation.y - previous_rotation
		if rotation_diff <= -PI:
			rotation_diff += 2 * PI

		if rotation_diff >= PI:
			rotation_diff -=  2 * PI

		increase_bank(rotation_diff)
	else:
		decrease_bank(delta)
	

func handle_shooting():
	if $Controller.shooting:
		$WeaponSlot/Weapon.try_shoot()
		#if chain_fire_mode:
			#$ChainFireManager.shoot_primary()
		#else:
			#for weapon in primary_weapons:
				#weapon.try_shoot()
#
	#if $Controller.shooting_secondary:
		#for weapon in secondary_weapons:
			#weapon.try_shoot()

func get_limited_velocity_with_thrust(delta):
	if $Controller.thrusting:
		linear_velocity += Vector2(accel * delta * 100, 0).rotated(-rotation.y)
		$Graphics.thrusting = true
	else:
		$Graphics.thrusting = false
	if $Controller.braking:
		linear_velocity = Vector2(linear_velocity.length() - (accel * delta * 100), 0).rotated(linear_velocity.angle())
	
	if not warping:
		if linear_velocity.length() > max_speed:
			return Vector2(max_speed, 0).rotated(linear_velocity.angle())
		else:
			return linear_velocity
	else:
		if linear_velocity.length() > max_speed * warp_speed_factor:
			return Vector2(max_speed * warp_speed_factor, 0).rotated(linear_velocity.angle())
		else:
			return linear_velocity
func flash_weapon():
	$Graphics.flash_weapon()

func increase_bank(rotation_impulse):
	$Graphics.rotation[bank_axis] += rotation_impulse * bank_speed * bank_factor
	$Graphics.rotation[bank_axis] = clamp(
		$Graphics.rotation[bank_axis],
		-max_bank,
		max_bank
	)

func decrease_bank(delta):
	if $Graphics.rotation[bank_axis] != 0.0:
		var sgn = sign($Graphics.rotation[bank_axis]) * bank_factor
		$Graphics.rotation[bank_axis] -= sgn * bank_speed * delta * bank_factor
		if sign($Graphics.rotation[bank_axis]) != sgn:
			$Graphics.rotation[bank_axis] = 0
	
func _on_health_destroyed():
	if Util.is_server():
		for player in Server.get_rpc_player_ids():
			ship_destroyed.rpc_id(player)
	ship_destroyed()

@rpc("reliable", "authority")
func ship_destroyed():
	call_deferred("queue_free")
	emit_signal("destroyed")

func _on_input_event_npc(_camera, event, _click_position, _camera_normal, _shape):
	#https://stackoverflow.com/questions/58628154/detecting-click-touchscreen-input-on-a-3d-object-inside-godot
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		Client.update_player_target_ship(self)
	else:
		Client.mouseover_entered(self)

func serialize_player():
	return {
		"type": type,
		"skin": skin,
		"health": $Health.serialize(),
		"equipment": $Equipment.serialize(),
		"inventory": $Inventory.serialize()
	}

func deserialize_player(data: Dictionary):
	type = data.type
	skin = data.skin
	$Health.deserialize(data.health)
	$Equipment.deserialize(data.equipment)
	$Inventory.deserialize(data.inventory)

func add_weapon(weapon: Node):
	if weapon.primary:
		primary_weapons.push_back(weapon)
	else:
		secondary_weapons.push_back(weapon)
		
	weapons_changed.emit()
func remove_weapon(weapon: Node):
	if weapon.primary:
		primary_weapons.erase(weapon) 
	else:
		secondary_weapons.erase(weapon)
	weapons_changed.emit()
				
func receive_impact(impact: Vector2):
	linear_velocity += impact / mass

#func screen_box_side_length():
	#var mesh = $Graphics.mesh
	#var aabb = mesh.get_aabb()
	#var trns: Transform3D
	##var factor = $Graphics.transform.basis.get_scale().x
	#var max_dim = max(aabb.size.x, aabb.size.y, aabb.size.z) # * factor
	#var camera_scale = Client.camera.size
	#var reference_dim = 10.0
	#var re_scale = camera_scale * reference_dim * max_dim
	#return re_scale

func marshal_spawn_state() -> Dictionary:
	return {
		"name": name,
		"origin": transform.origin,
		"#path": get_scene_file_path(),
		"player_owner": player_owner,
		"health": $Health.marshal_spawn_state()
	}

func unmarshal_spawn_state(state):
	name = state.name
	transform.origin = state.origin
	player_owner = state.player_owner
	$Health.unmarshal_spawn_state(state.health)
	
func marshal_frame_state() -> Dictionary:
	return {
		"origin": Util.flatten_25d(transform.origin),
		"rotation": rotation.y
	}.merged(
		$Health.marshal_frame_state()
	)
	
func ready_player_controller():
	add_child(preload("res://components/control/KeyboardController.tscn").instantiate())

func ready_npc_controller():
	add_child(preload("res://components/control/AIController.tscn").instantiate())

func do_lerp_update():
	var lerp_helper = StarSystem.LerpHelper.new(self, parent)
	if lerp_helper.can_lerp:
		transform.origin = Util.raise_25d(lerp_helper.calc_vector("origin"))
		rotation.y = lerp_helper.calc_angle("rotation")
		$Health.health = lerp_helper.calc_numeric("health")
		$Health.shields = lerp_helper.calc_numeric("shields")
