extends SceneTree

const Grid = preload("res://scripts/level_grid.gd")
const GrassTile = preload("res://scenes/tiles/tile_grass.tscn")
const PathTile = preload("res://scenes/tiles/tile_path.tscn")
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var grid := Grid.new()
	root.add_child(grid)
	await process_frame
	_check(grid.error_message.is_empty(), "Example level loads")
	_check(grid.width == 20 and grid.height == 20 and grid.get_node("Tile_19_19") != null, "20x20 tiles render")
	var grass_tile := grid.get_node("Tile_5_5") as GrassTileVisual
	var original_variant := grass_tile.variant_index
	var original_turns := grass_tile.quarter_turns
	var original_seed := grass_tile.visual_seed
	var path_tile := grid.get_node("Tile_5_7") as PathTileVisual
	var path_variant := path_tile.variant_index
	var path_turns := path_tile.quarter_turns
	var path_seed := path_tile.visual_seed
	_check(original_seed == grid.visual_seed_for(Vector2i(5, 5)), "Grass seed derives from level seed and coordinates")
	_check(path_seed == grid.visual_seed_for(Vector2i(5, 7)), "Path seed derives from level seed and coordinates")
	_check(original_variant >= 0 and original_variant < 3 and original_turns >= 0 and original_turns < 4, "Grass uses one of three variants and quarter turns")
	var dressing := grid.get_node("Dressing") as LevelDressing
	var original_dressing := _dressing_snapshot(dressing)
	_check(not original_dressing.is_empty(), "Grass tiles receive dressing")
	_check(dressing.get_node_or_null("Cell_5_7") == null, "Path tiles receive no grass dressing")
	var dressing_config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(grid.dressing_file))
	var seen_dressing_types := {}
	for holder: Node in dressing.get_children():
		for instance: Node in holder.get_children():
			var decoration := instance as Node3D
			for entry: Dictionary in dressing_config.types:
				if not decoration.name.begins_with(str(entry.id) + "_"):
					continue
				seen_dressing_types[entry.id] = true
				var limit: float = LevelGrid.TILE_SIZE * 0.5 - float(entry.get("edge_margin", 0.2))
				_check(absf(decoration.position.x) <= limit and absf(decoration.position.z) <= limit, "%s pivot stays within its grass cell margin" % entry.id)
				break
	_check(seen_dressing_types.size() == 6, "All six Garden dressing assets appear in the example level")
	_check(grid.load_level(grid.level_file), "Level reloads")
	dressing = grid.get_node("Dressing") as LevelDressing
	_check(_dressing_snapshot(dressing) == original_dressing, "Level reload reproduces dressing positions")
	var occupied_cell := dressing.get_child(0) as Node3D
	var tuft_mesh := _find_mesh(occupied_cell)
	var tuft_material := tuft_mesh.mesh.surface_get_material(0) as BaseMaterial3D if tuft_mesh != null else null
	_check(tuft_material != null and tuft_material.cull_mode == BaseMaterial3D.CULL_DISABLED, "Grass tuft renders both sides")
	var occupied_name := occupied_cell.name
	var coordinates := occupied_name.trim_prefix("Cell_").split("_")
	dressing.clear_cell(Vector2i(int(coordinates[0]), int(coordinates[1])))
	_check(dressing.get_node_or_null(NodePath(occupied_name)) == null, "Tower placement can clear dressing from its cell")
	grass_tile = grid.get_node("Tile_5_5") as GrassTileVisual
	path_tile = grid.get_node("Tile_5_7") as PathTileVisual
	_check(grass_tile.visual_seed == original_seed and grass_tile.variant_index == original_variant and grass_tile.quarter_turns == original_turns, "Level reload reproduces grass visuals")
	_check(path_tile.visual_seed == path_seed and path_tile.variant_index == path_variant and path_tile.quarter_turns == path_turns, "Level reload reproduces path visuals")
	var seen_variants := {}
	var seen_rotations := {}
	for seed in 32:
		var sample := GrassTile.instantiate() as GrassTileVisual
		sample.visual_seed = seed
		root.add_child(sample)
		seen_variants[sample.variant_index] = true
		seen_rotations[sample.quarter_turns] = true
		root.remove_child(sample)
		sample.queue_free()
	_check(seen_variants.size() == 3 and seen_rotations.size() == 4, "Different seeds can select every grass variant and rotation")
	seen_variants.clear()
	seen_rotations.clear()
	for seed in 32:
		var sample := PathTile.instantiate() as PathTileVisual
		sample.visual_seed = seed
		root.add_child(sample)
		seen_variants[sample.variant_index] = true
		seen_rotations[sample.quarter_turns] = true
		root.remove_child(sample)
		sample.queue_free()
	_check(seen_variants.size() == 4 and seen_rotations.size() == 4, "Different seeds can select every path variant and rotation")
	grid.visual_seeds["5,5"] = 73
	_check(grid.visual_seed_for(Vector2i(5, 5)) == 73 and grid.is_buildable(Vector2i(5, 5)), "Tile seed override changes only visual state")
	grid.visual_seeds["5,7"] = 74
	_check(grid.visual_seed_for(Vector2i(5, 7)) == 74 and grid.is_walkable(Vector2i(5, 7)), "Path seed override preserves route rules")
	var grass_visual := grid.get_node("Tile_5_5/GrassVisual") as Node3D
	var grass_mesh := _find_mesh(grass_visual)
	_check(is_equal_approx(grass_visual.position.y, -0.25), "Grass side top aligns with the Y=0 ground plane")
	_check(grass_mesh != null and is_equal_approx(grass_mesh.mesh.get_aabb().size.x, 2.0) and is_equal_approx(grass_mesh.mesh.get_aabb().size.z, 2.0), "Imported grass keeps its 2x2 footprint")
	var path_visual := grid.get_node("Tile_5_7/PathVisual") as Node3D
	var path_mesh := _find_mesh(path_visual)
	_check(is_equal_approx(path_visual.position.y, -0.25), "Path side top aligns with the Y=0 ground plane")
	_check(path_mesh != null and is_equal_approx(path_mesh.mesh.get_aabb().size.x, 2.0) and is_equal_approx(path_mesh.mesh.get_aabb().size.z, 2.0), "Imported path keeps its 2x2 footprint")
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
	data.level_seed = -1
	_check(grid._validate(data).contains("level_seed"), "Invalid level seed reports a clear error")
	data.level_seed = grid.level_seed
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


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child: Node in node.get_children():
		var mesh: MeshInstance3D = _find_mesh(child)
		if mesh != null:
			return mesh
	return null


func _dressing_snapshot(dressing: LevelDressing) -> Array[String]:
	var snapshot: Array[String] = []
	for holder: Node in dressing.get_children():
		for tuft: Node in holder.get_children():
			snapshot.append("%s/%s:%s" % [holder.name, tuft.name, (tuft as Node3D).transform])
	return snapshot
