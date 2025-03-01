extends Node

@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var players = {}
var server_started: bool = false
var online = false
signal universe_loaded

func universe() -> Universe:
	return get_tree().get_root().get_node("Universe")
	
func system() -> StarSystem:
	# TODO: Accept which system
	return universe().get_node("System")
	

class PlayerRecord:
	var id: int
	var alias: String
	
	func _init(id, alias):
		self.id = id
		self.alias = alias
	

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

func init_local(alias):
	print("Server init local")
	DisplayServer.window_set_title("Marauder - Local")
	
	server_started = true
	
@rpc("reliable", "any_peer", "call_remote")
func client_handshake(alias):
	var sender = get_sender()
	print("Client Handshake from: ", sender)
	
	players[sender] = PlayerRecord.new(sender, alias)
	# maybe don't set this 
	#players[sender].entity = 
	print(players)
	Client.server_handshake.rpc_id(sender, players, system().marshal_network_state())
	
	spawn_player(sender) # TODO: Player options
	print("RPC Sent")

func spawn_player(player_id: int):
	var player_ent = preload("res://entities/ships/Warship.tscn").instantiate()
	player_ent.player_owner = player_id
	player_ent.name = player_ship_name(player_id)
	player_ent.transform.origin = U25d.raise(Vector2(randf_range(-5,5), randf_range(-5,5)))
	universe().get_node("System").add_child(player_ent)
	# Sync
	var player_state = player_ent.marshal_spawn_state()
	for player in get_rpc_player_ids():
		Client.spawn_ship.rpc_id(player, player_state)

func time() -> float:
	return Util.system_time()

func get_sender() -> int:
	var rid = multiplayer.get_remote_sender_id()
	if rid == 0:
		return 1
	return rid
	
func peer_disconnected(peer_id):
	if players[peer_id]:
		var removed_player = players[peer_id]
		print("Player Disconnected: ", removed_player.alias, " (", removed_player.id, ")")
		players.erase(peer_id)
		var player_ship_name = player_ship_name(peer_id)
		var ship = universe().get_node("System").get_node(player_ship_name)
		universe().get_node("System").remove_child(ship)
		for player in get_rpc_player_ids():
			Client.vanish_ship.rpc_id(peer_id)
	else:
		print("Unknown Player disconnected: ", peer_id)

func player_ship_name(player_id):
	return "player_ship" + str(player_id)

func get_rpc_player_ids():
	var keys = Server.players.keys()
	keys.erase(1)
	return keys
