extends SceneTree

# Capture the playable fence at the reference image's size for comparison.
const OUTPUT := "res://docs/reference/fence_height4_horizontal2_render.png"
const PLACEMENT_PATH := "res://scenes/tower_placement.tscn"


func _initialize() -> void:
	_render.call_deferred()


func _render() -> void:
	root.size = Vector2i(1448, 1086)
	var scene := (load(PLACEMENT_PATH) as PackedScene).instantiate()
	root.add_child(scene)
	var border := scene.get_node("LevelGrid/Border") as Node3D
	if border.get_child_count() != 40:
		push_error("Expected two-cell fence sections on four 20-cell sides")
		quit(1)
		return
	for frame in 8:
		await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.save_png(OUTPUT) != OK:
		push_error("Could not save the current fence render")
		quit(1)
		return
	print("Saved " + ProjectSettings.globalize_path(OUTPUT))
	quit()
