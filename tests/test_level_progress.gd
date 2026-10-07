extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var progress: Variant = root.get_node("LevelProgress")
	progress.save_path = "res://tests/.level_progress_test.cfg"
	progress.completed_ids.clear()
	progress.selected_level_id = "garden_test_01"
	_check(progress.is_unlocked("garden_test_01") and not progress.is_unlocked("garden_test_02"), "Only the first level starts unlocked")
	_check(not progress.select_level("garden_test_02"), "Locked level cannot be selected")

	var menu: Node = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.get_node("Center/Menu/Start").pressed.emit()
	await process_frame
	await process_frame
	_check(current_scene.scene_file_path == "res://scenes/level_select.tscn", "Start opens level selection")
	var selection := current_scene
	var level_buttons := selection.get_node("Center/Panel/Content/Levels")
	_check(not level_buttons.get_child(0).disabled and level_buttons.get_child(1).disabled, "Selection shows the unlock rule")
	level_buttons.get_child(0).pressed.emit()
	await process_frame
	await process_frame
	var garden := current_scene
	_check(garden.level_id == "garden_test_01" and garden.grid.level_file == "res://levels/data/garden_test_01.json", "First level loads its map")
	_check(garden.waves.schedule_file == "res://levels/waves/garden_test_01.json", "First level loads its waves")
	var first_route_size: int = garden.grid.route.size()
	garden._finish_battle("victory")
	_check(progress.is_completed("garden_test_01") and progress.is_unlocked("garden_test_02"), "Victory saves completion and unlocks level 2")
	_check(garden.result_action_button.text == "Next level", "Victory offers the next level")
	progress.completed_ids.clear()
	progress.load_progress()
	_check(progress.is_completed("garden_test_01"), "Completion survives loading from disk")
	garden.result_action_button.pressed.emit()
	await process_frame
	await process_frame
	var second := current_scene
	_check(second.level_id == "garden_test_02" and second.grid.level_file == "res://levels/data/garden_test_02.json", "Next level loads its own map")
	_check(second.grid.error_message == "" and second.grid.route.size() > first_route_size, "Second map has a valid, distinct route")
	_check(second.waves.schedule_file == "res://levels/waves/garden_test_02.json" and second.waves.waves.size() == 3, "Second level loads its own waves")
	for wave_index in second.waves.waves.size():
		_check(second.waves.start_next_wave(), "Garden 2 wave %d starts" % [wave_index + 1])
		second.waves._process(100.0)
		for child in second.path.get_children():
			if child.has_method("take_damage") and child.health > 0.0:
				child.take_damage(1000.0)
		if wave_index < second.waves.waves.size() - 1:
			second.waves._process(100.0)
	_check(second.battle_result == "victory" and progress.is_completed("garden_test_02"), "Clearing Garden 2 saves its completion")
	_check(second.result_action_button.text == "Level selection", "Final victory offers level selection")
	second.result_action_button.pressed.emit()
	await process_frame
	await process_frame
	_check(current_scene.scene_file_path == "res://scenes/level_select.tscn", "Final victory returns to selection")
	level_buttons = current_scene.get_node("Center/Panel/Content/Levels")
	_check(level_buttons.get_child(0).text.contains("Completed") and level_buttons.get_child(1).text.contains("Completed"), "Selection shows completed levels")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(progress.save_path))
	if failures == 0:
		print("Level progression tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
