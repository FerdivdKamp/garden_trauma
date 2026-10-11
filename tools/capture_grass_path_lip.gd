extends SceneTree

# Godot --path . --script res://tools/capture_grass_path_lip.gd
# Requires a graphical renderer; saves both views from the same camera.
const OUTPUT_DIR := "res://examples/renders"


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	root.size = Vector2i(1400, 900)
	var study := (load("res://examples/grass_path_lip.tscn") as PackedScene).instantiate()
	root.add_child(study)
	current_scene = study
	for frame in 8:
		await process_frame
	study.get_node("Edges").visible = false
	study.get_node("Blades").visible = false
	await process_frame
	await process_frame
	_save(OUTPUT_DIR + "/01_raised_tiles_only.png")
	study.get_node("Edges").visible = true
	study.get_node("Blades").visible = true
	await process_frame
	await process_frame
	_save(OUTPUT_DIR + "/02_grass_lip_sparse_blades.png")
	var camera := study.get_node("Camera") as Camera3D
	camera.position = Vector3(6.5, 8.0, 8.5)
	camera.look_at(Vector3(0.5, 0.0, 0.5), Vector3.UP)
	camera.size = 6.5
	study.get_node("Edges").visible = false
	study.get_node("Blades").visible = false
	await process_frame
	await process_frame
	_save(OUTPUT_DIR + "/03_raised_tiles_only_close.png")
	study.get_node("Edges").visible = true
	study.get_node("Blades").visible = true
	await process_frame
	await process_frame
	_save(OUTPUT_DIR + "/04_grass_lip_sparse_blades_close.png")
	quit()


func _save(path: String) -> void:
	var image := root.get_texture().get_image()
	if image == null:
		push_error("A graphical renderer is needed for this capture")
		quit(1)
		return
	var result := image.save_png(path)
	if result != OK:
		push_error("Could not save %s: %s" % [path, error_string(result)])
		quit(1)
		return
	print("Saved " + ProjectSettings.globalize_path(path))
