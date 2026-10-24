class_name LavaLampVisual
extends Node3D

@onready var visual_root: Node3D = $VisualRoot
@onready var base: Node3D = $VisualRoot/Base
@onready var chamber: Node3D = $VisualRoot/GlassChamber
@onready var lava: Node3D = $VisualRoot/LavaContents
@onready var cap: Node3D = $VisualRoot/TopCap
@onready var muzzle: Marker3D = $VisualRoot/Muzzle

var blobs: Array[MeshInstance3D] = []
var glow_material: StandardMaterial3D
var idle_time := 0.0
var pressure := 0.0
var firing_tween: Tween


func _ready() -> void:
	var housing := _material(Color("603b83"), 0.15, 0.62)
	var rim := _material(Color("eacb6d"), 0.7, 0.26)
	var glass := _material(Color(0.54, 0.92, 0.96, 0.28), 0.0, 0.08)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow_material = _material(Color("ff761b"), 0.0, 0.18)
	glow_material.emission_enabled = true
	glow_material.emission = Color("ff5317")
	glow_material.emission_energy_multiplier = 1.2
	_add_cylinder(base, "WideBase", 0.52, 0.88, 0.32, 0.18, housing)
	_add_cylinder(base, "GoldFoot", 0.7, 0.72, 0.08, 0.05, rim)
	_add_cylinder(chamber, "Liquid", 0.31, 0.43, 1.55, 1.12, glow_material)
	_add_cylinder(chamber, "GlassShell", 0.37, 0.5, 1.75, 1.15, glass)
	_add_cylinder(chamber, "LowerRim", 0.53, 0.51, 0.09, 0.38, rim)
	_add_cylinder(cap, "UpperRim", 0.38, 0.5, 0.1, 2.04, rim)
	_add_cylinder(cap, "Cap", 0.23, 0.39, 0.37, 2.28, housing)
	_add_cylinder(cap, "Nozzle", 0.11, 0.15, 0.12, 2.49, rim)
	for index in 4:
		var blob := MeshInstance3D.new()
		blob.name = "LavaBlob%d" % index
		var mesh := SphereMesh.new()
		mesh.radius = 0.23 if index % 2 == 0 else 0.17
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 10
		mesh.rings = 5
		blob.mesh = mesh
		blob.material_override = glow_material
		blob.position = Vector3(cos(float(index) * 2.1) * 0.13, 0.73 + index * 0.34, sin(float(index) * 2.1) * 0.13)
		blob.scale = Vector3(1.0, 1.25, 0.85)
		lava.add_child(blob)
		blobs.append(blob)


func _process(delta: float) -> void:
	idle_time += delta
	for index in blobs.size():
		var blob := blobs[index]
		blob.position.y = 0.73 + index * 0.34 + sin(idle_time * 1.1 + index * 1.8) * 0.08 + pressure * 0.13
		blob.scale.y = 1.25 + sin(idle_time * 1.4 + index) * 0.12 + pressure * 0.4
	cap.position.y = pressure * 0.16
	glow_material.emission_energy_multiplier = 1.2 + pressure * 2.3


func fire() -> void:
	if firing_tween != null:
		firing_tween.kill()
	firing_tween = create_tween()
	firing_tween.tween_property(self, "pressure", 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	firing_tween.tween_property(self, "pressure", 0.0, 0.34).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func set_preview(valid: bool, preview: bool) -> void:
	for part in visual_root.find_children("*", "MeshInstance3D", true, false):
		var mesh_part := part as MeshInstance3D
		mesh_part.transparency = 0.35 if preview else 0.0
		if preview and not valid:
			var warning := StandardMaterial3D.new()
			warning.albedo_color = Color(1.0, 0.18, 0.15, 0.65)
			warning.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_part.material_overlay = warning
		else:
			mesh_part.material_overlay = null


func _add_cylinder(parent: Node3D, part_name: String, top: float, bottom: float, height: float, y: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 12
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.material_override = material
	part.position.y = y
	parent.add_child(part)


func _material(color: Color, metal: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = roughness
	return material
