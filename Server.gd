extends Node

@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var players = {}

class PlayerRecord:
	var id: int
	var alias: String
	
	func _init(id):
		self.id = id


func init():
	peer.create_server(Util.PORT)
	multiplayer.multiplayer_peer = peer

	multiplayer.peer_connected.connect(func _on_player_connected(peer_id):
		players[peer_id] = PlayerRecord.new(peer_id)
		print("New client connected: ", peer_id)
	)

@rpc("authority", "reliable")
func client_handshake(alias: String):
	var sender = multiplayer.get_remote_sender_id()
	print("Client Handshake from", sender)
	players[multiplayer.get_remote_sender_id()].alias = alias
	print(players)
	Client.rpc_id(sender, "server_handshake", players)
