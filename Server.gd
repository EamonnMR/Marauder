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
	var error = peer.create_server(Util.PORT)
	if error:
		print(error)
	get_tree().get_root().multiplayer.multiplayer_peer = peer
	
	DisplayServer.window_set_title("Marauder - Server")
	
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
	player_ent.name = "player_ship" + str(player_id)
	player_ent.transform.origin = U25d.raise(Vector2(randf_range(-5,5), randf_range(-5,5)))
	universe().get_node("System").add_child(player_ent)
	# Sync
	var player_state = player_ent.marshal_spawn_state()
	for player in players:
		Client.spawn_ship.rpc_id(player, player_state)

func time() -> float:
	return Util.system_time()

func get_sender() -> int:
	var rid = multiplayer.get_remote_sender_id()
	if rid == 0:
		return 1
	return rid
