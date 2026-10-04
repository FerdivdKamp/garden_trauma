extends Node3D

const SEGMENTS := 96

@onready var attack_area: MeshInstance3D = $AttackArea
@onready var detection_area: MeshInstance3D = $DetectionArea


func set_ranges(attack_radius: float, detection_radius: float) -> void:
	# Draw both as filled discs. The smaller green disc sits just above the yellow one.
	var attack := maxf(0.0, minf(attack_radius, detection_radius))
	var detection := maxf(attack, detection_radius)
	attack_area.mesh = _disc(attack, 0.055)
	detection_area.mesh = _disc(detection, 0.05)
	attack_area.material_override = _material(Color(0.24, 0.85, 0.35))
	detection_area.material_override = _material(Color(1.0, 0.82, 0.18))
	attack_area.material_override.render_priority = 1


func _disc(radius: float, height: float) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in SEGMENTS:
		# Vertex alpha fades from clear at the center to solid at the boundary.
		mesh.surface_set_color(Color(1.0, 1.0, 1.0, 0.0))
		mesh.surface_add_vertex(Vector3(0.0, height, 0.0))
		mesh.surface_set_color(Color.WHITE)
		mesh.surface_add_vertex(_point(radius, index + 1, height))
		mesh.surface_add_vertex(_point(radius, index, height))
	mesh.surface_end()
	return mesh


func _point(radius: float, index: int, height: float) -> Vector3:
	var angle := TAU * float(index) / float(SEGMENTS)
	return Vector3(cos(angle) * radius, height, sin(angle) * radius)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	material.vertex_color_use_as_albedo = true
	return material
