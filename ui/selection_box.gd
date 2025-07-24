extends NinePatchRect

var initial_position

func _ready():
	pass
	#sset_radius(10000)

func set_disposition(new_disposition: Util.DISPOSITION):
	#texture = textures[new_disposition]
	modulate = Util.DISPOSITION_COLORS[new_disposition]

func set_radius(size: int):
	custom_minimum_size.x = size
	custom_minimum_size.y = size
	position = -1 * custom_minimum_size / 2
