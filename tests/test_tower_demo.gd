extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/tower_demo.tscn") as PackedScene
	var demo := scene.instantiate()
	root.add_child(demo)
	await process_frame

	var pivot := demo.get_node("Tower/TurretPivot") as Node3D
	var pawn := demo.get_node("Pawn") as Node3D
	_check(pivot.get_child_count() == 2, "Single barrel has a cap and one barrel")
	_check(is_equal_approx(pawn.position.x, demo.get("pawn_distance")), "Pawn position matches its distance setting")

	demo.call("_on_tower_selected", 1)
	await process_frame
	_check(pivot.get_child_count() == 3, "Double barrel has a cap and two barrels")

	demo.call("_reset_aim")
	var direction: Vector3 = pawn.global_position - pivot.global_position
	var target_yaw := TowerRules.target_yaw(direction)
	_check(is_equal_approx(absf(angle_difference(pivot.rotation.y, target_yaw)), PI), "Reset aims away from pawn")

	if failures == 0:
		print("Tower scene tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
