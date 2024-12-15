extends Node

@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var players = {}

class PlayerRecord:
	var id: int
	var alias: String
	
	func _init(id, alias):
		self.id = id
		self.alias = alias


func init():
	var error = peer.create_server(Util.PORT)
	if error:
		print(error)
		breakpoint
	get_tree().get_root().multiplayer.multiplayer_peer = peer

@rpc("authority", "reliable", "call_remote")
func client_handshake(alias: String):
	var sender = multiplayer.get_remote_sender_id()
	print("Client Handshake from", sender)
	
	players[sender] = PlayerRecord.new(sender, alias)
	print(players)
	Client.rpc_id(sender, "server_handshake", players)
	print("RPC Sent")
