extends Node

const PlacementEnemy = preload("res://scripts/placement_enemy.gd")
const TowerDefinition = preload("res://scripts/tower_definition.gd")

# Added to placed towers only; the tower demo keeps its own editable pawn test.
@export var detection_radius := 9.0
@export var turn_speed := 90.0

var definition: TowerDefinition

var enemies: Node3D
var shot_clock := 0.0


func _process(delta: float) -> void:
	if enemies == null:
		return
	var tower := get_parent() as Node3D
	var pivot := tower.get_node("TurretPivot") as Node3D
	var target: PlacementEnemy
	var target_distance := INF
	var best_priority := -INF
	for child in enemies.get_children():
		var enemy := child as PlacementEnemy
		if enemy == null:
			continue
		if enemy.health <= 0.0:
			continue
		if not _can_target(enemy):
			continue
		var distance := tower.global_position.distance_to(enemy.global_position)
		var priority_score := -distance
		if definition.priority == "first":
			priority_score = enemy.progress
		elif definition.priority == "last":
			priority_score = -enemy.progress
		if TowerRules.can_detect(distance, detection_radius) and priority_score > best_priority:
			target = enemy
			target_distance = distance
			best_priority = priority_score
	shot_clock += delta
	if target == null:
		return
	var direction := target.global_position - pivot.global_position
	var desired_yaw := TowerRules.target_yaw(direction)
	pivot.rotation.y = TowerRules.step_yaw(pivot.rotation.y, desired_yaw, deg_to_rad(turn_speed), delta)
	var aimed := absf(angle_difference(pivot.rotation.y, desired_yaw)) < deg_to_rad(5.0)
	if shot_clock >= definition.cooldown and aimed and TowerRules.can_attack(target_distance, definition.attack_range, detection_radius):
		shot_clock = 0.0
		var multiplier := 1.0 - target.definition.armor_for(definition.damage_type)
		for tag in target.definition.tags:
			if definition.bonus_vs_tags.has(tag):
				multiplier *= float(definition.bonus_vs_tags[tag])
		target.take_damage(definition.damage * multiplier)


func _can_target(enemy: PlacementEnemy) -> bool:
	for target_tag in definition.targets:
		if target_tag in enemy.definition.tags:
			return true
	return false
