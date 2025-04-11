extends Node

var ships = {}

func _ready():
	print("Loading Ships")
	process_dir("res://data/ship_data", func load_ship(path):
		var ship_data: ShipData = load(path)
		ships[ship_data.id] = ship_data
	)

func process_dir(path, function: Callable):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			function.call(path.path_join(file_name))
			file_name = dir.get_next()
