extends CharacterBody3D

var linear_velocity = Vector2()

@export var type: String
@onready var data: WeaponData = Data.weapons[type]
var iff: IffProfile
@onready var damage: Health.DamageVal = data.damage()
@onready var splash_damage: Health.DamageVal = data.splash_damage()

var explode_on_timeout: bool = true
var impact: float
var material: StandardMaterial3D# = $MeshInstance3D.surface_get_material(0)
var initial_rotation = 0
var initial_emission_energy
var initial_albedo

func _ready():
	rotate_y(initial_rotation)
	linear_velocity += Vector2(data.speed * Util.SPEED_FACTOR, 0).rotated(-rotation.y)
	$Lifetime.wait_time = (Util.TIME_FACTOR * data.decay) / max(data.energy_damage, data.mass_damage)
	if data.fade:
		material = $Graphics.mesh.surface_get_material(0).duplicate(true)
		$Graphics.set_surface_override_material(0, material)
		initial_emission_energy = material.emission_intensity
		initial_albedo = material.albedo_color.a
func _process(delta):
	if data.fade:
		var fade = _fade_factor()
		material.albedo_color.a = initial_albedo * fade
		material.emission_intensity = initial_emission_energy * fade

func _physics_process(_delta):
	set_velocity(Util.raise_25d(linear_velocity))
	move_and_slide()
	#Util.wrap_to_play_radius(self)


func get_falloff_damage(damage) -> Health.DamageVal:
	if data.fade:
		return damage.faded(_fade_factor())
	else:
		return damage

func get_falloff_impact() -> int:
	if data.fade:
		return data.impact * _fade_factor()
	else:
		return data.impact
		
func _fade_factor():
	return $Lifetime.time_left / $Lifetime.wait_time

func _on_Lifetime_timeout():
	if explode_on_timeout:
		detonate()
	queue_free()


func set_lifetime(lifetime: float):
	if lifetime:
		$Timer.wait_time = lifetime

func owner():
	if is_instance_valid(iff.owner):
		return iff.owner
	return null

func detonate():
	if data.explosion:
		pass
		#Explosion.make_explo(explosion, self)
	#if splash_damage:
		#for data in Util.sphere_query(get_world_3d(), global_transform, data.splash_radius, $Area3D.collision_mask, $Sphere/SphereShapeHolder.shape):
			#pass
			#Health.do_damage(data.collider, splash_damage, owner())

func marshal_spawn_state() -> Dictionary:
	return {
		"name": name,
		"origin": global_transform.origin,
		"rotation": Util.flatten_rotation(self),
		"velocity": velocity,
		"#path": get_scene_file_path(),
		"type": type
	}

func unmarshal_spawn_state(state):
	name = state.name
	type = state.type
	transform.origin = state.origin
	velocity = state.velocity
	rotate_y(state.rotation)


func _on_area_3d_body_entered(body):
	if is_instance_valid(body) and not iff.should_exclude(body):
		if Util.is_server():
			Health.do_damage(body, get_falloff_damage(damage), owner())
			if impact > 0 and body.has_method("receive_impact"):
				body.receive_impact(linear_velocity.normalized() * get_falloff_impact())
		detonate()
		queue_free()
