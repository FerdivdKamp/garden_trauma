extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var progress = root.get_node("LevelProgress")
	progress.save_path = "res://tests/.tower_progression_test.cfg"
	progress.completed_ids.clear()
	_check(progress.is_unlocked("tower_test") and progress.is_unlocked("garden_test_01"), "Test level and first garden start unlocked")
	_check(not progress.is_unlocked("garden_test_02") and progress.next_level_id("tower_test") == "", "Test level is outside campaign progression")
	_check(progress.is_tower_unlocked("laser_tower") and not progress.is_tower_unlocked("lightning_tower"), "Fresh progress starts with laser only")
	progress.selected_level_id = "garden_test_01"
	var garden = (load("res://scenes/tower_placement.tscn") as PackedScene).instantiate()
	root.add_child(garden)
	_check(not garden.tower_buttons[0].disabled and garden.tower_buttons[2].disabled, "Normal level disables locked tower")
	garden._select_tower(2)
	garden.place_tower(Vector3(-10, 0, -1))
	_check(garden.selected_type == -1 and garden.placed_towers.get_child_count() == 0, "Locked tower cannot be selected or placed")
	var normal_price: int = garden.tower_definitions["laser_tower"].cost
	var normal_upgrade: int = garden.tower_definitions["laser_tower"].upgrades[0].cost
	garden.queue_free()
	await process_frame
	progress.selected_level_id = "tower_test"
	var test_level = (load("res://scenes/tower_placement.tscn") as PackedScene).instantiate()
	root.add_child(test_level)
	_check(test_level.grid.level_file.ends_with("tower_test.json") and test_level.waves.schedule_file.ends_with("tower_test.json"), "Test level loads its copied map and waves")
	for index in test_level.TOWER_IDS.size():
		var definition = test_level.tower_definitions[test_level.TOWER_IDS[index]]
		_check(not test_level.tower_buttons[index].disabled and definition.cost == 1, "Test tower %s is available for one credit" % definition.id)
		for upgrade in definition.upgrades:
			_check(upgrade.cost == 1, "Test upgrades cost one credit")
	test_level._select_tower(0)
	var before: int = test_level.currency
	test_level.place_tower(Vector3(-10, 0, -1))
	var placed = test_level.placed_towers.get_child(0)
	test_level._select_placed_tower(placed)
	test_level._buy_selected_upgrade()
	_check(test_level.currency == before - 2 and placed.get_node("Attack").upgrade_level == 1, "Test placement and upgrade each deduct one credit")
	test_level._finish_battle("victory")
	_check(not progress.is_completed("tower_test") and not progress.is_tower_unlocked("lightning_tower"), "Test victory grants no campaign progress")
	test_level.queue_free()
	await process_frame
	progress.selected_level_id = "garden_test_01"
	garden = (load("res://scenes/tower_placement.tscn") as PackedScene).instantiate()
	root.add_child(garden)
	_check(garden.tower_definitions["laser_tower"].cost == normal_price and garden.tower_definitions["laser_tower"].upgrades[0].cost == normal_upgrade, "Test prices do not leak into campaign")
	garden._finish_battle("victory")
	_check(progress.is_tower_unlocked("lightning_tower") and progress.is_unlocked("garden_test_02"), "Garden 1 victory unlocks lightning and Garden 2")
	_check(garden.get_node("UI/ResultOverlay/Center/Panel/Actions/Title").text.contains("Lightning Tower"), "Victory announces the new tower")
	progress.completed_ids.clear()
	progress.load_progress()
	_check(progress.is_tower_unlocked("lightning_tower"), "Unlock survives reload using completed levels")
	garden.queue_free()
	await process_frame
	garden = (load("res://scenes/tower_placement.tscn") as PackedScene).instantiate()
	root.add_child(garden)
	_check(not garden.tower_buttons[2].disabled, "Unlocked tower is available on a Garden 1 replay")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(progress.save_path))
	if failures == 0:
		print("Tower progression tests passed")
	quit(1 if failures else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
