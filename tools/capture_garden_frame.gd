extends SceneTree

# Run with: godot --path . --script res://tools/capture_garden_frame.gd
# The scene is captured at its actual gameplay camera and Mobile renderer.
func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene: Node = load("res://scenes/tower_placement.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.set("selected_type", 0)
	scene.call("place_tower", Vector3(8, 0, -1))
	scene.call("place_tower", Vector3(12, 0, 5))
	scene.call("spawn_enemy")
	await create_timer(2.0).timeout
	_save_frame("res://docs/reference/garden_camera_16_9.png")
	root.size = Vector2i(1200, 900)
	await create_timer(0.5).timeout
	_save_frame("res://docs/reference/garden_camera_4_3.png")
	quit()


func _save_frame(output: String) -> void:
	var image := root.get_texture().get_image()
	if image == null:
		push_error("A graphical renderer is required to capture the frame")
		return
	var error := image.save_png(output)
	if error != OK:
		push_error("Could not save camera frame: %s" % error_string(error))
	else:
		print("Saved %s (%s)" % [output, image.get_size()])
