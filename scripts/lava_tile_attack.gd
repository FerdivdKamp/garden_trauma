extends "res://scripts/placement_tower_attack.gd"

var grid: LevelGrid
var lava_field: LavaField


func _process(delta: float) -> void:
	if lava_field == null or not lava_field.active or enemies == null:
		return
	shot_clock = minf(shot_clock + delta, definition.cooldown)
	if shot_clock < definition.cooldown:
		return
	var tower := get_parent() as TowerVisual
	var cell := choose_target_cell(tower.global_position)
	if cell == Vector2i(-1, -1):
		return
	if lava_field.launch(tower.get_muzzle_position(), cell, definition):
		shot_clock = 0.0
		tower.play_lava_fire()


func choose_target_cell(tower_position: Vector3) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for child in enemies.get_children():
		var enemy := child as PlacementEnemy
		if enemy == null or enemy.health <= 0.0 or enemy.reached_objective or not _can_target(enemy):
			continue
		var cell := grid.world_to_grid(enemy.global_position)
		if not grid.is_walkable(cell) or lava_field.is_covered(cell):
			continue
		var center := grid.grid_to_world(cell)
		var distance := Vector2(center.x - tower_position.x, center.z - tower_position.z).length()
		if TowerRules.can_attack(distance, definition.attack_range, definition.detection_range) and distance < best_distance:
			best_distance = distance
			best = cell
	return best
