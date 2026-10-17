extends SceneTree

const WaterRocketProjectile = preload("res://scripts/water_rocket_projectile.gd")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var garden := (load("res://scenes/tower_placement.tscn") as PackedScene).instantiate()
	garden.debug_mode = true
	root.add_child(garden)
	garden.currency = 1000
	garden._select_tower(3)
	_check(garden.tower_buttons.size() == 5 and garden.preview.water_model != null, "Water rocket has a placeable preview")
	_check(garden.preview.water_model.muzzle is Marker3D, "Placeholder has a muzzle marker")
	garden.place_tower(Vector3(-8, 0, 8))
	var placed_cost: int = (garden.tower_definitions["water_rocket"] as TowerDefinition).cost
	_check(garden.placed_towers.get_child_count() == 1 and garden.currency == 1000 - placed_cost, "Placement deducts the configured cost")
	var tower = garden.placed_towers.get_child(0)
	var attack = tower.get_node("Attack")
	attack.set_process(false)
	_check(tower.tower_type == 3 and tower.get_yaw_pivot() == tower.water_model.yaw_pivot, "Water rocket uses its own yaw pivot")
	_check(tower.get_muzzle_position().is_equal_approx(tower.water_model.muzzle.global_position), "Projectile uses the marker position")
	var enemy = garden.path.get_node("Enemy1")
	enemy.movement_speed = 0.0
	var nearest_progress := 0.0
	var nearest_distance := INF
	for index in int(garden.path.curve.get_baked_length() * 2.0):
		enemy.progress = index * 0.5
		var candidate_distance: float = tower.global_position.distance_to(enemy.global_position)
		if candidate_distance < nearest_distance:
			nearest_distance = candidate_distance
			nearest_progress = enemy.progress
	enemy.progress = nearest_progress
	_check(nearest_distance < attack.definition.attack_range, "Placed tower can reach the test route")
	garden._select_placed_tower(tower)
	_check(garden.upgrade_panel.visible and garden.upgrade_details.text.contains("Water Rocket"), "Water rocket opens the existing upgrade UI")
	attack.shot_clock = 0.0
	attack._process(attack.definition.cooldown + 0.1)
	var desired_yaw: float = TowerRules.target_yaw(enemy.global_position - tower.get_yaw_pivot().global_position)
	_check(absf(angle_difference(tower.get_yaw_pivot().rotation.y, desired_yaw)) < deg_to_rad(5.0), "Pump and launcher turn toward the enemy")
	_check(is_equal_approx(enemy.health, enemy.max_health), "Pump begins before damage")
	await create_timer(0.20).timeout
	var launched_rocket := garden.shot_effects.get_node_or_null("WaterRocketProjectile") as WaterRocketProjectile
	_check(launched_rocket != null and launched_rocket.global_position.distance_to(tower.get_muzzle_position()) < 1.0, "Attack launches from the rotating muzzle")
	if launched_rocket != null:
		launched_rocket.queue_free()
	enemy.health = enemy.max_health
	var launches := {"count": 0, "compressed_scale": 1.0}
	tower.pump_and_launch(func() -> void:
		launches.count += 1
		launches.compressed_scale = tower.water_model.accordion.scale.y
	)
	_check(tower.water_model.loaded_rocket.visible, "Rocket stays seated during compression")
	await create_timer(0.30).timeout
	_check(launches.count == 1 and launches.compressed_scale <= 0.56, "Launch follows full compression")
	await create_timer(0.40).timeout
	_check(tower.water_model.loaded_rocket.visible and is_equal_approx(tower.water_model.accordion.scale.y, 1.0), "Bellows and rocket reset")
	var definition := attack.definition as TowerDefinition
	var hit_point: Vector3 = enemy.visual.global_position
	var start := hit_point + Vector3(0, 0.8, 4.0)
	var rocket := garden.shot_effects.fire_water_rocket(start, enemy, definition, Vector3(0, 1, -0.35)) as WaterRocketProjectile
	rocket.set_physics_process(false)
	_check(rocket.trail.emitting and not rocket.trail.local_coords, "Water droplets form a world-space trail")
	var nozzle_spray := garden.shot_effects.get_node_or_null("WaterNozzleSpray") as GPUParticles3D
	_check(nozzle_spray != null and nozzle_spray.one_shot and nozzle_spray.lifetime < 0.35, "Launch emits a short separate nozzle burst")
	var initial_direction := rocket.direction
	var hits := {"count": 0}
	rocket.hit_target.connect(func(_target: Node) -> void:
		hits.count += 1
	)
	for step in 150:
		if rocket.impacted:
			break
		if step == 6:
			enemy.progress += 0.7
		rocket._physics_process(0.05)
	_check(initial_direction.angle_to(rocket.direction) > 0.1, "Rocket curves toward a moving enemy")
	_check(hits.count == 1 and is_equal_approx(enemy.health, enemy.max_health - definition.damage), "Impact deals damage once")
	rocket._impact(enemy)
	_check(hits.count == 1, "Repeated impact cannot deal damage again")
	var lost_target := garden.shot_effects.fire_water_rocket(start, enemy, definition, Vector3.UP) as WaterRocketProjectile
	lost_target.set_physics_process(false)
	enemy.take_damage(enemy.health)
	lost_target._physics_process(0.1)
	_check(not lost_target.impacted and lost_target.global_position.y > start.y, "Lost target leaves rocket on its last heading")
	lost_target._physics_process(definition.projectile_lifetime)
	_check(lost_target.is_queued_for_deletion(), "Rocket expires at its lifetime")
	var upgrades := definition.upgrades.duplicate(true)
	for level in upgrades.size():
		var upgrade: Dictionary = upgrades[level]
		var cost: int = int(upgrade.cost)
		_check(attack.buy_next_upgrade(cost) == cost and attack.upgrade_level == level + 1, "Upgrade stage %d can be purchased" % (level + 1))
		for key in upgrade.attack:
			var property_name: String = "attack_range" if key == "range" else key
			_check(is_equal_approx(float(definition.get(property_name)), float(upgrade.attack[key])), "Upgrade stage %d applies %s" % [level + 1, key])
	if failures == 0:
		print("Water rocket tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
