extends SceneTree

# Run with: Godot --headless --path . --script res://tests/test_stone_import.gd
# This checks the exported GLB Godot actually imports, not just its JSON data.
const STONES: PackedScene = preload("res://assets/models/props/border/rock_stylized.glb")


func _initialize() -> void:
	var root := STONES.instantiate()
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root, meshes)
	if meshes.size() != 4:
		_fail("Expected four stone meshes, got %d" % meshes.size())
		return
	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			_fail("Missing mesh on %s" % mesh_instance.name)
			return
		var material := mesh_instance.mesh.surface_get_material(0) as BaseMaterial3D
		if material == null or material.albedo_texture == null:
			_fail("Missing baked albedo on %s" % mesh_instance.name)
			return
	print("PASS: Godot imported four stone meshes with four baked albedo materials.")
	root.free()
	quit()


func _collect_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		_collect_meshes(child, meshes)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
