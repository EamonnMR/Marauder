extends Resource
class_name WeaponData

enum GUIDANCE_TYPE {
	FIXED,
	TURRET,
	PDC,
	FRONT_QUADRANT,
	GUIDED,
	MINE
}

@export var id: String
@export var speed: int
@export var projectile_scene: PackedScene
@export var graphics: PackedScene
@export var spread: float = 0
@export var mass_damage: int
@export var energy_damage: int
@export var splash_mass_damage: int
@export var splash_energy_damage: int
@export var splash_radius: int
@export var ignore_shields: bool
@export var explosion: PackedScene
@export var fade: bool
@export var impact: int
@export var reload: int
@export var decay: int
@export var lifetime: int
@export var guidance_type: GUIDANCE_TYPE
@export var translucent: bool
@export var guided_turn_rate: int
@export var projectile_health: int

func damage() -> Health.DamageVal:
	return Health.DamageVal.new(mass_damage, energy_damage, ignore_shields)
	
func splash_damage() -> Health.DamageVal:
	return Health.DamageVal.new(splash_mass_damage, splash_energy_damage, ignore_shields)

func is_turreted():
	match guidance_type:
		GUIDANCE_TYPE.TURRET, GUIDANCE_TYPE.FRONT_QUADRANT, GUIDANCE_TYPE.PDC:
			return true
	return false
func effective_range():
	# TODO: calculate decay to 50%
	return (Util.TIME_FACTOR * lifetime) * (Util.SPEED_FACTOR * speed)

func lead_position(position: Vector2, target_position: Vector2, target_velocity: Vector2):
	var travel_time = (target_position - position).length() / (Util.SPEED_FACTOR * speed)
	var lead_position = target_velocity * travel_time + target_position
	return lead_position
