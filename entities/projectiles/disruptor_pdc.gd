extends Projectile

func _on_area_3d_body_entered(body):
	if body == owner:
		return
	if is_instance_valid(body) and not _should_exclude_impact(body):
		if Util.is_server():
			Health.do_damage(body, get_falloff_damage(damage), owner())
			if data.impact > 0 and body.has_method("receive_impact"):
				body.receive_impact(linear_velocity.normalized() * data.impact)
		detonate()
		queue_free()
