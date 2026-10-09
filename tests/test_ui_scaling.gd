extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var ui_scale: Node = root.get_node("UiScale")
	var scene := load("res://scenes/tower_placement.tscn") as PackedScene
	var garden := scene.instantiate()
	root.add_child(garden)
	current_scene = garden
	await process_frame

	root.size = Vector2i(1489, 648)
	ui_scale._update_scale()
	var small_factor := root.content_scale_factor
	var small_palette_width: float = garden.palette.size.x * root.get_stretch_transform().get_scale().x

	root.size = Vector2i(3399, 1815)
	ui_scale._update_scale()
	await process_frame
	var large_factor := root.content_scale_factor
	var large_palette_width: float = garden.palette.size.x * root.get_stretch_transform().get_scale().x

	if not is_equal_approx(small_factor, 1.0):
		push_error("Small embedded viewport should keep the design UI scale")
		quit(1)
		return
	if not large_factor < small_factor or not large_palette_width < small_palette_width * 2.0:
		push_error("Large viewport should grow the HUD gradually")
		quit(1)
		return
	if garden.enemy_panel.position.y + garden.enemy_panel.size.y >= root.get_visible_rect().size.y:
		push_error("Battle sidebar should not fill a tall viewport")
		quit(1)
		return
	print("UI scaling and sidebar layout passed")
	quit()
