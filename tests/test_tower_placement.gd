extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/tower_placement.tscn") as PackedScene
	var demo := scene.instantiate()
	root.add_child(demo)
	await process_frame

	var path := demo.get_node("PlacementPath")
	_check(path.curve.point_count == demo.grid.route.size(), "Enemy path follows the level route")
	_check(not demo.can_place_at(Vector3(0, 0, -6)), "Path blocks tower placement")
	_check(demo.can_place_at(Vector3(-8, 0, 8)), "Open ground allows placement")
	_check(not demo.can_place_at(Vector3(20, 0, 12)), "Outside grid blocks placement")
	_check(not demo.can_place_at(demo.grid.grid_to_world(Vector2i(5, 4))), "Rock tile blocks placement")

	demo._select_tower(1)
	_check(demo.preview != null and demo.preview.is_preview, "Selecting a tile creates a preview")
	var preview_base := demo.preview.get_node("Base") as MeshInstance3D
	_check(preview_base.material_override.albedo_color.a < 1.0, "Preview is translucent")
	_check(demo.preview.get_node("RangeVisual").visible, "Selected preview shows its ranges")
	var preview_detection := demo.preview.get_node("RangeVisual/DetectionArea") as MeshInstance3D
	var preview_vertices: PackedVector3Array = preview_detection.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	_check(preview_vertices.size() > 3 and is_zero_approx(Vector2(preview_vertices[0].x, preview_vertices[0].z).length()), "Preview detection range is filled")
	demo.place_tower(Vector3(-8, 0, 8))
	_check(demo.placed_towers.get_child_count() == 1, "Click places a tower")
	_check(demo.placed_towers.get_child(0).position == demo.grid.grid_to_world(demo.grid.world_to_grid(Vector3(-8, 0, 8))), "Tower snaps to its tile center")
	_check(not demo.can_place_at(Vector3(-7, 0, 8)), "Towers cannot overlap")
	demo.place_tower(Vector3(-7, 0, 8))
	_check(demo.placed_towers.get_child_count() == 1, "Invalid placement creates no tower")
	demo.place_tower(Vector3(8, 0, 8))
	_check(demo.placed_towers.get_child_count() == 2, "Selection remains active for repeated placement")
	var second_pivot: Node3D = demo.placed_towers.get_child(1).get_node("TurretPivot")
	_check(second_pivot.get_child_count() == 3, "Placed double tower uses shared visual")
	_check(demo.placed_towers.get_child(0).get_node("Attack").definition.id == "double_tank", "Double barrel uses its own definition")
	var first_tower := demo.placed_towers.get_child(0) as Node3D
	var hover_screen: Vector2 = demo.camera.unproject_position(first_tower.global_position + Vector3(0.0, 0.6, 0.0))
	demo._update_hovered_tower(hover_screen)
	_check(first_tower.get_node("RangeVisual").visible, "Hovering a placed tower shows its ranges")
	demo._update_hovered_tower(Vector2(-1000.0, -1000.0))
	_check(not first_tower.get_node("RangeVisual").visible, "Leaving a tower hides its ranges")
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	demo._input(right_click)
	_check(demo.selected_type == -1 and demo.preview == null, "Right click empties the hand")
	_check(not demo.tower_buttons[0].button_pressed and not demo.tower_buttons[1].button_pressed, "Right click clears tower tiles")
	demo._update_hovered_tower(hover_screen)
	_check(first_tower.get_node("RangeVisual").visible, "Hover still shows ranges with an empty hand")
	demo._select_tower(0)
	_check(demo.selected_type == 0 and demo.tower_buttons[0].button_pressed, "Clicking a tile selects a builder again")
	demo._select_tower(2)
	demo.place_tower(Vector3(0, 0, 8))
	var lightning_tower := demo.placed_towers.get_child(2) as Node3D
	_check(demo.tower_buttons.size() == 3 and lightning_tower.tower_type == 2, "Lightning tower is selectable and placeable")
	_check(lightning_tower.get_node("TurretPivot/Orb/LightningOrigin") != null, "Lightning orb has a strike origin")

	if failures == 0:
		print("Tower placement tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
