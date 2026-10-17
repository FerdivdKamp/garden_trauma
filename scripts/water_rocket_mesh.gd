extends Node3D

# Visual-only placeholder shared by the parked rocket and the flying projectile.
# Replace this scene with an imported model while keeping its nose along local +Y.
func _ready() -> void:
	var body := CylinderMesh.new()
	body.top_radius = 0.10
	body.bottom_radius = 0.12
	body.height = 0.43
	_add_part("RocketBody", body, Color("ffdb42"), Vector3(0, 0.24, 0))
	var nose := CylinderMesh.new()
	nose.top_radius = 0.0
	nose.bottom_radius = 0.11
	nose.height = 0.20
	_add_part("RocketNose", nose, Color("f05d4f"), Vector3(0, 0.56, 0))
	for index in 4:
		var fin := BoxMesh.new()
		fin.size = Vector3(0.07, 0.19, 0.17)
		var part := _add_part("Fin%d" % index, fin, Color("ed6653"), Vector3(0, 0.08, 0))
		part.rotation.y = index * PI * 0.5
		part.position += part.transform.basis * Vector3(0, 0, 0.16)


func _add_part(part_name: String, mesh: Mesh, color: Color, offset: Vector3) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.position = offset
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.42
	part.material_override = material
	add_child(part)
	return part
