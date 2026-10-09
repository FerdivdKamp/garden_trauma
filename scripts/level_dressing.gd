class_name LevelDressing
extends Node3D

# Dressing is visual only. The grid owns terrain and placement rules.
const EDGE_MARGIN := 0.2


func build(grid: LevelGrid, config_path: String) -> void:
	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_warning("Cannot read dressing config: " + config_path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.get("types") is Array:
		push_warning("Dressing config needs a types array: " + config_path)
		return
	for type_index in parsed.types.size():
		var entry: Variant = parsed.types[type_index]
		if not _valid_entry(entry):
			push_warning("Invalid dressing entry %d in %s" % [type_index, config_path])
			continue
		var scene: PackedScene = load(entry.scene) as PackedScene
		if scene == null:
			push_warning("Cannot load dressing scene: " + entry.scene)
			continue
		for z in grid.height:
			for x in grid.width:
				var cell := Vector2i(x, z)
				if grid.terrain_at(cell) != "grass":
					continue
				# Each type has a separate stream, so adding pebbles does not
				# reposition existing grass tufts.
				var rng := RandomNumberGenerator.new()
				rng.seed = grid.visual_seed_for(cell) + (str(entry.id).hash() & 0x7fffffff)
				if rng.randf() > float(entry.chance):
					continue
				var count := rng.randi_range(int(entry.min_per_tile), int(entry.max_per_tile))
				var holder := get_node_or_null("Cell_%d_%d" % [x, z]) as Node3D
				if holder == null:
					holder = Node3D.new()
					holder.name = "Cell_%d_%d" % [x, z]
					holder.position = grid.grid_to_world(cell)
					add_child(holder)
				for index in count:
					var instance := scene.instantiate() as Node3D
					instance.name = "%s_%d" % [entry.id, index]
					# Keep the full rotated mesh inside its grass cell, especially
					# beside sand paths. Larger pebble groups need a wider margin.
					var margin := float(entry.get("edge_margin", EDGE_MARGIN))
					var limit := LevelGrid.TILE_SIZE * 0.5 - margin
					instance.position = Vector3(rng.randf_range(-limit, limit), float(entry.height_offset), rng.randf_range(-limit, limit))
					instance.rotation.y = rng.randf_range(0.0, TAU)
					instance.scale = Vector3.ONE * rng.randf_range(float(entry.scale_min), float(entry.scale_max))
					holder.add_child(instance)


func clear_cell(cell: Vector2i) -> void:
	var holder := get_node_or_null("Cell_%d_%d" % [cell.x, cell.y])
	if holder != null:
		remove_child(holder)
		holder.queue_free()


func _valid_entry(entry: Variant) -> bool:
	if not entry is Dictionary:
		return false
	for key in ["id", "scene"]:
		if not entry.get(key) is String or str(entry[key]).is_empty():
			return false
	for key in ["chance", "scale_min", "scale_max", "height_offset"]:
		if not entry.get(key) is float and not entry.get(key) is int:
			return false
	for key in ["min_per_tile", "max_per_tile"]:
		if not entry.get(key) is float and not entry.get(key) is int:
			return false
	if entry.chance < 0.0 or entry.chance > 1.0 or entry.min_per_tile < 0 or entry.max_per_tile < entry.min_per_tile:
		return false
	if entry.scale_min <= 0.0 or entry.scale_max < entry.scale_min:
		return false
	var margin: Variant = entry.get("edge_margin", EDGE_MARGIN)
	if not margin is float and not margin is int:
		return false
	if margin < 0.0 or margin > LevelGrid.TILE_SIZE * 0.5:
		return false
	return int(entry.min_per_tile) == entry.min_per_tile and int(entry.max_per_tile) == entry.max_per_tile
