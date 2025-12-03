extends Node

@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var server_started: bool = false
var online = false
var npc_counter = 0
signal universe_loaded

func universe() -> Universe:
	return get_tree().get_root().get_node("Universe")
	
func system() -> StarSystem:
	# TODO: Accept which system
	return universe().get_node("System")
	

class PlayerRecord:
	var id: int
	var alias: String
	var ship_pref: String
	var player_entity: Spaceship
	var faction_status: Dictionary[String, float]
	
	func _init(id, alias, ship_pref):
		self.id = id
		self.alias = alias
		self.ship_pref = ship_pref
		self.faction_status = {}
		for faction in Data.factions:
			faction_status[faction] = Data.factions[faction].initial_disposition

var players: Dictionary[int, PlayerRecord] = {}

func init():
	print("Server init")

	DisplayServer.window_set_title("Marauder - Server")
	
	var error = peer.create_server(Util.PORT)
	if error:
		print(error)
		
	peer.peer_connected.connect(func peer_connected(peer_id):
		print("Peer Connected: ", peer_id, ", awaiting handshake")
	)
	
	peer.peer_disconnected.connect(peer_disconnected)
	
	get_tree().get_root().multiplayer.multiplayer_peer = peer
	
	server_started = true
	online = true
	# universe().system().show()

func init_local():
	print("Server init local")
	DisplayServer.window_set_title("Marauder - Local")
	
	server_started = true
	#universe().system().show()
	
@rpc("reliable", "any_peer", "call_remote")
func client_handshake(alias: String, ship_pref: String):
	var sender = get_sender()
	print("Client Handshake from: ", sender)
	
	if not ship_pref in Data.ships:
		print("Invalid Ship: ", ship_pref)
		ship_pref = "shuttle"
	players[sender] = PlayerRecord.new(sender, alias, ship_pref)
	# maybe don't set this 
	#players[sender].entity = 
	print(players)
	var net_state = system().marshal_network_state()
	Client.server_handshake.rpc_id(sender, players, net_state, time())
	spawn_player(sender) # TODO: Player options
	print("RPC Sent")

func spawn_player(player_id: int):
	var player_ent = preload("res://entities/Ship.tscn").instantiate()
	player_ent.type = players[player_id].ship_pref
	player_ent.player_owner = player_id
	player_ent.name = player_ship_name(player_id)
	player_ent.faction = "pirate"
	player_ent.transform.origin = U25d.raise(Vector2(randf_range(-5,5), randf_range(-5,5)))
	universe().get_node("System").add_child(player_ent)
	players[player_id].player_entity = player_ent
	# Sync
	var player_state = player_ent.marshal_spawn_state()
	for player in get_rpc_player_ids():
		Client.spawn_ship.rpc_id(player, player_state)
		
func spawn_npc():
	var npc_ent = preload("res://entities/Ship.tscn").instantiate()
	var possible_ships = Data.ships.keys()
	npc_ent.type = Util.random_select(Data.ships.keys())
	
	#npc_ent.type = "cruiser"
	npc_ent.name = "npc_" + str(npc_counter)
	npc_counter += 1
	npc_ent.transform.origin = U25d.raise(Vector2(randf_range(-5000,5000), randf_range(-5000,5000)))
	universe().get_node("System").add_child(npc_ent)
	# Sync
	var state = npc_ent.marshal_spawn_state()
	for player in get_rpc_player_ids():
		Client.spawn_ship.rpc_id(player, state)

func time() -> float:
	return Util.system_time()

func get_sender() -> int:
	var rid = multiplayer.get_remote_sender_id()
	if rid == 0:
		return 1
	return rid

func get_sender_data() -> PlayerRecord:
	return players[get_sender()]
	
func peer_disconnected(peer_id):
	if players[peer_id]:
		var removed_player = players[peer_id]
		print("Player Disconnected: ", removed_player.alias, " (", removed_player.id, ")")
		players.erase(peer_id)
		var player_ship_name = player_ship_name(peer_id)
		var ship = universe().get_node("System").get_node(player_ship_name)
		universe().get_node("System").remove_child(ship)
		var appointed_time = time()
		for player in get_rpc_player_ids():
			Client.vanish_ship.rpc_id(player, peer_id, appointed_time)
	else:
		print("Unknown Player disconnected: ", peer_id)

func player_ship_name(player_id):
	return "player_ship" + str(player_id)

func get_rpc_player_ids():
	var keys = Server.players.keys()
	keys.erase(1)
	return keys

@rpc("reliable", "any_peer", "call_remote")
func update_player_target_ship(target):
	var sender: PlayerRecord = get_sender_data()
	var target_ent = get_node(target)

	if target_ent is Spaceship and is_instance_valid(sender.player_entity):
		sender.player_entity.server_set_target(target_ent)
