class_name LavaProjectile
extends Node3D

signal landed(cell: Vector2i, definition: TowerDefinition)

var cell := Vector2i.ZERO
var definition: TowerDefinition
var start := Vector3.ZERO
var destination := Vector3.ZERO
var travel_time := 0.9
var elapsed := 0.0
var launch_delay := 0.22
var body: MeshInstance3D
var droplets: Array[MeshInstance3D] = []


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ff751d")
	material.emission_enabled = true
	material.emission = Color("ff9f28")
	material.emission_energy_multiplier = 2.0
	body = _sphere("LavaBlob", 0.23, material)
	body.scale = Vector3(1.1, 1.25, 0.9)
	for index in 3:
		var drop := _sphere("Droplet%d" % index, 0.06, material)
		droplets.append(drop)


func configure(origin: Vector3, target: Vector3, target_cell: Vector2i, shot: TowerDefinition) -> void:
	start = origin
	destination = target + Vector3.UP * 0.19
	cell = target_cell
	definition = shot.copy()
	travel_time = clampf(Vector2(origin.x - target.x, origin.z - target.z).length() / shot.projectile_speed, 0.7, 1.1)
	global_position = start


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < launch_delay:
		return
	var progress := minf((elapsed - launch_delay) / travel_time, 1.0)
	var arc_height := 1.6 + start.distance_to(destination) * 0.12
	global_position = start.lerp(destination, progress) + Vector3.UP * sin(progress * PI) * arc_height
	body.scale.y = 1.25 + sin(progress * PI) * 0.45
	body.rotation.z += delta * 3.0
	for index in droplets.size():
		var drop := droplets[index]
		var behind := 0.12 + index * 0.13
		drop.position = Vector3(sin(elapsed * 13.0 + index) * 0.14, -behind, cos(elapsed * 9.0 + index) * 0.12)
	if progress >= 1.0:
		landed.emit(cell, definition)
		queue_free()


func _sphere(part_name: String, radius: float, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.material_override = material
	add_child(part)
	return part
