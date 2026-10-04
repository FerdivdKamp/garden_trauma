class_name TowerDefinition
extends Resource

# A typed, read-only-by-convention view of one data/towers JSON file.
var id: String
var name: String
var cost: int
var damage: float
var cooldown: float
var attack_range: float
var projectile_speed: float
var damage_type: String
var bonus_vs_tags: Dictionary
var targets: PackedStringArray
var priority: String
var tags: PackedStringArray
