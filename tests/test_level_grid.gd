extends SceneTree

const Grid = preload("res://scripts/level_grid.gd")
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var grid := Grid.new()
	root.add_child(grid)
	await process_frame
	_check(grid.error_message.is_empty(), "Example level loads")
	_check(grid.width == 20 and grid.height == 20 and grid.get_node("Tile_19_19") != null, "20x20 tiles render")
	var grass_mesh := grid.get_node("Tile_5_5/Ground") as MeshInstance3D
	_check(grass_mesh.mesh is BoxMesh and grass_mesh.mesh.size.is_equal_approx(Vector3(2, 0.2, 2)) and is_equal_approx(grass_mesh.position.y, -0.1), "Tile footprint and top surface match the design")
	_check(grid.grid_to_world(Vector2i(0, 0)) == Vector3(-19, 0, -19), "Even grid centers on origin")
	_check(grid.grid_to_world(Vector2i(1, 0)) == Vector3(-17, 0, -19), "Grid step is 2 meters")
	_check(grid.world_to_grid(Vector3(-19, 0, -19)) == Vector2i.ZERO, "World converts back to grid")
	_check(grid.is_buildable(Vector2i(5, 5)) and not grid.is_walkable(Vector2i(5, 5)), "Grass is buildable")
	_check(not grid.is_buildable(Vector2i(5, 7)) and grid.is_walkable(Vector2i(5, 7)), "Sand is path only")
	_check(not grid.is_buildable(Vector2i(5, 4)) and not grid.is_walkable(Vector2i(5, 4)), "Rock is blocked")
	_check(grid.get_node("SPAWN") != null and grid.get_node("GOAL") != null, "Markers are visible")
	_check(grid.route[0] == grid.spawn and grid.route[-1] == grid.objective, "Route joins spawn and goal")
	grid.show_grid = true
	grid.show_coordinates = true
	grid.show_route = true
	_check(grid.get_node("GridOverlay") != null and grid.get_node("Coordinates") != null and grid.get_node("RouteOverlay") != null, "Debug overlays can be enabled")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(grid.level_file))
	data.route[1] = [3, 7]
	_check(grid._validate(data).contains("orthogonally adjacent"), "Nonadjacent route reports a clear error")
	data.route[1] = [2, 7]
	data.tiles[4] = "....?##............."
	_check(grid._validate(data).contains("unknown terrain"), "Unknown terrain reports a clear error")
	if failures == 0:
		print("Level grid tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
