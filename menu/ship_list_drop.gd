extends OptionButton

var ids = []

func _ready():
	for ship_type: ShipData in Data.ships.values():
		add_item(ship_type.display_name())
		ids.append(ship_type.id)

func get_id(index):
	if index == -1:
		return null
	return ids[index]

func get_selection():
	return get_id(selected)
