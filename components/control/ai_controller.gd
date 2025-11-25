extends Controller

class_name AiController

enum STATE_NAME {
	IDLE,
	ATTACK,
	PERSUE,
	PATH,
	LEAVE,
	WARP
}

class AiState:
	var parent: AiController
	func _init(parent: AiController):
		self.parent = parent
		
	func state_name() -> STATE_NAME:
		return STATE_NAME.IDLE

	func process(delta):
		pass
		
	func rethink():
		pass
		
	func enter():
		pass
		
	func leave():
		pass
	
	func respond_to_damage(source):
		pass
		
class Idle extends AiState:
	func state_name() -> STATE_NAME:
		return STATE_NAME.IDLE
		
	func rethink():
		parent._find_target()

	func enter():
		parent.thrusting = false
		parent.shooting = false
		parent.rotation_impulse = 0
		parent.remove_from_group("npcs-hostile")
		#print("New State: Idle")


	
class Attack extends AiState:
	func state_name() -> STATE_NAME:
		return STATE_NAME.ATTACK
	
	func process(delta):
		if not parent._verify_target():
			return
		# var target_2d_pos = parent.target_2d_pos()
		parent.populate_rotation_impulse_and_ideal_face(
			parent.parent.get_target_lead(),
			delta
		)
		parent.last_nav_tick = Time.get_ticks_msec()
		#parent.nav_target(delta)

		# TODO: Shoot weapons independently based on margin and range
		parent.shooting = true #_facing_within_margin(shoot_margin)
		parent.thrusting = not parent.parent.standoff and parent._facing_within_margin(parent.accel_margin)
		parent.braking = parent.parent.standoff
	
	func rethink():
		parent.persue_if_out_of_range()


class Persue extends AiState:
	func state_name() -> STATE_NAME:
		return STATE_NAME.PERSUE
		
	func process(delta):
		if not parent._verify_target():
			return
		#parent.populate_rotation_impulse_and_ideal_face(
			#parent.parent.get_target_lead(),
			#delta
		#)
		parent.nav_target(delta)
		parent.shooting = false
		#print("Rotation Impulse: ", rotation_impulse)
		parent.thrusting = parent._facing_within_margin(parent.accel_margin)
		parent.braking = false
	
	func rethink():
		parent.attack_if_in_range()
			
	func enter():
		if parent.attack_if_in_range():
			return
			
		#if target == Client.player:
			#parent.add_to_group("npcs-hostile")
		#else:
			#parent.remove_from_group("npcs-hostile")
		print("New State: Persue")
	
class Path extends AiState:
	func state_name() -> STATE_NAME:
		return STATE_NAME.PATH
	
	func process(delta):
		parent._verify_path_target()
		parent.nav_target( delta)
		parent.shooting = false
		parent.thrusting = parent._facing_within_margin(parent.accel_margin)
		parent.braking = false

class Warp extends AiState:
	func state_name() -> STATE_NAME:
		return STATE_NAME.WARP
	func rethink():
		if parent.warp_conditions_met():
			pass
			#state = STATES.WARP

class Leave extends AiState:
	func state_name() -> STATE_NAME:
		return STATE_NAME.LEAVE

@export var accel_margin = PI / 4
@export var shoot_margin = PI * 1
@export var max_target_distance = 1000
@export var destination_margin = 100
var last_nav_tick

var path_target
var lead_velocity: float
var states: Array[AiState] = [
	Idle.new(self),
	Attack.new(self),
	Persue.new(self),
	Path.new(self)
]
@onready var state = states[0]
var state_map: Dictionary[STATE_NAME, AiState] = {}

var cache_lead_position

#var unvisited_spobs: Array

# @onready var faction: FactionData = Data.factions[get_node("../").faction]

func complete_warp():
	parent.queue_free()

func _ready():
	for a_state in states:
		state_map[a_state.state_name()] = a_state

	#if get_tree().debug_collisions_hint:
		#$Label.show()
	#var shape = $EngagementRange/CollisionShape3D.shape
	#shape = shape.duplicate(true)
	#shape.radius = parent.engagement_range
	#$EngagementRange/CollisionShape3D.shape = shape
	#get_node("../Health").damaged.connect(_on_damage_taken)
	#_compute_weapon_velocity.call_deferred()
	#unvisited_spobs = get_tree().get_nodes_in_group("spobs")

func change_state(new_state: STATE_NAME):
	state.leave()
	state = state_map[new_state]
	state.enter()
	
func persue_target(target):
	parent.target = target
	parent.server_set_target(parent.target)
	change_state(STATE_NAME.ATTACK)

	
func attack_if_in_range():
	if _check_range(parent.target):
		change_state(STATE_NAME.ATTACK)
		return true
	
	return false

func persue_if_out_of_range():
	if not _verify_target():
		return
	if not _check_range(parent.target):
		change_state(STATE_NAME.PERSUE)
		return true
	
	return false


func nav_target(delta):
	populate_rotation_impulse_and_ideal_face(
		Util.flatten_25d(parent.target.global_position),
		delta
	)
	last_nav_tick = Time.get_ticks_msec()
	
func set_idle():
	parent.server_set_target(null)
	change_state(STATE_NAME.IDLE)


func _verify_target():
	var target = parent.target
	if target == null or not is_instance_valid(parent.target):
		#print("No parent.target", parent.target)
		set_idle()
		return false
	return true
	
func _verify_path_target():
	if path_target == null or not is_instance_valid(path_target):
		#print("No target", target)
		set_idle()
		return false
	return true

func _physics_process(delta):
	if get_tree().debug_collisions_hint:
		pass
		#$LeadIndicator.hide()
		#$Label.text = STATES.keys()[state] + "\n"
	#	+ "My faction: " + Data.factions[parent.faction].name + "\n" \
	#	+ str(target) + " (" + Data.factions[target.faction].name + ")" if is_instance_valid(target) else "" + "\n"
	
	state.process(delta)
	
#func process_state_leave(delta):
	#
	#populate_rotation_impulse_and_ideal_face(
		#Procgen.systems[warp_dest_system].position * 10000,
		#delta
	#)
	#shooting = false # Take shots of opportunity
	#thrusting = _facing_within_margin(accel_margin)
	#braking = false

func _find_target():
	var players = get_tree().get_nodes_in_group("players")
	if len(players):
		persue_target(
			Util.closest(players, Util.flatten_25d(parent.global_transform.origin))
		)
	#var enemy_ships = [Client.player] if faction.hostile_to_player() and is_instance_valid(Client.player) else []
	#for faction_id in faction.get_enemies():
		#enemy_ships += get_tree().get_nodes_in_group("faction-" + str(faction_id))
#
	#if enemy_ships.size() == 0:
		#_find_spob()
	#elif enemy_ships.size() == 1:
		#change_state_persue(enemy_ships[0])
	#else:
		#change_state_persue(Util.closest(enemy_ships, Util.flatten_25d(parent.global_transform.origin)))
		#
	var player_ships = []
	#for player: in Server.players.values():
		#if player.s
#func _find_spob():
	#if unvisited_spobs.size() == 0:
		#change_state_leave()
	#else:
		#var rng  = RandomNumberGenerator.new()
		#rng.randomize()
		#var picked_spob = Procgen.random_select(unvisited_spobs, rng)
		#unvisited_spobs.erase(picked_spob)
		#change_state_path(picked_spob)

func _on_rethink_timeout(): 
	state.rethink()
	
#func change_state_path(path_target):
	#self.path_target = path_target
	#state = STATES.PATH
	#parent.remove_from_group("npcs-hostile")

#func change_state_leave():
	#state = STATES.LEAVE
	#var rng  = RandomNumberGenerator.new()
	#rng.randomize()
	#warp_dest_system = Procgen.random_select(Procgen.systems[Client.current_system].links_cache, rng)

func complete_jump():
	parent.queue_free()

func _compute_weapon_velocity():
	lead_velocity = 12 # TODO: actually compute this from weapons

func _get_target_lead_position(lead_velocity, target):
	var lead_position = super(lead_velocity, target)
	#if get_tree().debug_collisions_hint:
		#$LeadIndicator.global_transform.origin = Util.raise_25d(lead_position)
		#$LeadIndicator.show()
	#	pass
	return lead_position

func _on_damage_taken(source):
	state.respond_to_damage(source)

func get_target():
	return parent.target

func _distance_to(target: Node3D) -> float:
	return (Util.flatten_25d(target.global_transform.origin) -  Util.flatten_25d(global_transform.origin)).length()

func _check_range(target: Node3D):
	if parent.effective_range and _distance_to(target) < parent.effective_range:
		return true
	return false

func display_state():
	if Util.is_server() or Util.is_local():
		var state_name = state.state_name()
		var state_name_txt = STATE_NAME.keys()[state_name]
		
		var rot_imp_txt = "rotation impulse: " + str(rotation_impulse)
		var ideal_face_txt = "ideal face: " + (str(deg_to_rad(ideal_face)) if ideal_face != null else "Nil")
		var last_nav_tick_txt = "Last Nav Tick: " + str(last_nav_tick)
		return "\n".join([state_name_txt, rot_imp_txt, ideal_face_txt, last_nav_tick_txt])
	else:
		return "Not A Server"
