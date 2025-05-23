extends Controller

# var warp_autopilot = false

#@onready var ui = get_tree().get_root().get_node("Main/UI/")
@onready var is_current_player: bool = decide_if_is_current_player()
@onready var is_remote: bool = decide_if_is_remote()

func get_rotation_impulse() -> int:
	var dc = 0
	if Input.is_action_pressed("turn_left"):
		dc += 1
	if Input.is_action_pressed("turn_right"):
		dc -= 1
	return dc
	
func _ready():
	set_multiplayer_authority(parent.player_owner)

class InputFrame:
	var thrusting: bool
	var braking: bool
	var shooting: bool
	var rotation_impulse: float


@rpc("unreliable", "authority")
func send_input(frame: Dictionary):
	thrusting = frame.thrusting
	braking = frame.braking
	shooting = frame.shooting
	rotation_impulse = frame.rotation_impulse

func _physics_process(delta):
	# I'd love if this could be a fast serialized object instead
	if is_current_player:
		# I'd love if this could be a fast serialized object instead
		var frame: Dictionary
		
		frame.thrusting = Input.is_action_pressed("thrust")
		frame.braking = Input.is_action_pressed("brake")
		frame.shooting = Input.is_action_pressed("shoot")
		frame.rotation_impulse = get_rotation_impulse()
		
		if is_remote:
			send_input.rpc_id(1, frame)
		else:
			send_input(frame) # Intentional non-rpc call

#func _physics_process(delta):
	# if not Client.typing:
		# toggle_pause()
		# toggle_map()
		# toggle_inventory()
		# toggle_codex()
		# toggle_fire_mode()
	
	#if warp_autopilot:
		#process_warping_out(delta)
		#return
		
	#if Client.typing:
	#	return
	
	#thrusting = Input.is_action_pressed("thrust")
	#braking = Input.is_action_pressed("brake")
	# shooting = Input.is_action_pressed("shoot")
	# shooting_secondary = Input.is_action_pressed("shoot_secondary")
	#rotation_impulse = get_rotation_impulse() * delta * parent.turn
	# check_jumped()
	# select_nearest_target()
	# cycle_targets()
	# interact()
	# hyperspace()
	# handle_cheat_modal()
	# handle_zoom()
	# handle_spob_selection()
	
	#
#func toggle_map():
	#if Input.is_action_just_released("toggle_map"):
		#ui.toggle_map()
#
#func toggle_codex():
	#if Input.is_action_just_released("toggle_codex"):
		#ui.toggle_codex()
		#
#func toggle_inventory():
	#if Input.is_action_just_released("toggle_inventory"):
		#ui.toggle_inventory(["Inventory", "Crafting", "Equipment"])
		#
func check_jumped():
	if Input.is_action_just_released("jump"):
		jumping = true

func select_nearest_target():
	if Input.is_action_just_pressed("target_nearest_hostile"):
		var hostile_ships = get_tree().get_nodes_in_group("npcs-hostile")
		if len(hostile_ships) == 0:
			return
		elif len(hostile_ships) == 1:
			Client.update_player_target_ship(hostile_ships[0])
		else:
			Client.update_player_target_ship(Util.closest(
				hostile_ships,
				Util.flatten_25d(parent.global_transform.origin)
			))
		
func cycle_targets():
	if Input.is_action_just_pressed("cycle_targets"):
		var all_ships = get_tree().get_nodes_in_group("npcs")
		var index = all_ships.find(Client.target_ship)
		if all_ships.size():
			var next_index = (index + 1) % all_ships.size()
			Client.update_player_target_ship(all_ships[next_index])

func interact():
	if Input.is_action_just_pressed("interact") and is_instance_valid(Client.player):
		Client.player.get_node("InteractionRange").interact()

func hyperspace():
	if Input.is_action_just_pressed("jump"):
		pass
		#if warp_conditions_met():
			#if Client.selected_system:
				#if is_instance_valid(Client.player):
					#warp_dest_system = Client.selected_system
					#warp_autopilot = true
					#parent.warping = true
			#else:
				#Client.display_message("No system selected - press 'm' and select a destination")
		#else:
			#Client.display_message("Cannot warp to hyperspace - move further from system center\n"
			#+ "(Mass Lock: %s, Your distance: %s" % [Util.JUMP_DISTANCE, Util.flatten_25d(parent.position).length()])

#func complete_jump():
	## warp_autopilot = false
	#if is_instance_valid(parent):
		#parent.get_node("HyperspaceManager").start_hyperjump()

func toggle_pause():
	if Input.is_action_just_pressed("pause"):
		Client.toggle_pause()

func toggle_fire_mode():
	if Input.is_action_just_pressed("toggle_chain_fire"):
		parent.chain_fire_mode = not parent.chain_fire_mode
		Client.display_message("Fire Mode: " + ("chain fire" if parent.chain_fire_mode else "syncro"))

func handle_cheat_modal():
	if Input.is_action_just_pressed("open_cheat_dialogue"):
		var dialogue = Client.get_ui().get_node("CheatInput")
		if not dialogue.visible:
			Client.get_ui().get_node("CheatInput").show()
			Client.get_ui().get_node("CheatInput").grab_focus()

func handle_zoom():
	var ZOOM_FACTOR = 2.0
	if Input.is_action_just_pressed("zoom_in"):
		Client.camera.size /= ZOOM_FACTOR
		Client.camera_updated.emit()
	elif Input.is_action_just_pressed("zoom_out"):
		Client.camera.size *= ZOOM_FACTOR
		Client.camera_updated.emit()
		
func handle_spob_selection():
	var spobs
	for i in range(10):
		if Input.is_action_just_pressed("select_spob_" + str(i + 1)):
			if not spobs:
				spobs = get_tree().get_nodes_in_group("spobs")
			if i >= len(spobs):
				break
			else:
				Client.update_player_target_spob(spobs[i])
			

func get_target():
	return Client.target_ship

func decide_if_is_current_player():
	var uid = multiplayer.get_unique_id()
	var owner = parent.player_owner
	return uid == owner

func decide_if_is_remote():
	var uid = multiplayer.get_unique_id()
	return multiplayer.get_unique_id() != 1
