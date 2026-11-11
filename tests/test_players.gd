extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var progress = root.get_node("LevelProgress")
	var test_dir := "res://.godot/player_test_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_dir))
	progress.players_directory = test_dir.path_join("players")
	progress.players_index_path = test_dir.path_join("players.cfg")
	progress.legacy_save_path = test_dir.path_join("progress.cfg")
	progress.load_players()
	var legacy := ConfigFile.new()
	legacy.set_value("levels", "completed_ids", ["garden_test_01"])
	_check(legacy.save(progress.legacy_save_path) == OK, "Prepare old-format save")
	var menu = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.get_node("Center/Menu/Start").pressed.emit()
	_check(menu.player_panel.visible and menu.get_node("Center/PlayerPanel/Contents/Import").visible, "Player selection offers previous-game import")
	menu.player_name_input.text = "Alice"
	menu.get_node("Center/PlayerPanel/Contents/Create").pressed.emit()
	await process_frame
	await process_frame
	_check(current_scene.scene_file_path == "res://scenes/level_select.tscn" and progress.active_player_name == "Alice", "Creating a player opens level selection")
	_check(not progress.is_completed("garden_test_01"), "New game starts without legacy progress")
	var alice_id: String = progress.active_player_id
	progress.complete_level("garden_test_01")
	_check(progress.is_tower_unlocked("lightning_tower"), "Alice earns the first unlock")
	_check(progress.create_player("Bob") == "", "Create a second player")
	var bob_id: String = progress.active_player_id
	_check(not progress.is_completed("garden_test_01") and not progress.is_tower_unlocked("lightning_tower"), "Bob starts independently")
	_check(progress.create_player("  ALICE  ") != "", "Duplicate names are rejected")
	_check(progress.create_player("  ") != "", "Blank names are rejected")
	_check(progress.select_player(alice_id) and progress.is_completed("garden_test_01"), "Switching back restores Alice's progress")
	_check(progress.create_player("Previous", true) == "", "Import previous progress as its own player")
	_check(progress.is_completed("garden_test_01") and not progress.has_legacy_save(), "Import copies completion and cannot be repeated")
	var imported_id: String = progress.active_player_id
	progress.load_players()
	_check(progress.players.size() == 3 and progress.select_player(bob_id) and not progress.is_completed("garden_test_01"), "Player list and independent progress survive reload")
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	menu = current_scene
	menu.get_node("Center/Menu/Start").pressed.emit()
	var alice_button: Button = menu.player_list.get_child(0)
	_check(alice_button.text.contains("Alice"), "Player chooser shows existing names")
	alice_button.pressed.emit()
	await process_frame
	await process_frame
	_check(progress.active_player_name == "Alice" and progress.is_completed("garden_test_01"), "Continue button loads the selected player's progress")
	var untouched := ConfigFile.new()
	_check(untouched.load(progress.legacy_save_path) == OK and untouched.get_value("levels", "completed_ids", []).has("garden_test_01"), "Legacy save remains intact")
	for id in [alice_id, bob_id, imported_id]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(progress.players_directory.path_join(id + ".cfg")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(progress.players_directory))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(progress.players_index_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(progress.legacy_save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_dir))
	if failures == 0:
		print("Player selection tests passed")
	quit(1 if failures else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
