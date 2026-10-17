extends Node3D

const TILE_SIZE := LevelGrid.TILE_SIZE


func show_lane(grid: LevelGrid, origin: Vector2i, option: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	if option.is_empty():
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 0.94, 0.97, 0.32)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = false
	for cell in option.cells:
		var tile := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(TILE_SIZE * 0.88, 0.025, TILE_SIZE * 0.88)
		tile.mesh = mesh
		tile.material_override = material
		tile.position = grid.grid_to_world(cell) + Vector3(0, 0.16, 0)
		add_child(tile)
	var direction: Vector2i = option.direction
	var start := grid.grid_to_world(origin) + Vector3(direction.x, 0, direction.y) * 0.88 + Vector3.UP * 0.28
	var finish := grid.grid_to_world(option.cells.back()) + Vector3.UP * 0.28
	var arrow_material := StandardMaterial3D.new()
	arrow_material.albedo_color = Color("fff04e")
	arrow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var shaft := MeshInstance3D.new()
	var shaft_mesh := BoxMesh.new()
	shaft_mesh.size = Vector3(0.12, 0.08, start.distance_to(finish))
	shaft.mesh = shaft_mesh
	shaft.material_override = arrow_material
	shaft.position = (start + finish) * 0.5
	add_child(shaft)
	shaft.look_at(finish)
	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.32
	head_mesh.height = 0.52
	head.mesh = head_mesh
	head.material_override = arrow_material
	head.position = finish
	head.quaternion = Quaternion(Vector3.UP, Vector3(direction.x, 0, direction.y))
	add_child(head)
