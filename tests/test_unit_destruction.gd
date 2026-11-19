extends SceneTree

const EnemyScene := preload("res://scenes/placement_enemy.tscn")
var failures := 0
var defeats := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var route := Path3D.new()
	route.curve = Curve3D.new()
	route.curve.add_point(Vector3.ZERO)
	route.curve.add_point(Vector3(0, 0, -10))
	root.add_child(route)
	var robot: Node
	var wheel_starts: Array[Dictionary] = []
	for entry in [[0, "windup_robot"], [3, "formula_car"], [4, "race_car_battery"]]:
		var enemy := EnemyScene.instantiate()
		var unit := DefinitionLoader.load_unit("res://data/units/%s.json" % entry[1])
		enemy.configure(entry[0], unit, unit.speed, 1.0)
		route.add_child(enemy)
		enemy.defeated.connect(func(_unit: Node) -> void: defeats += 1)
		enemy.take_damage(enemy.health)
		enemy.take_damage(1.0)
		_check(enemy.health == 0.0 and enemy.visual.visible, "Defeated unit remains visible for its effect")
		if entry[0] == 0:
			robot = enemy
			_check(enemy.head.get_parent() is RigidBody3D and enemy.leg_left.get_parent() is RigidBody3D, "Robot parts detach into physics bodies")
			_check(enemy.get_node_or_null("DebrisFloor") is StaticBody3D, "Robot debris has an isolated floor")
		else:
			var model: Node3D = enemy.formula_car if entry[0] == 3 else enemy.battery_car
			var pieces := 0
			for child in model.get_children():
				if child.has_meta("wheel_debris"):
					pieces += 1
					_check(child.get_child_count() == 2, "Each wheel and hub share one pivot")
					wheel_starts.append({"node": child, "position": child.position})
			_check(pieces == 4, "Each car has four independent wheels")
	_check(defeats == 3, "Repeated damage emits defeat once per unit")
	await create_timer(0.35).timeout
	for wheel in wheel_starts:
		var pivot: Node3D = wheel.node
		_check(pivot.position.z < wheel.position.z - 0.05 and pivot.rotation.x > 0.1, "Wheels roll forward before tipping")
		_check(absf(pivot.rotation.z) < 0.05, "Wheels remain upright at the start of the roll")
	await create_timer(1.15).timeout
	for wheel in wheel_starts:
		_check(absf((wheel.node as Node3D).rotation.z) > 1.0, "Wheels tip outward after rolling")
	for child in robot.get_children():
		if child is RigidBody3D:
			var shape := child.get_child(0) as CollisionShape3D
			var box := shape.shape as BoxShape3D
			var bounds: AABB = shape.global_transform * AABB(-box.size / 2.0, box.size)
			_check(bounds.position.y > -0.08 and bounds.position.y < 0.18, "Robot debris rests on its floor")
	await create_timer(1.2).timeout
	_check(route.get_child_count() == 0, "Defeated wave units are cleaned up")
	route.queue_free()
	if failures == 0:
		print("Unit destruction tests passed")
	quit(1 if failures else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
