extends Node

@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	
func system() -> StarSystem:
	# Client only cares about one system - the one the player is in
	return get_tree().get_root().get_node("Universe/System")


func init(host: String, alias: String):
	var error = peer.create_client(host, Util.PORT)
	if error:
		print(error)
		breakpoint
	get_tree().get_root().multiplayer.multiplayer_peer = peer
	get_tree().get_root().multiplayer.connected_to_server.connect(func _on_connected():
		Server.client_handshake(alias)
	)

@rpc("reliable", "any_peer")
func server_handshake(players, state):
	print("Server Handshake", players)
	system().unmarshall_network_state(state)
