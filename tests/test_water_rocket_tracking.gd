extends SceneTree

const ENEMY_SCENE: PackedScene = preload("res://scenes/placement_enemy.tscn")
const ROCKET_SCENE: PackedScene = preload("res://scenes/water_rocket_projectile.tscn")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var definition := DefinitionLoader.load_tower("res://data/towers/water_rocket.json")
	var unit := DefinitionLoader.load_unit("res://data/units/windup_robot.json")
	# A route moving away from the rocket catches the near-target orbit problem.
	await _check_route(Vector3(0, 0, 0), Vector3(0, 0, 40), 5.0, Vector3(0, 1, 0), Vector3(0, 1, 0.35), definition, unit, "receding")
	# A crossing route checks that steering still follows a moving target.
	await _check_route(Vector3(-20, 0, 0), Vector3(20, 0, 0), 16.0, Vector3(0, 1, -5), Vector3(0, 1, 0.35), definition, unit, "crossing")
	var slower_rocket := definition.copy()
	slower_rocket.projectile_speed = 5.0
	await _check_route(Vector3(0, 0, 0), Vector3(0, 0, 40), 5.0, Vector3(0, 1, 0), Vector3(0, 1, 0.35), slower_rocket, unit, "slow receding")
	var faster_rocket := definition.copy()
	faster_rocket.projectile_speed = 10.0
	await _check_route(Vector3(-20, 0, 0), Vector3(20, 0, 0), 16.0, Vector3(0, 1, -5), Vector3(0, 1, 0.35), faster_rocket, unit, "fast crossing")
	if failures == 0:
		print("Water rocket tracking tests passed")
	quit(1 if failures > 0 else 0)


func _check_route(route_start: Vector3, route_end: Vector3, progress: float, launch_position: Vector3, launch_direction: Vector3, definition: TowerDefinition, unit: UnitDefinition, label: String) -> void:
	var path := Path3D.new()
	var curve := Curve3D.new()
	curve.add_point(route_start)
	curve.add_point(route_end)
	path.curve = curve
	root.add_child(path)
	var enemy := ENEMY_SCENE.instantiate()
	enemy.auto_cleanup = false
	enemy.configure(0, unit, 3.0, 1.0)
	path.add_child(enemy)
	enemy.set_process(false)
	enemy.progress = progress
	var rocket := ROCKET_SCENE.instantiate()
	root.add_child(rocket)
	rocket.global_position = launch_position
	rocket.configure(enemy, launch_direction, definition)
	rocket.set_physics_process(false)
	var hits := {"count": 0}
	rocket.hit_target.connect(func(_target: Node) -> void:
		hits.count += 1
	)
	var nearest := INF
	var step_delta := 1.0 / 60.0
	for step in int(definition.projectile_lifetime / step_delta):
		if rocket.impacted or rocket.is_queued_for_deletion() or enemy.reached_objective:
			break
		enemy._process(step_delta)
		rocket._physics_process(step_delta)
		nearest = minf(nearest, rocket.global_position.distance_to(enemy.visual.global_position))
	if hits.count != 1:
		push_error("%s target was never hit; nearest approach %.2f m" % [label, nearest])
		failures += 1
	path.queue_free()
	rocket.queue_free()
	await process_frame
