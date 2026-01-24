extends Node

const GRID_SIZE = 2048

const HALF_SQUARE = Vector2(GRID_SIZE/2, GRID_SIZE/2)

const MIN_PER_SECTOR = 10

const MAX_PER_SECTOR = 20

var active_sectors: Array[Vector2i]

func offset(sector: Vector2i) -> Vector2:
	return Vector2(sector * GRID_SIZE)
	
func get_sector(position: Vector2) -> Vector2i:
	return Vector2i((position + HALF_SQUARE) / GRID_SIZE)
	
func sector_group(sector: Vector2i) -> String:
	return "asteroids-" + str(sector.x) + "-" + str(sector.y)

func fill_grid_section(sector) -> Array[Vector2]:
	var sector_offset = offset(sector)
	var points: Array[Vector2] = []
	for i in randi_range(MIN_PER_SECTOR, MAX_PER_SECTOR):
		points.append(sector_offset + Vector2(randi_range(0,GRID_SIZE), randi_range(0,GRID_SIZE)))

	return points
	
func adjacent_sectors(sector: Vector2i) -> Array[Vector2i]:
	var sectors: Array[Vector2i] = []
	for i in range(-1, 2):
		for j in range(-1, 2):
			sectors.append(Vector2i(sector.x + i, sector.y + j))
	return sectors

func difference(lval: Array[Vector2i], rval: Array[Vector2i] ) -> Array[Vector2i]:
	var diff: Array[Vector2i] = []
	
	for sector in lval:
		if sector not in rval:
			diff.append(sector)
	
	return diff

func _physics_process(delta):
	var new_active_sectors: Array[Vector2i] = []

	for player in Server.players.values():
		if not is_instance_valid(player.player_entity):
			continue
		var sector = get_sector(U25d.flatten(player.player_entity.global_position))
		
		var adjacent = adjacent_sectors(sector)
		new_active_sectors += difference(adjacent, new_active_sectors)
	
	var net_new_sectors = difference(new_active_sectors, active_sectors)
	var retired_sectors = difference(active_sectors, new_active_sectors)

	for sector in net_new_sectors:
		for point in fill_grid_section(sector):
			Server.spawn_asteroid(point, sector_group(sector))
		
	for sector in retired_sectors:
		for asteroid in get_tree().get_nodes_in_group(sector_group(sector)):
			Server.despawn_asteroid(asteroid)
	
	active_sectors = new_active_sectors
	
	
