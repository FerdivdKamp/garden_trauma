class_name TowerDefinition
extends Resource

# Typed tower data loaded from JSON; the playground edits it before saving.
var id: String
var name: String
var cost: int
var damage: float
var cooldown: float
var attack_range: float
var detection_range: float
var turn_speed: float
var projectile_speed: float
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
	result.name = name
	result.cost = cost
	result.damage = damage
	result.cooldown = cooldown
	result.attack_range = attack_range
	result.detection_range = detection_range
	result.turn_speed = turn_speed
	result.projectile_speed = projectile_speed
	result.damage_type = damage_type
	result.bonus_vs_tags = bonus_vs_tags.duplicate(true)
	result.targets = targets.duplicate()
	result.priority = priority
	result.tags = tags.duplicate()
	result.upgrades = upgrades.duplicate(true)
	return result
