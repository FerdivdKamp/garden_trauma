extends SceneTree

const PlacementEnemy = preload("res://scripts/placement_enemy.gd")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# The headless test runs in a restricted workspace; keep its save isolated.
	var progress: Variant = root.get_node("LevelProgress")
	progress.save_path = "res://tests/.basic_game_loop_progress.cfg"
	progress.completed_ids.clear()
	progress.selected_level_id = "garden_test_01"
	var scene := load("res://scenes/tower_placement.tscn") as PackedScene
	var garden := scene.instantiate()
	root.add_child(garden)
	current_scene = garden
	await process_frame
	_check(garden.waves.waves.size() == 3 and garden.waves.current_wave == -1, "Three waves wait for player input")
	_check(garden.path.get_child_count() == 1 and garden.enemy_selector == null, "Normal play starts without manual enemies or debug controls")
	_check(garden.objective_health == 10 and garden.currency == 240, "Level starts with health and coins")

	garden._select_tower(0)
	var tower_cost: int = garden.tower_definitions["laser_tower"].cost
	garden.place_tower(Vector3(-10, 0, -1))
	_check(garden.placed_towers.get_child_count() == 1 and garden.currency == 240 - tower_cost, "Tower purchase deducts its cost")
	garden._select_tower(2)
	garden.currency = (garden.tower_definitions["lightning_tower"] as TowerDefinition).cost - 1
	var before_unaffordable: int = garden.currency
	garden.place_tower(Vector3(-8, 0, -1))
	_check(garden.placed_towers.get_child_count() == 1 and garden.currency == before_unaffordable, "Unaffordable tower cannot be placed")

	garden.pause_button.pressed.emit()
	_check(paused and garden.pause_overlay.visible and garden.pause_overlay.process_mode == Node.PROCESS_MODE_ALWAYS, "Pause freezes the game and keeps menu active")
	garden._resume_battle()
	_check(not paused and not garden.pause_overlay.visible, "Resume returns to play")

	for wave_index in garden.waves.waves.size():
		if wave_index == 0:
			garden.next_wave_button.pressed.emit()
			_check(garden.waves.state == WaveController.State.SPAWNING, "Start wave button begins wave 1")
			garden.waves._process(0.0)
			_check(garden.waves.active_enemies == 1 and garden.waves.remaining_to_spawn == 4, "First enemy spawns at wave start")
			garden.waves._process(1.0)
			_check(garden.waves.active_enemies == 1, "Spawn spacing delays the next enemy")
			garden.waves._process(0.6)
			_check(garden.waves.active_enemies == 2, "Next enemy spawns after the interval")
		else:
			_check(garden.waves.start_next_wave(), "Wave %d starts" % [wave_index + 1])
		garden.waves._process(100.0)
		_check(garden.waves.remaining_to_spawn == 0, "Wave %d spawns its full schedule" % [wave_index + 1])
		var live: Array[PlacementEnemy] = []
		for child in garden.path.get_children():
			var enemy := child as PlacementEnemy
			if enemy != null and enemy.health > 0.0:
				live.append(enemy)
		_check(live.size() == int(garden.waves.waves[wave_index].count), "Wave %d has the scheduled enemy count" % [wave_index + 1])
		var first := live[0]
		var reward: int = first.definition.reward
		var currency_before: int = garden.currency
		first.take_damage(1000.0)
		first.take_damage(1000.0)
		_check(garden.currency == currency_before + reward, "Enemy reward is paid once")
		_check(not first.visual.visible, "Defeated enemy hides while its sound finishes")
		if wave_index == 0:
			await first.destroyed_audio.finished
			await process_frame
			_check(not is_instance_valid(first), "Defeated enemy is removed after its sound")
		for index in range(1, live.size()):
			live[index].take_damage(1000.0)
		_check(garden.waves.active_enemies == 0, "Wave %d resolves all enemies" % [wave_index + 1])
		if wave_index < garden.waves.waves.size() - 1:
			_check(garden.waves.state == WaveController.State.INTERMISSION and garden.next_wave_button.disabled, "Break follows wave %d" % [wave_index + 1])
			garden.waves._process(100.0)
			_check(garden.waves.state == WaveController.State.READY and not garden.next_wave_button.disabled, "Next wave becomes available")
	_check(garden.battle_result == "victory" and garden.result_overlay.visible, "Final wave produces victory")
	_check(not garden.waves.start_next_wave(), "Victory prevents further waves")
	_check(not garden.placed_towers.get_child(0).get_node("Attack").is_processing(), "Victory stops tower attacks")

	garden.get_node("UI/ResultOverlay/Center/Panel/Actions/Restart").pressed.emit()
	await process_frame
	await process_frame
	var restarted := current_scene
	_check(restarted != null and restarted.scene_file_path == "res://scenes/tower_placement.tscn", "Retry reloads the level")
	_check(restarted.currency == restarted.starting_currency and restarted.objective_health == restarted.starting_objective_health and restarted.waves.current_wave == -1, "Retry resets battle state")
	restarted.objective_health = 1
	restarted.waves.start_next_wave()
	restarted.waves._process(0.0)
	var escaping := restarted.path.get_node("Enemy1") as PlacementEnemy
	escaping.progress = restarted.path.curve.get_baked_length() - 0.5
	escaping._process(1.0)
	_check(restarted.objective_health == 0 and restarted.battle_result == "defeat", "Enemy reaching objective can lose the level")
	escaping._process(1.0)
	_check(restarted.objective_health == 0, "Objective damage occurs only once per enemy")
	_check(restarted.result_overlay.visible and restarted.waves.state == WaveController.State.DONE, "Defeat stops the battle")
	await escaping.objective_audio.finished
	await process_frame
	_check(not is_instance_valid(escaping), "Escaped enemy is removed after its sound")
	restarted.get_node("UI/ResultOverlay/Center/Panel/Actions/MainMenu").pressed.emit()
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/main_menu.tscn" and not paused, "Result returns to main menu")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(progress.save_path))
	if failures == 0:
		print("Basic game loop tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
