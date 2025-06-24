extends Controller

enum STATES {
	IDLE,
	ATTACK,
	PERSUE,
	PATH,
	#LEAVE,
	#WARP
}

@export var accel_margin = PI / 4
@export var shoot_margin = PI * 1
@export var max_target_distance = 1000
@export var destination_margin = 100

var path_target
var lead_velocity: float
var state = STATES.IDLE
var cache_lead_position

#
#var unvisited_spobs: Array

# @onready var faction: FactionData = Data.factions[get_node("../").faction]

func complete_warp():
	parent.queue_free()

func _ready():
	pass
	#if get_tree().debug_collisions_hint:
		#$Label.show()
	#var shape = $EngagementRange/CollisionShape3D.shape
	#shape = shape.duplicate(true)
	#shape.radius = parent.engagement_range
	#$EngagementRange/CollisionShape3D.shape = shape
	#get_node("../Health").damaged.connect(_on_damage_taken)
	#_compute_weapon_velocity.call_deferred()
	#unvisited_spobs = get_tree().get_nodes_in_group("spobs")
	

func _verify_target():
	if parent.target == null or not is_instance_valid(parent.target):
		#print("No parent.target", parent.target)
		change_state_idle()
		return false
	return true
	
func _verify_path_target():
	if path_target == null or not is_instance_valid(path_target):
		#print("No target", target)
		change_state_idle()
		return false
	return true

func _physics_process(delta):
	if get_tree().debug_collisions_hint:
		pass
		#$LeadIndicator.hide()
		#$Label.text = STATES.keys()[state] + "\n"
	#	+ "My faction: " + Data.factions[parent.faction].name + "\n" \
	#	+ str(target) + " (" + Data.factions[target.faction].name + ")" if is_instance_valid(target) else "" + "\n"
	match state:
		STATES.IDLE:
			process_state_idle(delta)
		STATES.ATTACK:
			process_state_attack(delta)
		STATES.PERSUE:
			process_state_persue(delta)
		STATES.PATH:
			process_state_path(delta)
		#STATES.LEAVE:
			#process_state_leave(delta)
		#STATES.WARP:
			#process_warping_out(delta)

func process_state_path(delta):
	_verify_path_target()
	populate_rotation_impulse_and_ideal_face(
		Util.flatten_25d(path_target.global_transform.origin),
		delta
	)
	shooting = false
	thrusting = _facing_within_margin(accel_margin)
	braking = false

func process_state_idle(_delta):
	pass

func process_state_attack(delta):
	if not _verify_target():
		return
	
	populate_rotation_impulse_and_ideal_face(
		#_get_target_lead_position(lead_velocity, target),
		Util.flatten_25d(parent.target.global_transform.origin),
		delta
	)
	# TODO: Shoot weapons independently based on margin and range
	shooting = true #_facing_within_margin(shoot_margin)
	thrusting = not parent.standoff and _facing_within_margin(accel_margin)
	braking = parent.standoff

func process_state_persue(delta):
	if not _verify_target():
		return
	populate_rotation_impulse_and_ideal_face(Util.flatten_25d(parent.target.global_transform.origin), delta)
	shooting = false
	#print("Rotation Impulse: ", rotation_impulse)
	thrusting = _facing_within_margin(accel_margin)
	braking = false

	
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
		change_state_persue(Util.closest(players, Util.flatten_25d(parent.global_transform.origin)))
	
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
	match state:
		STATES.IDLE:
			rethink_state_idle()
		STATES.ATTACK:
			rethink_state_attack()
		STATES.PERSUE:
			rethink_state_persue()
		#STATES.PATH:
			#rethink_state_path()
		#STATES.LEAVE:
			#rethink_state_leave()
		#STATES.WARP:
			#pass

func rethink_state_idle():
	_find_target()

func rethink_state_path():
	pass

func rethink_state_persue():
	if _check_range(parent.target):
		change_state_attack()
	
#func rethink_state_leave():
	#if warp_conditions_met():
		#state = STATES.WARP

func rethink_state_attack():
	if not _check_range(parent.target):
		change_state_persue(parent.target)

func change_state_idle():
	state = STATES.IDLE
	parent.server_set_target(null)
	thrusting = false
	shooting = false
	rotation_impulse = 0
	parent.remove_from_group("npcs-hostile")
	#print("New State: Idle")

func change_state_persue(target):
	if _check_range(target):
		change_state_attack()
		return
	state = STATES.PERSUE
	self.parent.server_set_target(target)
	#if target == Client.player:
		#parent.add_to_group("npcs-hostile")
	#else:
		#parent.remove_from_group("npcs-hostile")
	print("New State: Persue")

func change_state_attack():
	state = STATES.ATTACK
	#print("New State: Attack")
	
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
	match state:
		STATES.IDLE, STATES.PERSUE, STATES.PATH:
			change_state_persue(source)

func get_target():
	return parent.target

func _distance_to(target: Node3D) -> float:
	return (Util.flatten_25d(target.global_transform.origin) -  Util.flatten_25d(global_transform.origin)).length()

func _check_range(target: Node3D):
	if _distance_to(target) < parent.effective_range:
		return true
	return false
