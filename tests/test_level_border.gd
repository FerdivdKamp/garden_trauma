extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var border := LevelBorder.new()
	root.add_child(border)
	border.build(3, 2)
	assert(border.get_child_count() == 6, "Two-cell sections should cover the perimeter")
	assert(border.get_child(0).position.is_equal_approx(Vector3(-3.0, 0.0, -2.0)))
	assert(border.get_child(1).position.is_equal_approx(Vector3(1.0, 0.0, -2.0)))
	assert(border.get_child(2).position.is_equal_approx(Vector3(3.0, 0.0, -2.0)))
	assert(border.get_child(3).position.is_equal_approx(Vector3(3.0, 0.0, 2.0)))
	assert(border.get_child(5).position.is_equal_approx(Vector3(-3.0, 0.0, 2.0)))
	assert(border.get_child(0).scale.is_equal_approx(Vector3(2.0, 4.0, 2.0)))
	assert(border.get_child(1).scale.is_equal_approx(Vector3(2.0, 4.0, 1.0)),
		"An odd-length side ends with one cell of rail")
	var first_segment := border.get_child(0) as Node3D
	assert(absf(first_segment.global_position.distance_to(first_segment.to_global(Vector3(0.0, 0.0, -2.0))) - 4.0) < 0.01)
	var min_point := Vector3(INF, INF, INF)
	var max_point := Vector3(-INF, -INF, -INF)
	for mesh in border.get_child(0).find_children("*", "MeshInstance3D", true, false):
		var bounds: AABB = mesh.get_aabb()
		for corner in 8:
			var point: Vector3 = border.get_child(0).to_local(mesh.to_global(bounds.get_endpoint(corner)))
			min_point = min_point.min(point)
			max_point = max_point.max(point)
	assert(absf(min_point.z + 2.0) < 0.01 and absf(max_point.z) < 0.3,
		"The Blender module must extend 2 m along Godot local -Z before scaling")
	assert(min_point.y > -0.01 and max_point.y > 1.0,
		"Fence should stand on the tile plane")
	print("Level border module and perimeter placement validated")
	quit()
