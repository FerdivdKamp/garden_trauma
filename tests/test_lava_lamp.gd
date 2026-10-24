extends SceneTree

const PlacementEnemy = preload("res://scripts/placement_enemy.gd")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var definition := DefinitionLoader.load_tower("res://data/towers/lava_lamp.json")
	_check(definition != null and definition.firing_mode == "tile", "Lava definition loads")
	var scene := load("res://scenes/tower_placement.tscn") as PackedScene
	var garden := scene.instantiate()
	root.add_child(garden)
	garden._select_tower(5)
	garden.place_tower(Vector3(-8, 0, 8))
	_check(garden.placed_towers.get_child_count() == 1, "Lava lamp can be placed")
	var tower := garden.placed_towers.get_child(0) as Node3D
	var attack := tower.get_node("Attack")
	_check(tower.lava_model != null and tower.lava_model.muzzle != null, "Placeholder has a working muzzle")
	garden._select_placed_tower(tower)
	_check(garden.upgrade_panel.visible, "Lava lamp can be selected and upgraded")
	var first_upgrade: Dictionary = attack.next_upgrade()
	_check(attack.buy_next_upgrade(int(first_upgrade.cost)) > 0, "Lava upgrade uses the shared upgrade flow")

	# Stop automatic spawns so the same tile stays occupied throughout this test.
	garden.waves.set_process(false)
	garden.waves.state = WaveController.State.SPAWNING
	garden.waves.state_changed.emit()
	var route_index := _nearby_route_index(garden.grid, tower.global_position, attack.definition.attack_range)
	_check(route_index >= 0, "Map has a reachable route tile")
	if route_index < 0:
		quit(1)
		return
	var cell: Vector2i = garden.grid.route[route_index]
	var enemy := garden.spawn_enemy(0, false) as PlacementEnemy
	enemy.set_process(false)
	enemy.progress = float(route_index) * garden.grid.TILE_SIZE
	var second := garden.spawn_enemy(0, false) as PlacementEnemy
	second.set_process(false)
	second.progress = enemy.progress
	_check(attack.choose_target_cell(tower.global_position) == cell, "Targets an occupied path tile")
	var original_range: float = attack.definition.attack_range
	attack.definition.attack_range = 0.1
	_check(attack.choose_target_cell(tower.global_position) == Vector2i(-1, -1), "Rejects path tiles outside range")
	attack.definition.attack_range = original_range
	attack.shot_clock = attack.definition.cooldown
	attack._process(0.01)
	_check(garden.lava_field.pending.has(cell), "One projectile reserves the target tile")
	_check(attack.choose_target_cell(tower.global_position) == Vector2i(-1, -1), "Does not retarget a covered tile")
	var projectile := garden.lava_field.get_node("LavaProjectile") as LavaProjectile
	_check(projectile != null and projectile.cell == cell, "Projectile aims at the tile")
	projectile._process(2.0)
	_check(garden.lava_field.puddles.size() == 1, "Impact creates one puddle")
	_check(enemy.health < enemy.max_health and second.health < second.max_health, "Impact damages both enemies")
	var before: float = enemy.health
	var second_before: float = second.health
	garden.lava_field._physics_process(0.25)
	garden.lava_field._physics_process(0.25)
	_check(second.health < second_before, "The same puddle damages a second enemy over time")
	var half_steps: float = before - enemy.health
	enemy.health = before
	garden.lava_field._physics_process(0.5)
	_check(is_equal_approx(before - enemy.health, half_steps), "Damage scales with elapsed time")
	# The level owns puddles, so removing a tower cannot remove its damage area.
	tower.queue_free()
	await process_frame
	before = enemy.health
	garden.lava_field._physics_process(0.5)
	_check(enemy.health < before, "Puddle survives tower removal")
	garden.waves.state = WaveController.State.INTERMISSION
	garden.waves.state_changed.emit()
	_check(garden.lava_field.puddles.is_empty(), "Wave end clears active puddles")
	_check(not garden.lava_field.active, "Wave end stops damage")
	_check(not garden.lava_field.launch(Vector3.UP, cell, definition), "Late shots cannot create puddles")
	garden.waves.state = WaveController.State.SPAWNING
	garden.waves.state_changed.emit()
	_check(garden.lava_field.launch(Vector3.UP, cell, definition), "Next wave can target the tile again")
	garden.waves.state = WaveController.State.INTERMISSION
	garden.waves.state_changed.emit()
	await process_frame
	_check(garden.lava_field.pending.is_empty() and garden.lava_field.puddles.is_empty(), "Wave end cancels a blob in flight")
	_check(garden.lava_field.get_node_or_null("LavaProjectile") == null, "Cancelled projectile is freed")
	if failures == 0:
		print("Lava lamp tests passed")
	quit(1 if failures > 0 else 0)


func _nearby_route_index(grid: LevelGrid, tower_position: Vector3, reach: float) -> int:
	for index in grid.route.size():
		var center := grid.grid_to_world(grid.route[index])
		var distance := Vector2(center.x - tower_position.x, center.z - tower_position.z).length()
		if distance <= reach - 1.0 and distance > 2.0:
			return index
	return -1


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
