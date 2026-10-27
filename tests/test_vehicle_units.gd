extends SceneTree

const EnemyScene: PackedScene = preload("res://scenes/placement_enemy.tscn")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var route := Path3D.new()
	var curve := Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(0, 0, -4))
	curve.add_point(Vector3(4, 0, -4))
	route.curve = curve
	root.add_child(route)

	var tank := _add_enemy(route, 2, "toy_tank")
	var car := _add_enemy(route, 3, "formula_car")
	_check(tank.tank.visible and not tank.robot.visible and not tank.sphere.visible, "Tank has its own placeholder model")
	_check(car.formula_car.visible and not car.robot.visible and not car.sphere.visible, "Car has its own placeholder model")
	_check(tank.health == 220.0 and car.health == 30.0, "Vehicle health comes from data")

	# A tank turns its hull at the corner before continuing down the next leg.
	tank.progress = 3.95
	tank.visual.rotation.y = 0.0
	var before: float = tank.progress
	tank._process(0.1)
	_check(is_equal_approx(tank.progress, before) and absf(tank.visual.rotation.y) > 0.01, "Tank pivots before moving around a corner")
	for index in range(20):
		tank._process(0.1)
	_check(tank.progress > before, "Tank resumes movement once aligned")

	# The car builds speed on a straight, then slows before the next bend.
	car.progress = 0.0
	car.current_speed = 2.0
	car._process(0.2)
	_check(car.current_speed > 2.0, "Car accelerates on a straight")
	car.progress = 2.8
	car.current_speed = car.movement_speed
	car._process(0.2)
	_check(car.current_speed < car.movement_speed, "Car brakes for an upcoming bend")

	if failures == 0:
		print("Vehicle unit tests passed")
	quit(1 if failures > 0 else 0)


func _add_enemy(route: Path3D, type: int, id: String) -> Node:
	var unit := DefinitionLoader.load_unit("res://data/units/%s.json" % id)
	var enemy := EnemyScene.instantiate()
	enemy.auto_cleanup = false
	enemy.configure(type, unit, unit.speed, 1.0)
	route.add_child(enemy)
	return enemy


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
