extends Node

@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	
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

@rpc("reliable", "authority")
func server_handshake(players, state):
	print("Server Handshake", players)
	system().unmarshal_network_state(state)

@rpc("reliable", "authority")
func spawn_ship(state: Dictionary):
	system().spawn_entity(state)
