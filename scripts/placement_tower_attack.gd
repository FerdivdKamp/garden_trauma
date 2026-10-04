extends Node

const PlacementEnemy = preload("res://scripts/placement_enemy.gd")

# Added to placed towers only; the tower demo keeps its own editable pawn test.
const SHOT_INTERVAL := 1.0

@export var detection_radius := 9.0
@export var attack_radius := 6.0
@export var turn_speed := 90.0
@export var damage := 10.0

var enemies: Node3D
var shot_clock := 0.0


func _process(delta: float) -> void:
	if enemies == null:
		return
	var tower := get_parent() as Node3D
	var pivot := tower.get_node("TurretPivot") as Node3D
	var target: PlacementEnemy
	var nearest := INF
	for child in enemies.get_children():
		var enemy := child as PlacementEnemy
		if enemy == null:
			continue
		if enemy.health <= 0.0:
			continue
		var distance := tower.global_position.distance_to(enemy.global_position)
		if TowerRules.can_detect(distance, detection_radius) and distance < nearest:
			target = enemy
			nearest = distance
	shot_clock += delta
	if target == null:
		return
	var direction := target.global_position - pivot.global_position
	var desired_yaw := TowerRules.target_yaw(direction)
	pivot.rotation.y = TowerRules.step_yaw(pivot.rotation.y, desired_yaw, deg_to_rad(turn_speed), delta)
	var aimed := absf(angle_difference(pivot.rotation.y, desired_yaw)) < deg_to_rad(5.0)
	if shot_clock >= SHOT_INTERVAL and aimed and TowerRules.can_attack(nearest, attack_radius, detection_radius):
		shot_clock = 0.0
		target.take_damage(damage)
