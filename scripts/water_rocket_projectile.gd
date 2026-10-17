extends Node3D

signal hit_target(target: Node)

const PlacementEnemy = preload("res://scripts/placement_enemy.gd")
const HIT_RADIUS := 0.60

@onready var trail: GPUParticles3D = $WaterTrail

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
	elapsed += delta
	if elapsed >= max_lifetime:
		queue_free()
		return
	var target: PlacementEnemy = null
	if target_ref != null:
		target = target_ref.get_ref() as PlacementEnemy
	if target != null and target.health > 0.0 and not target.reached_objective:
		var to_target := target.visual.global_position - global_position
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
		var closest := Geometry3D.get_closest_point_to_segment(target.visual.global_position, previous_position, global_position)
		if closest.distance_to(target.visual.global_position) <= HIT_RADIUS:
			_impact(target)


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
