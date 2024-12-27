extends Node

@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var players = {}

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
	# maybe don't set this 
	#players[sender].entity = 
	spawn_player(sender) # TODO: Player options
	print(players)
	Client.rpc_id(sender, "server_handshake", players, system().marshall_network_state())
	print("RPC Sent")

func spawn_player(player_id):
	var player_ent = preload("res://entities/ships/Warship.tscn").instantiate()
	player_ent.player_owner = player_id
	universe().get_node("System").add_child(player_ent)
	return player_ent
