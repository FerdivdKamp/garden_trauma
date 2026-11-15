extends Node3D

signal hit_target(target: Node)

const PlacementEnemy = preload("res://scripts/placement_enemy.gd")
const HIT_RADIUS := 0.60
const SPIRAL_DURATION := 1.8
const SPIRAL_RADIUS := 0.65
const SPIRAL_TURNS := 2.5
const SPIRAL_CLIMB_SPEED := 5.0

@onready var trail: GPUParticles3D = $WaterTrail
@onready var rocket_visual: Node3D = $RocketVisual

var target_ref: WeakRef
var direction := Vector3.UP
var speed := 5.0
var turn_speed := 120.0
var max_lifetime := 8.0
var damage := 18.0
var damage_type := "water"
var bonus_vs_tags: Dictionary = {}
var elapsed := 0.0
var impacted := false
var spiraling := false
var spiral_elapsed := 0.0
var spiral_origin := Vector3.ZERO


func _ready() -> void:
	_build_trail()
	trail.emitting = true


func configure(target: Node, shot_direction: Vector3, definition: TowerDefinition) -> void:
	target_ref = weakref(target)
	direction = shot_direction.normalized()
	speed = definition.projectile_speed
	turn_speed = definition.homing_turn_speed
	max_lifetime = definition.projectile_lifetime
	damage = definition.damage
	damage_type = definition.damage_type
	bonus_vs_tags = definition.bonus_vs_tags.duplicate()
	_update_orientation()


func _physics_process(delta: float) -> void:
	if impacted:
		return
	if spiraling:
		_advance_spiral(delta)
		return
	elapsed += delta
	var target: PlacementEnemy = null
	if target_ref != null:
		target = target_ref.get_ref() as PlacementEnemy
	if target == null or target.health <= 0.0 or target.reached_objective:
		# The target may have been freed, defeated, or reached the objective.
		spiraling = true
		spiral_origin = global_position
		_advance_spiral(delta)
		return
	if elapsed >= max_lifetime:
		queue_free()
		return
	if target != null and target.health > 0.0 and not target.reached_objective:
		var to_target := target.get_aim_position() - global_position
		var desired := to_target.normalized()
		var angle := direction.angle_to(desired)
		var turn_rate := deg_to_rad(turn_speed)
		if elapsed > 0.25:
			# The normal turn rate draws the launch arc. Near an enemy, tighten
			# the turn so a faster rocket cannot orbit just outside hit range.
			turn_rate = maxf(turn_rate, speed / maxf(to_target.length() * 0.5, 0.5))
		direction = direction.slerp(desired, minf(1.0, turn_rate * delta / maxf(angle, 0.0001))).normalized()
	_update_orientation()
	var previous_position := global_position
	global_position += direction * speed * delta
	if target != null and target.health > 0.0 and not target.reached_objective:
		var hit_position := target.get_aim_position()
		var closest := Geometry3D.get_closest_point_to_segment(hit_position, previous_position, global_position)
		if closest.distance_to(hit_position) <= HIT_RADIUS:
			_impact(target)


func _advance_spiral(delta: float) -> void:
	var previous_position := global_position
	spiral_elapsed = minf(spiral_elapsed + delta, SPIRAL_DURATION)
	var angle := spiral_elapsed / SPIRAL_DURATION * TAU * SPIRAL_TURNS
	# Subtract the initial radius so the spiral starts at the current position.
	global_position = spiral_origin + Vector3(
		SPIRAL_RADIUS * (cos(angle) - 1.0),
		SPIRAL_CLIMB_SPEED * spiral_elapsed,
		SPIRAL_RADIUS * sin(angle)
	)
	var movement := global_position - previous_position
	if movement.length_squared() > 0.0001:
		direction = movement.normalized()
		_update_orientation()
	if spiral_elapsed >= SPIRAL_DURATION:
		_water_firework()


func _water_firework() -> void:
	impacted = true
	rocket_visual.hide()
	trail.emitting = false
	# Put the burst in world space so its upward spout ignores the rocket's tilt.
	global_basis = Basis.IDENTITY
	_make_water_burst("WaterFirework", 80, 180.0, 4.0, 1.3)
	_make_water_burst("WaterSpout", 45, 18.0, 5.5, 1.5)
	get_tree().create_timer(2.0).timeout.connect(queue_free)


func _make_water_burst(effect_name: String, count: int, spread: float, velocity: float, lifetime: float) -> void:
	var particles := GPUParticles3D.new()
	particles.name = effect_name
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = count
	particles.lifetime = lifetime
	particles.local_coords = false
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = spread
	process.initial_velocity_min = velocity * 0.55
	process.initial_velocity_max = velocity
	process.gravity = Vector3(0, -5.0, 0)
	process.color = Color("72e7ff")
	process.scale_min = 0.7
	process.scale_max = 1.4
	particles.process_material = process
	particles.draw_pass_1 = trail.draw_pass_1
	add_child(particles)
	particles.emitting = true


func _impact(target: PlacementEnemy) -> void:
	if impacted:
		return
	impacted = true
	var multiplier := 1.0 - target.definition.armor_for(damage_type)
	for tag in target.definition.tags:
		if bonus_vs_tags.has(tag):
			multiplier *= float(bonus_vs_tags[tag])
	target.take_damage(damage * multiplier)
	hit_target.emit(target)
	queue_free()


func _update_orientation() -> void:
	# The toy rocket's nose is local +Y; the droplet emitter sits behind it.
	quaternion = Quaternion(Vector3.UP, direction)


func _build_trail() -> void:
	trail.amount = 38
	trail.lifetime = 0.6
	trail.local_coords = false
	trail.emitting = false
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.DOWN
	process.spread = 24.0
	process.initial_velocity_min = 0.25
	process.initial_velocity_max = 0.9
	process.gravity = Vector3(0, -2.2, 0)
	process.color = Color("55dfff")
	process.scale_min = 0.65
	process.scale_max = 1.25
	trail.process_material = process
	var droplet := SphereMesh.new()
	droplet.radius = 0.045
	droplet.height = 0.09
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("55dfff")
	material.roughness = 0.18
	material.vertex_color_use_as_albedo = true
	droplet.material = material
	trail.draw_pass_1 = droplet
