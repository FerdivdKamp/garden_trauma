class_name LavaPuddle
extends Node3D

var cell := Vector2i.ZERO
var radius := 0.9
var damage_per_second := 4.0
var impact_damage := 5.0
var damage_type := "physical"
var elapsed := 0.0
var crust: MeshInstance3D
var center: MeshInstance3D
var crust_lobes: Array[MeshInstance3D] = []
var molten_lobes: Array[MeshInstance3D] = []
var hot_spots: Array[MeshInstance3D] = []
var molten_material: StandardMaterial3D


func _ready() -> void:
	crust = _disc("DarkCrust", Color("69202a"), 1.0, 0.035)
	center = _disc("MoltenCenter", Color("f25a15"), 0.78, 0.055)
	molten_material = center.material_override as StandardMaterial3D
	molten_material.emission_enabled = true
	molten_material.emission = Color("ff7226")
	molten_material.emission_energy_multiplier = 1.5
	# Offset flat lobes make the outline read as a splash rather than a circle.
	for index in 5:
		crust_lobes.append(_disc("CrustLobe%d" % index, Color("69202a"), 0.34 + 0.05 * (index % 2), 0.034))
	for index in 3:
		var lobe := _disc("MoltenLobe%d" % index, Color("f25a15"), 0.25, 0.055)
		lobe.material_override = molten_material
		molten_lobes.append(lobe)
	for index in 4:
		var spot := _disc("HotSpot%d" % index, Color("ffd04c"), 0.13 + 0.03 * (index % 2), 0.07)
		spot.position.x = cos(float(index) * 2.4) * radius * 0.43
		spot.position.z = sin(float(index) * 2.4) * radius * 0.4
		hot_spots.append(spot)
	scale = Vector3(0.2, 1.0, 0.2)
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func configure(target_cell: Vector2i, center_position: Vector3, shot: TowerDefinition) -> void:
	cell = target_cell
	radius = shot.puddle_radius
	damage_per_second = shot.lava_damage_per_second
	impact_damage = shot.damage
	damage_type = shot.damage_type
	global_position = center_position + Vector3.UP * 0.12
	crust.scale.x = radius
	crust.scale.z = radius * 0.94
	center.scale.x = radius
	center.scale.z = radius * 0.9
	for index in crust_lobes.size():
		var angle := float(index) * TAU / 5.0
		crust_lobes[index].position.x = cos(angle) * radius * 0.78
		crust_lobes[index].position.z = sin(angle) * radius * 0.7
		crust_lobes[index].scale.x = radius
		crust_lobes[index].scale.z = radius
	for index in molten_lobes.size():
		var angle := float(index) * TAU / 3.0 + 0.3
		molten_lobes[index].position.x = cos(angle) * radius * 0.53
		molten_lobes[index].position.z = sin(angle) * radius * 0.5
		molten_lobes[index].scale.x = radius
		molten_lobes[index].scale.z = radius
	for index in hot_spots.size():
		hot_spots[index].position.x = cos(float(index) * 2.4) * radius * 0.43
		hot_spots[index].position.z = sin(float(index) * 2.4) * radius * 0.4


func _process(delta: float) -> void:
	elapsed += delta
	center.rotation.y = sin(elapsed * 0.7) * 0.08
	for index in hot_spots.size():
		var spot := hot_spots[index]
		spot.scale.y = 0.08 * (1.0 + sin(elapsed * 2.0 + index * 1.8) * 0.35)
		spot.position.y = 0.07 + sin(elapsed * 1.7 + index) * 0.013


func cool() -> void:
	set_process(false)
	var cooling := create_tween()
	cooling.set_parallel(true)
	cooling.tween_property(molten_material, "emission_energy_multiplier", 0.0, 0.4)
	cooling.tween_property(molten_material, "albedo_color", Color("4c3338"), 0.4)
	cooling.tween_property(self, "scale", Vector3(0.65, 0.6, 0.65), 0.4)
	cooling.chain().tween_callback(queue_free)


func _disc(part_name: String, color: Color, size: float, y: float) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 12
	mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.4
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.material_override = material
	part.position.y = y
	part.scale.y = 0.08
	add_child(part)
	return part
