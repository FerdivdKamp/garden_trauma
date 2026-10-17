class_name TowerDefinition
extends Resource

# Typed tower data loaded from JSON; the playground edits it before saving.
var id: String
var firing_mode: String = "targeted"
var name: String
var cost: int
var damage: float
var cooldown: float
var attack_range: float
var detection_range: float
var turn_speed: float
var projectile_speed: float
var ball_count: int = 1
var homing_turn_speed: float = 120.0
var projectile_lifetime: float = 8.0
var bounce_height: float = 0.5
var bounce_frequency: float = 2.5
var damage_type: String
var bonus_vs_tags: Dictionary
var targets: PackedStringArray
var priority: String
var tags: PackedStringArray
var upgrades: Array[Dictionary] = []


func copy() -> TowerDefinition:
	# Resource.duplicate() only copies stored properties; these parsed fields are plain vars.
	var result := TowerDefinition.new()
	result.id = id
	result.firing_mode = firing_mode
	result.name = name
	result.cost = cost
	result.damage = damage
	result.cooldown = cooldown
	result.attack_range = attack_range
	result.detection_range = detection_range
	result.turn_speed = turn_speed
	result.projectile_speed = projectile_speed
	result.ball_count = ball_count
	result.homing_turn_speed = homing_turn_speed
	result.projectile_lifetime = projectile_lifetime
	result.bounce_height = bounce_height
	result.bounce_frequency = bounce_frequency
	result.damage_type = damage_type
	result.bonus_vs_tags = bonus_vs_tags.duplicate(true)
	result.targets = targets.duplicate()
	result.priority = priority
	result.tags = tags.duplicate()
	result.upgrades = upgrades.duplicate(true)
	return result
