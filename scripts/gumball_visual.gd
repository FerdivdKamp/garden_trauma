extends Node3D

const COLORS := [Color("ffe24c"), Color("46def0"), Color("a9ef53"), Color("ff9b42"), Color("ff6fbb"), Color("a577ef")]

@onready var direction_pivot: Node3D = $DirectionPivot
@onready var muzzle: Marker3D = $DirectionPivot/Muzzle


func _ready() -> void:
	# All visible geometry lives under one pivot. Replacing these meshes with a
	# GLB will leave lane logic and the Muzzle marker untouched.
	_add_box("LowerBase", Vector3(1.1, 0.2, 1.1), Vector3(0, 0.12, 0), Color("a91d31"))
	_add_box("MachineBody", Vector3(0.95, 0.75, 0.95), Vector3(0, 0.54, 0), Color("e93445"))
	_add_sphere("Globe", 0.48, Vector3(0, 1.37, 0), Color(0.74, 0.96, 1.0, 0.34))
	_add_cylinder("Lid", 0.57, 0.13, Vector3(0, 1.88, 0), Color("df293d"))
	_add_cylinder("Neck", 0.32, 0.1, Vector3(0, 0.98, 0), Color("bc2337"))
	# Fixed positions give the globe a full, colorful silhouette from above.
	for index in 18:
		var angle := float(index) * TAU / 9.0
		var ring := 0.26 if index < 9 else 0.18
		var height := 1.16 if index < 9 else 1.38
		_add_sphere("Candy%d" % index, 0.115, Vector3(cos(angle) * ring, height, sin(angle) * ring), COLORS[index % COLORS.size()])
	_add_box("ChuteFrame", Vector3(0.5, 0.34, 0.33), Vector3(0, 0.35, -0.61), Color("dcdbd0"))
	_add_box("ChuteOpening", Vector3(0.36, 0.19, 0.025), Vector3(0, 0.37, -0.79), Color("29333e"))
	_add_box("ChuteLip", Vector3(0.48, 0.055, 0.39), Vector3(0, 0.19, -0.73), Color("b9bfc1"))
	var knob := _add_cylinder("Knob", 0.13, 0.1, Vector3(0, 0.72, -0.54), Color("d5e1df"))
	knob.rotation.x = PI * 0.5


func face(direction: Vector2i) -> void:
	# Godot's forward is -Z, matching the laser tower's imported yaw convention.
	direction_pivot.rotation.y = atan2(-float(direction.x), -float(direction.y))


func set_preview(valid: bool, preview: bool) -> void:
	for part in direction_pivot.find_children("*", "MeshInstance3D", true, false):
		var mesh_part := part as MeshInstance3D
		var color: Color = mesh_part.get_meta("color")
		if preview:
			color = color.lightened(0.1) if valid else Color(0.9, 0.2, 0.2, 0.55)
			color.a = minf(color.a, 0.55)
		mesh_part.material_override = _material(color)


func _add_box(name: String, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_part(name, mesh, at, color)


func _add_sphere(name: String, radius: float, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _add_part(name, mesh, at, color)


func _add_cylinder(name: String, radius: float, height: float, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return _add_part(name, mesh, at, color)


func _add_part(name: String, mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name
	part.mesh = mesh
	part.position = at
	part.set_meta("color", color)
	part.material_override = _material(color)
	direction_pivot.add_child(part)
	return part


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.34
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	return material
