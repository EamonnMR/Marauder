extends Node

class_name Health

var already_destroyed: bool = false
var shield_regen_cooldown: bool = false
var invulnerable: bool = false

signal damaged(source)
signal healed
signal destroyed

class DamageVal:
	var mass: int
	var energy: int
	#var ionization: int
	#var disruption: int
	# Also: Crew specific damage? Crit chance?
	var ignore_shields: bool
	
	func _init(mass_damage: int, energy_damage: int, ignore_shields: bool):
		self.mass = mass_damage
		self.energy = energy_damage
		self.ignore_shields = ignore_shields
		
	func diminished(mass_damage, energy_damage):
		return DamageVal.new(
			min(mass - mass_damage, 1),
			min(energy - energy_damage, 1),
			ignore_shields
		)

		
		
		self.mass -= mass_damage
		self.energy -= energy_damage
		self.mass = max(self.mass, 1)
		self.energy = max(self.energy, 1)

	func calc_fade(damage: int, factor: float) -> int:
		if damage > 1:
			return roundi((damage - 1) * factor) + 1
		else:
			return 0
	
	func faded(factor):
		return DamageVal.new(
			calc_fade(mass, factor),
			calc_fade(energy, factor),
			ignore_shields
		)

@export var max_health: int = 1
@export var health: int = -1
@export var max_shields: int = 10
@export var shields: int = -1
@export var shield_regen: float = 1
@export var shield_regen_delay: float = 5



func _ready():
	set_max_health(max_health, max_shields)
	set_shield_regen(shield_regen, shield_regen_delay)
	
	if Util.is_server():
		$ShieldRegen.timeout.connect(_on_shield_regen_timeout)
		$RegenDelay.timeout.connect(_on_regen_delay_timeout)
		$ShieldRegen.start()
		$RegenDelay.start()
	
func set_max_health(max_h, max_s):
	var old_max = max_health
	max_health = max_h
	if health == -1 or health == old_max:
		health = max_health
	max_shields = max_s
	old_max = max_shields
	if shields == -1 or shields == old_max:
		shields = max_shields
		
func set_shield_regen(n_shield_regen, n_shield_regen_delay):
	shield_regen = n_shield_regen
	shield_regen_delay = n_shield_regen_delay
	$ShieldRegen.wait_time = shield_regen
	$RegenDelay.wait_time = shield_regen_delay
  
func heal(amount):
	if can_heal():
		health += amount
	if health >= max_health:
		health = max_health
		emit_signal("healed")

func can_heal():
	return health < max_health

func take_damage(damage: DamageVal, source):
	
	if invulnerable:
		return
	
	var mass_damage = damage.mass
	if not damage.ignore_shields:
		if damage.energy > 0:
			reset_shield_regen()
		
			if shields > 0:
				if damage.energy > 0:
					if shields < damage.energy:
						mass_damage = get_fractional_mass_damage(damage)
						shields = 0
					else:
						shields -= damage.energy
						if shields > 0:
							emit_signal("damaged", source)
							return
	if shields > 0:
		return
	health -= mass_damage

	if health <= 0 and not already_destroyed:
		already_destroyed = true
		emit_signal("destroyed")
	else:
		emit_signal("damaged", source)

func get_fractional_mass_damage(damage: DamageVal):
		var remainder = shields - damage.energy
		var remainder_fraction = damage.energy / remainder
		return round(damage.mass * (damage.energy / shields - damage.energy) )

func serialize():
	return {
		"health": health
	}
	
func deserialize(data):
	health = data.health

static func do_damage(entity: Node, damage: DamageVal, source: Node):
	if entity.has_node("Health"):
		entity.get_node("Health").take_damage(damage, source)

func reset_shield_regen():
	shield_regen_cooldown = true
	$ShieldRegen.start()
	$RegenDelay.start()

func _on_regen_delay_timeout():
	shield_regen_cooldown = false

func _on_shield_regen_timeout():
	if shields < max_shields and not shield_regen_cooldown:
		shields += 1

func marshal_spawn_state() -> Dictionary:
	return {
		"max_health": max_health,
		"health": health,
		"max_shields": max_shields,
		"shields": shields
	}

func unmarshal_spawn_state(state):
	max_health = state.max_health
	health = state.health
	max_shields = state.max_shields
	shields = state.shields
	
func marshal_frame_state() -> Dictionary:
	return {
		"health": health,
		"shields": shields
	}
	
