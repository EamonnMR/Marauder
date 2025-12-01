extends Node

var ships = {}
var weapons = {}
var factions = {}

func _ready():
	print("Loading Factions")
	process_dir("res://data/faction_data", func load_faction(path):
		var faction_data: FactionData = load(path)
		factions[faction_data.id] = faction_data
	)
	
	print("Loading Weapons")
	process_dir("res://data/weapon_data", func load_weapon(path):
		var weapon_data: WeaponData = load(path)
		weapons[weapon_data.id] = weapon_data
	)

	print("Loading Ships")
	process_dir("res://data/ship_data", func load_ship(path):
		var ship_data: ShipData = load(path)
		assert(ship_data.id != "")
		
		# Verify weapon config
		
		var graphics_inst = ship_data.graphics.instantiate()
		for weapon_slot in ship_data.weapon_config:
			assert(graphics_inst.has_node(weapon_slot))
			var weapon_id = ship_data.weapon_config[weapon_slot]
			assert(weapon_id in weapons)
		
		ship_data.faction_data = factions[ship_data.faction]
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
