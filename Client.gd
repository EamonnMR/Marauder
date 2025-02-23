extends Node

@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
signal universe_loaded

func system() -> StarSystem:
	# Client only cares about one system - the one the player is in
	return get_tree().get_root().get_node("Universe/System")


func init(host: String, alias: String):
	print("Client init")
	var error = peer.create_client(host, Util.PORT)
	if error:
		print(error)
		breakpoint
	get_tree().get_root().multiplayer.multiplayer_peer = peer
	#get_tree().get_root().set_multiplayer_authority(0)
	get_tree().get_root().multiplayer.connected_to_server.connect(func _on_connected():
		var mpe = get_multiplayer_authority()
		Server.client_handshake.rpc(alias)
	)
	
	DisplayServer.window_set_title("Marauder - Client") 

func init_local(alias: String):
	universe_loaded.connect(func handshake_closure():
		Server.client_handshake(alias)
	)

	
@rpc("reliable", "authority")
func server_handshake(players, state):
	print("Server Handshake", players)
	system().unmarshal_network_state(state)

@rpc("reliable", "authority")
func spawn_ship(state: Dictionary):
	system().spawn_entity(state)

var latency = 0.1

var _time: float

func time() -> float:
	return _time

func time_update() -> float:
	_time = Util.system_time() - latency
	return _time
