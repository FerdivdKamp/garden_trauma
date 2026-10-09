extends SceneTree

# Run with Godot from the project root to inspect tile geometry and lighting
# without the grass color shader: godot --path . --script res://tools/render_flat_grass.gd
const OUTPUT := "res://.godot/grass_three_tile_flat.png"
const PLACEMENT_PATH := "res://scenes/tower_placement.tscn"


func _initialize() -> void:
	_render.call_deferred()


func _render() -> void:
	var placement := load(PLACEMENT_PATH) as PackedScene
	if placement == null:
		push_error("Could not load placement scene")
		quit(1)
		return
	var scene := placement.instantiate()
	root.add_child(scene)
	await process_frame
	var grid := scene.get_node("LevelGrid") as LevelGrid
	var dressing := grid.get_node_or_null("Dressing")
	if dressing != null:
		dressing.visible = false
	var flat := StandardMaterial3D.new()
	flat.albedo_color = Color("67ad45")
	flat.roughness = 1.0
	var changed := 0
	for tile in grid.get_children():
		if tile is GrassTileVisual:
			changed += _replace_grass_top(tile.get_node("GrassVisual"), flat)
	if changed == 0:
		push_error("No GrassTop surfaces found")
		quit(1)
		return
	for frame in 5:
		await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("No rendered image available; run with a graphics display")
		quit(1)
		return
	var result := image.save_png(OUTPUT)
	if result != OK:
		push_error("Could not save diagnostic image: %s" % error_string(result))
		quit(1)
		return
	print("Saved %s (%d grass surfaces)" % [ProjectSettings.globalize_path(OUTPUT), changed])
	quit()


func _replace_grass_top(node: Node, flat: Material) -> int:
	var count := 0
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		for index in instance.mesh.get_surface_count():
			var original := instance.mesh.surface_get_material(index)
			if original != null and original.resource_name == "GrassTop":
				instance.set_surface_override_material(index, flat)
				count += 1
	for child in node.get_children():
		count += _replace_grass_top(child, flat)
	return count
