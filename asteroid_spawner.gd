extends Node

const GRID_SIZE = 100

var active_sectors: Array[Vector2i]

func offset(sector: Vector2i) -> Vector2:
	return Vector2(sector * GRID_SIZE)
	
func get_sector(position: Vector2) -> Vector2i:
	return Vector2i(position / GRID_SIZE)

func fill_grid_section(sector) -> Array[Vector2]:
	var sector_offset = offset(sector)
	var points: Array[Vector2] = []
	for i in range(10):
		for j in range(10):
			points.append(Vector2(i, j) + sector_offset)
	return points
	
func adjacent_sectors(sector: Vector2i) -> Array[Vector2i]:
	var sectors: Array[Vector2i] = []
	for i in range(-1, 1):
		for j in range(-1, 1):
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
		var sector = get_sector(U25d.flatten(player.player_entity.global_position))
		
		var adjacent = adjacent_sectors(sector)
		new_active_sectors += difference(adjacent, new_active_sectors)
				
	var net_new_sectors = difference(new_active_sectors, active_sectors)
	var retired_sectors = difference(active_sectors, new_active_sectors)
	
	# TODO: Rez and derez asteroids on the server side
	
	
