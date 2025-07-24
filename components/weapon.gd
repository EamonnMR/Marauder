extends Node3D

class_name Weapon

var cooldown: bool = false
var burst_cooldown: bool = false
var burst_counter: int = 0

var projectile

var iff: IffProfile

@export var type: String
@onready var data: WeaponData = Data.weapons[type]

var parent: Spaceship

@onready var spread_max = deg_to_rad(data.spread * 0.5)
@onready var spread_min = -1 * spread_max
var emerge_point: Node3D

@export var burst_count = 0
@export var dupe_count = 1
@export var world_projectile: bool = true  # Disable for beams or other things that should follow the player
@export var vary_pitch = 0
@export var ammo_item: String
@export var primary = true
@export var projectile_velocity: float

# @export var dmg_factor: float = 1

@export var timeout: float
@export var explode_on_timeout: bool
@export var damage_falloff: bool
@export var fade: bool
@export var overpen: bool
@export var impact: float
@export var beam_length: int
@export var recoil: int



#@onready var damage: Health.DamageVal
#@onready var splash_damage: Health.DamageVal

func _ready():
	$Cooldown.wait_time = data.reload * Util.TIME_FACTOR
	#if data.front_quadrant_turret:
		##add_child(preload("res://components/FrontQuadTurret.tscn"))
		#var graphics = $Graphics
		#$FrontQuadTurret.add_weapon(graphics)
		#emerge_point = $FrontQuadTurret
	#else:
	emerge_point = self#$Graphics#/EmergePoint
	#Data.weapons[type].apply_to_node(self)
#
	#damage = Health.DamageVal.new(
		#mass_damage,
		#energy_damage,
		#false
	#)

	#splash_damage = Health.DamageVal.new(
		#splash_mass_damage,
		#splash_energy_damage,
		#false
	#)
	#

	iff = IffProfile.new(
		parent,
		parent.faction,
		true
	)

func try_shoot():
	if Util.is_server():
		if not cooldown and not burst_cooldown:
			if _try_consume_ammo():
				# TODO: Consume ammo
				_shoot()
				return true
		return false

func _shoot():
	if burst_count:
		burst_counter += 1
		if burst_counter >= burst_count:
			burst_cooldown = true
			$BurstCooldown.start()
	#for i in range(dupe_count):
	var projectile = _create_projectile()
	var projectile_data: Dictionary = projectile.marshal_spawn_state()
	for player in Server.get_rpc_player_ids():
		shoot_remote.rpc_id(player, Server.time(), projectile_data)
	
	cooldown = true
	$Cooldown.start()
#	if Client.is_playing:
	_effects()


@rpc("reliable", "authority")
func shoot_remote(appointed_time: float, state: Dictionary):
	Client.delay_until(appointed_time)
	cooldown = true
	$Cooldown.start()
	var new_projectile = Client.system().spawn_entity(state)
	new_projectile.iff = iff
	_effects()
	
func _create_projectile():
	var new_projectile = false
	var recycle_projectile = not world_projectile # TODO: make optional, it would be neat
	if world_projectile or (recycle_projectile and not is_instance_valid(projectile)):
		projectile = data.projectile_scene.instantiate()
		new_projectile = true
	# projectile.init()
	#projectile.damage *= dmg_factor
	#projectile.splash_damage *= dmg_factor
	# TODO: Also scale splash damage
	
	projectile.scale = Vector3(1,1,1)
	#projectile.damage = damage
	#
	## TODO: Really, weapon wants to be the API and projectile wants to pull from it.
	#if "overpen" in projectile:
		#projectile.overpen = overpen
	#if "splash_damage" in projectile:
		#projectile.splash_damage = splash_damage
		#projectile.splash_radius = splash_radius
	projectile.rotate_y(randf_range(spread_min, spread_max))
	
	# TODO: This seems like a similar direction issue to warp-in
	#if recoil and new_projectile and world_projectile:
	#	parent.receive_impact(Vector2(recoil, 0).rotated(Util.flatten_rotation(self)))

	
	projectile.iff = iff
	projectile.type = type
	#if "recoil" in projectile:
		#projectile.recoil = recoil
	#if "explode_on_timeout" in projectile:
		#projectile.explode_on_timeout = explode_on_timeout
		#projectile.damage_falloff = damage_falloff
		#projectile.fade = fade
	#if "beam_length" in projectile:
		#projectile.beam_length = beam_length
	#projectile.impact = impact
	#if not new_projectile:
		#projectile.do_beam.call_deferred(global_transform.origin, [iff.owner])
	#
	if new_projectile and world_projectile:
		projectile.global_transform = emerge_point.global_transform
		# TODO: Reset projectile scale
		var deflect = randf_range(spread_min, spread_max)
		var deflect_deg = rad_to_deg(PI)
		projectile.initial_rotation = deflect
		projectile.initial_velocity = parent.linear_velocity

		Client.system().add_child(projectile)
		#projectile.rotate_y(deflect)
		projectile.scale = Vector3(1,1,1)
		projectile.initial_rotation = deflect

	else:
		get_node("../").add_child(projectile)
	return projectile

func _effects():
	#$Emerge/MuzzleFlash.restart()
	#$Emerge/MuzzleFlash.emitting = true
	$AudioStreamPlayer3D.play()
	#parent.flash_weapon()

func _on_BurstCooldown_timeout():
	burst_cooldown = false
	burst_counter = 0
	
func _try_consume_ammo():
	if ammo_item == "":
		return true
	return parent.get_node("Inventory").deduct_ingredients({ammo_item: 1})


func _on_cooldown_timeout():
	cooldown = false
