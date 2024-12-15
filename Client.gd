extends Node

@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

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
func server_handshake(players):
	print("Server Handshake", players)
	get_tree().quit()
