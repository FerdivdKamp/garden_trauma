extends Node

const PlacementEnemy = preload("res://scripts/placement_enemy.gd")
const TowerVisual = preload("res://scripts/tower_visual.gd")
const ShotEffects = preload("res://scripts/placement_shot_effects.gd")

# Added to placed towers only; the tower demo keeps its own editable pawn test.
var definition: TowerDefinition

var enemies: Node3D
var effects: ShotEffects
var shot_clock := 0.0
var next_barrel := 0


func _process(delta: float) -> void:
	if enemies == null:
		return
	var tower := get_parent() as TowerVisual
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
		if enemy.reached_objective:
			continue
		if not _can_target(enemy):
			continue
		var distance := tower.global_position.distance_to(enemy.global_position)
		var priority_score := -distance
		if definition.priority == "first":
			priority_score = enemy.progress
		elif definition.priority == "last":
			priority_score = -enemy.progress
		if TowerRules.can_detect(distance, definition.detection_range) and priority_score > best_priority:
			target = enemy
			target_distance = distance
			best_priority = priority_score
	shot_clock += delta
	if target == null:
		return
	var direction := target.global_position - pivot.global_position
	var desired_yaw := TowerRules.target_yaw(direction)
	pivot.rotation.y = TowerRules.step_yaw(pivot.rotation.y, desired_yaw, deg_to_rad(definition.turn_speed), delta)
	var aimed := absf(angle_difference(pivot.rotation.y, desired_yaw)) < deg_to_rad(5.0)
	if shot_clock >= definition.cooldown and aimed and TowerRules.can_attack(target_distance, definition.attack_range, definition.detection_range):
		shot_clock = 0.0
		# Capture world positions now. Shell visuals can finish after the target has moved.
		var hit_position := target.visual.global_position
		var muzzle_position: Vector3 = tower.get_muzzle_position(next_barrel)
		if effects != null:
			if tower.tower_type == 0:
				effects.fire_laser(muzzle_position, hit_position)
			elif tower.tower_type == 1:
				effects.fire_shell(muzzle_position, hit_position, definition.projectile_speed)
				next_barrel = 1 - next_barrel
			else:
				effects.fire_lightning(muzzle_position, hit_position)
		tower.play_fire_sound()
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
