extends Node

@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
signal universe_loaded

var playing = false

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
	playing = true 

func init_local(alias: String):
	universe_loaded.connect(func handshake_closure():
		Server.client_handshake(alias)
	)
	playing = true

	
@rpc("reliable", "authority")
func server_handshake(players, state, appointed_time):
	print("Server Handshake", players)
	system().unmarshal_network_state(state)
	delay_until(appointed_time)
	#system().show()

@rpc("reliable", "authority")
func spawn_ship(state: Dictionary):
	system().spawn_entity(state)
	#if state.player_owner == multiplayer.get_unique_id():
	#	breakpoint

@rpc("reliable", "authority")
func vanish_ship(player_id, appointed_time):
	delay_until(appointed_time)
	print("Player left: ", player_id)
	var ship_name = Server.player_ship_name(player_id)
	var ship = system().get_node(ship_name)
	if ship:
		system().remove_child(ship)

# var latency = - 0.1
var latency = 0.1

var _time: float

func time() -> float:
	return _time

func time_update() -> float:
	_time = Util.system_time() - latency
	return _time

func delay_until(appointed_time):
	# https://godotengine.org/qa/1660/execute-a-function-after-a-time-delay
	var delay = appointed_time - time()
	if delay > 0:
		var before = Util.system_time()
		await get_tree().create_timer(delay).timeout
		var actual_delay = Util.system_time()- before
		print("Actual Delay: ", actual_delay)
	else:
		print("Arrived late!")
