extends GuidedProjectile

var misdirected: bool

func project_beam() -> Dictionary:
	var collision_mask = 0b100000
	var spaceState :PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	return spaceState.intersect_ray(PhysicsRayQueryParameters3D.create(
		global_position, target.global_position, collision_mask, []
	))

func do_server_update(delta):
	if not misdirected and is_instance_valid(target):
		var collider = project_beam()
		if collider:
			target = collider
			misdirected = true
	super.do_server_update(delta)
