extends Node2D

var radar_scale = 2
var player = null

# TODO: Don't hardcode this
@onready var radar_offset = Vector2(119, 119)

@onready var radar_rotate = PI + Util.flatten_25d(Client.system().camera().global_transform.origin).angle()

var DISPOSITION_COLORS = {
		Util.DISPOSITION.HOSTILE: Color(1.0,0,0),
		Util.DISPOSITION.NEUTRAL: Color(1.0, 1.0, 0),
		Util.DISPOSITION.ABANDONED: Color(0.5, 0.5, 0.5),
		Util.DISPOSITION.FRIENDLY: Color(0.0,1.0,0.0),
}

func _ready():
	Client.player_ent_updated.connect(func _on_player_ent_updated(new_player):
		player = new_player
	)

func _relative_position(subject: Node3D, player_position: Vector2) -> Vector2:
	var relative_position: Vector2 = (Util.flatten_25d(subject.global_transform.origin) - player_position) * radar_scale
	relative_position = relative_position.rotated(radar_rotate)
	return relative_position.limit_length((radar_offset.x - 5))
	
func _process(_delta):
	queue_redraw()

func _get_color(node: Node):
	# TODO: if IFF decoder type upgrade is installed
	var color = DISPOSITION_COLORS[Util.DISPOSITION.NEUTRAL]#Client.get_disposition(node)]
	return color
	#if Client.target_ship != node:
	#	return color
	#else:
	#	return ((0.1 * sin(Time.get_ticks_msec() / 200.0)) + 0.9) * color

func _get_contact_size(node: Node):
	if "radar_size" in node:
		return node.radar_size
	return 2

func _draw():
	if is_instance_valid(player) and player.is_inside_tree():
		var player_position = Util.flatten_25d(player.global_transform.origin)
		for spob_blip in get_tree().get_nodes_in_group("radar-spobs"):
			draw_circle(_relative_position(spob_blip, player_position), 5, _get_color(spob_blip))
		for blip in get_tree().get_nodes_in_group("radar"):
			#draw_circle(_relative_position(blip, player_position), size, _get_color(blip))
			draw_circle(_relative_position(blip, player_position), _get_contact_size(blip), _get_color(blip))
