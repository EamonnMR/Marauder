extends Node3D

@export var faction: String
@onready var faction_data: FactionData = Data.factions[faction]

var possible_ships = []

func _ready():
	if not Util.is_server():
		$timer.queue_free()
		
	for ship_id in Data.ships:
		var ship_data = Data.ships[ship_id]
		if ship_data.faction == faction:
			possible_ships.push_back(ship_id)

func _on_timer_timeout():
	if Util.is_server():
		var system: StarSystem = get_node("../")
		var npc_count = len(get_tree().get_nodes_in_group("npcs"))
		if npc_count <= system.max_npcs:
			Server.spawn_npc(self.select_ship_to_spawn())

func select_ship_to_spawn() -> String:
	return Util.random_select(possible_ships)
