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
	_check(path.curve.point_count == 4, "Path has editable curve points")
	_check(not demo.can_place_at(Vector3(0, 0, -6)), "Path blocks tower placement")
	_check(demo.can_place_at(Vector3(-8, 0, 8)), "Open ground allows placement")
	_check(not demo.can_place_at(Vector3(18, 0, 12)), "Tower footprint stays inside ground")
	path.path_width = 8.0
	_check(not demo.can_place_at(Vector3(-8, 0, -1)), "Changing width changes blocked area")
	path.path_width = 3.0

	demo._select_tower(1)
	_check(demo.preview != null and demo.preview.is_preview, "Selecting a tile creates a preview")
	var preview_base := demo.preview.get_child(1) as MeshInstance3D
	_check(preview_base.material_override.albedo_color.a < 1.0, "Preview is translucent")
	demo.place_tower(Vector3(-8, 0, 8))
	_check(demo.placed_towers.get_child_count() == 1, "Click places a tower")
	_check(not demo.can_place_at(Vector3(-7, 0, 8)), "Towers cannot overlap")
	demo.place_tower(Vector3(-7, 0, 8))
	_check(demo.placed_towers.get_child_count() == 1, "Invalid placement creates no tower")
	demo.place_tower(Vector3(8, 0, 8))
	_check(demo.placed_towers.get_child_count() == 2, "Selection remains active for repeated placement")
	var second_pivot: Node3D = demo.placed_towers.get_child(1).get_node("TurretPivot")
	_check(second_pivot.get_child_count() == 3, "Placed double tower uses shared visual")

	if failures == 0:
		print("Tower placement tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
