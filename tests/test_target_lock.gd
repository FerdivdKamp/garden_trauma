extends SceneTree

const EnemyScene = preload("res://scenes/placement_enemy.tscn")
const TowerScene = preload("res://scenes/tower_visual.tscn")
const TowerAttack = preload("res://scripts/placement_tower_attack.gd")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var route := Path3D.new()
	route.curve = Curve3D.new()
	route.curve.add_point(Vector3.ZERO)
	route.curve.add_point(Vector3(20, 0, 0))
	root.add_child(route)
	var tower = TowerScene.instantiate()
	root.add_child(tower)
	var attack = TowerAttack.new()
	attack.definition = DefinitionLoader.load_tower("res://data/towers/laser_tower.json")
	attack.definition.attack_range = 5.0
	attack.definition.detection_range = 10.0
	attack.definition.turn_speed = 360.0
	attack.enemies = route
	tower.add_child(attack)
	attack.set_process(false)
	var first = _enemy(route, 4.0)
	attack._process(1.0)
	_check(first.health < first.max_health and attack.locked_target == first, "Tower fires at and locks its first enemy")
	var second = _enemy(route, 2.0)
	attack._process(1.0)
	_check(first.health < first.max_health - attack.definition.damage and second.health == second.max_health, "Closer arrival does not interrupt a wounded target")
	first.progress = 6.0
	_check(attack._choose_target(tower) == second, "Leaving attack range releases the lock even within detection range")
	second.health = 0.0
	_check(attack._choose_target(tower) == first and attack.locked_target == null, "A detected enemy outside attack range is only pre-aimed")
	second.health = second.max_health
	_check(attack._choose_target(tower) == second, "Attackable enemy takes precedence over pre-aim")
	second.reached_objective = true
	first.progress = 3.0
	_check(attack._choose_target(tower) == first, "Enemy reaching the objective releases the lock")
	first.queue_free()
	second.reached_objective = false
	_check(attack._choose_target(tower) == second, "Enemy queued for deletion releases the lock")
	second.free()
	_check(attack._choose_target(tower) == null, "Freed target is handled safely")
	if failures == 0:
		print("Target lock tests passed")
	quit(1 if failures else 0)


func _enemy(route: Path3D, progress: float) -> Node:
	var enemy = EnemyScene.instantiate()
	var unit := DefinitionLoader.load_unit("res://data/units/windup_robot.json")
	enemy.configure(0, unit, 0.0, 1.0)
	route.add_child(enemy)
	enemy.set_process(false)
	enemy.progress = progress
	return enemy


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
