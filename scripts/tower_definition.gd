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
