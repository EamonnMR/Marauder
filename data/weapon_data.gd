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
@export var guidance_type: GUIDANCE_TYPE

func damage() -> Health.DamageVal:
	return Health.DamageVal.new(mass_damage, energy_damage, ignore_shields)
	
func splash_damage() -> Health.DamageVal:
	return Health.DamageVal.new(splash_mass_damage, splash_energy_damage, ignore_shields)

func is_turreted():
	return guidance_type == GUIDANCE_TYPE.TURRET or guidance_type == GUIDANCE_TYPE.FRONT_QUADRANT
