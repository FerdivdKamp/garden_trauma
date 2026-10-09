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
	_check(demo.tower_visual.get_yaw_pivot().name == "turret_yaw", "Laser tower uses the imported yaw pivot")
	var pitch := demo.tower_visual.get_node("LaserTower/turret_yaw/gunbase/turret_pitch") as Node3D
	var muzzle_before: Vector3 = demo.tower_visual.get_muzzle_position()
	var laser_yaw: Node3D = demo.tower_visual.get_yaw_pivot()
	laser_yaw.rotation.y = TowerRules.target_yaw(pawn.global_position - laser_yaw.global_position)
	demo.tower_visual.aim_pitch_at(pawn.global_position, 360.0, 1.0)
	_check(not is_zero_approx(pitch.rotation.x) and demo.tower_visual.get_muzzle_position().distance_to(muzzle_before) > 0.1, "Imported pitch pivot moves the muzzle")
	var barrel_direction: Vector3 = (demo.tower_visual.get_muzzle_position() - pitch.global_position).normalized()
	var target_direction: Vector3 = (pawn.global_position - pitch.global_position).normalized()
	_check(barrel_direction.dot(target_direction) > 0.95, "Imported barrel points toward the target")
	_check(demo.definition.id == "laser_tower" and demo.damage == demo.definition.damage, "Laser tower loads its definition")
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
		var edge_alpha := 0.0
		for vertex_color in vertex_colors:
			edge_alpha = maxf(edge_alpha, vertex_color.a)
		_check(vertex_colors[0].a < edge_alpha and edge_alpha > 0.5, "Range fades from center to edge")
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
	demo.call("_on_tower_selected", 2)
	await process_frame
	_check(pivot.get_child_count() == 2 and demo.definition.id == "lightning_tower", "Lightning tower is selectable in demo")
	demo._on_field_changed(360.0, "turn_speed", demo.fields["turn_speed"]["number"])
	demo._on_field_changed(4.0, "pawn_distance", demo.fields["pawn_distance"]["number"])
	var health_before: float = demo.pawn_health
	demo._process(1.2)
	_check(demo.pawn_health < health_before and demo.lightning_effect.active, "Demo lightning attack damages and draws a bolt")

	if failures == 0:
		print("Tower scene tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
