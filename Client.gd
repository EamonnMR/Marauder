extends Node

@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func init(host: String, alias: String):
	peer.create_client(host, Util.PORT)
	multiplayer.peer = peer
	multiplayer.connected_to_server.connect(func _on_connected():
		Server.client_handshake(alias)
	)

@rpc
func server_handshake(players):
	print("Server Handshake", players)
