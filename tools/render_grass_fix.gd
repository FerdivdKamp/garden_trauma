extends SceneTree

# Capture the playable Garden with its regular materials after grass changes.
const OUTPUT := "res://.godot/grass_material_world_noise.png"
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
	for frame in 6:
		await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("No rendered image available; run with a graphics display")
		quit(1)
		return
	var result := image.save_png(OUTPUT)
	if result != OK:
		push_error("Could not save render: %s" % error_string(result))
		quit(1)
		return
	print("Saved " + ProjectSettings.globalize_path(OUTPUT))
	quit()
