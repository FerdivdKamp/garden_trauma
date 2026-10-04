extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/tower_demo.tscn") as PackedScene
	var demo := scene.instantiate()
	root.add_child(demo)
	await process_frame

	var pivot := demo.get_node("Tower/TurretPivot") as Node3D
	var pawn := demo.get_node("Pawn") as Node3D
	_check(pivot.get_child_count() == 2, "Single barrel has a cap and one barrel")
	_check(demo.definition.id == "toy_tank" and demo.damage == demo.definition.damage, "Single barrel loads tower definition")
	var attack_area := demo.get_node("Tower/RangeVisual/AttackArea") as MeshInstance3D
	var detection_area := demo.get_node("Tower/RangeVisual/DetectionArea") as MeshInstance3D
	_check(demo.get_node("Tower/RangeVisual").visible, "Demo shows the filled ranges")
	var green: Color = attack_area.material_override.albedo_color
	var yellow: Color = detection_area.material_override.albedo_color
	_check(green.g > green.r and yellow.r > yellow.b and yellow.g > yellow.b, "Attack is green and detection is yellow")
	var green_vertices: PackedVector3Array = attack_area.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	_check(green_vertices.size() > 3 and green_vertices[0].length() < demo.attack_radius, "Attack area is filled")
	var yellow_vertices: PackedVector3Array = detection_area.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var smallest_yellow_radius := INF
	for vertex in yellow_vertices:
		smallest_yellow_radius = minf(smallest_yellow_radius, Vector2(vertex.x, vertex.z).length())
	_check(is_zero_approx(smallest_yellow_radius), "Detection range is also a filled circle")
	for area in [attack_area, detection_area]:
		var vertex_colors: PackedColorArray = area.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
		_check(area.material_override.vertex_color_use_as_albedo and vertex_colors.size() > 2, "Range material uses vertex colors")
		_check(is_zero_approx(vertex_colors[0].a) and is_equal_approx(vertex_colors[1].a, 1.0), "Range fades from transparent center to opaque edge")
	_check(is_equal_approx(demo.fire_rate, 1.0 / demo.definition.cooldown), "Fire rate field loads from tower cooldown")
	demo._on_field_changed(2.0, "fire_rate", demo.fields["fire_rate"]["number"])
	_check(is_equal_approx(demo.definition.cooldown, 0.5), "Changing fire rate updates seconds between shots")
	_check(is_equal_approx(pawn.position.x, demo.get("pawn_distance")), "Pawn position matches its distance setting")

	demo.call("_on_tower_selected", 1)
	await process_frame
	_check(pivot.get_child_count() == 3, "Double barrel has a cap and two barrels")
	_check(demo.definition.id == "double_tank", "Double barrel loads its own definition")
	_check(is_equal_approx(demo.fire_rate, 1.0 / demo.definition.cooldown), "Switching towers loads its fire rate")

	demo.call("_reset_aim")
	var direction: Vector3 = pawn.global_position - pivot.global_position
	var target_yaw := TowerRules.target_yaw(direction)
	_check(is_equal_approx(absf(angle_difference(pivot.rotation.y, target_yaw)), PI), "Reset aims away from pawn")

	if failures == 0:
		print("Tower scene tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
