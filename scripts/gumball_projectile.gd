extends Node3D

const PlacementEnemy = preload("res://scripts/placement_enemy.gd")
const HIT_RADIUS := 0.72

@onready var visual: MeshInstance3D = $Visual

var direction := Vector3.FORWARD
var speed := 7.0
var remaining_distance := 0.0
var damage := 7.0
var damage_type := "physical"
var bounce_height := 0.5
var bounce_frequency := 2.5
var bounce_phase := 0.0
var ball_color := Color("ffe24c")
var elapsed := 0.0
var max_lifetime := 8.0
var enemies: Node3D
var hit_enemies: Dictionary = {}


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = ball_color
	material.roughness = 0.24
	visual.material_override = material


func configure(start: Vector3, endpoint: Vector3, definition: TowerDefinition, enemy_container: Node3D, color: Color, spread: float) -> void:
	global_position = start
	direction = (endpoint - start).normalized()
	remaining_distance = start.distance_to(endpoint)
	speed = definition.projectile_speed * (1.0 + spread * 0.08)
	damage = definition.damage
	damage_type = definition.damage_type
	bounce_height = definition.bounce_height * (1.0 + spread * 0.18)
	bounce_frequency = definition.bounce_frequency * (1.0 - spread * 0.12)
	bounce_phase = absf(spread) * 0.3
	ball_color = color
	(visual.material_override as StandardMaterial3D).albedo_color = color
	max_lifetime = remaining_distance / speed + 1.0
	enemies = enemy_container


func _physics_process(delta: float) -> void:
	if remaining_distance <= 0.0:
		queue_free()
		return
	elapsed += delta
	if elapsed > max_lifetime:
		queue_free()
		return
	var previous := global_position
	var step := minf(speed * delta, remaining_distance)
	global_position += direction * step
	remaining_distance -= step
	# Logical travel stays horizontal; only the mesh bounces.
	# abs(sin) makes one full hop per PI radians.
	visual.position.y = absf(sin(elapsed * PI * bounce_frequency + bounce_phase)) * bounce_height
	visual.rotation.x += delta * 4.0
	_check_hits(previous, global_position)
	if remaining_distance <= 0.0:
		queue_free()


func _check_hits(previous: Vector3, current: Vector3) -> void:
	if enemies == null:
		return
	for child in enemies.get_children():
			var enemy := child as PlacementEnemy
			if enemy == null or enemy.health <= 0.0 or enemy.reached_objective or hit_enemies.has(enemy.get_instance_id()):
				continue
			if not "ground" in enemy.definition.tags:
				continue
			# A swept XZ check catches fast balls without tying damage to bounce height.
			var point := Vector3(enemy.global_position.x, previous.y, enemy.global_position.z)
			var closest := Geometry3D.get_closest_point_to_segment(point, previous, current)
			if closest.distance_to(point) <= HIT_RADIUS:
				hit_enemies[enemy.get_instance_id()] = true
				var multiplier := 1.0 - enemy.definition.armor_for(damage_type)
				enemy.take_damage(damage * multiplier)
