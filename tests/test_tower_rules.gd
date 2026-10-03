extends SceneTree

var failures := 0


func _initialize() -> void:
	_check(TowerRules.can_detect(9.0, 9.0), "Detection includes its boundary")
	_check(not TowerRules.can_detect(9.1, 9.0), "Detection excludes farther targets")
	_check(TowerRules.can_attack(6.0, 6.0, 9.0), "Attack includes its boundary")
	_check(not TowerRules.can_attack(7.0, 6.0, 9.0), "Detected target outside attack range is safe")
	_check(not TowerRules.can_attack(7.0, 8.0, 6.0), "Attack also requires detection")
	_check(is_equal_approx(TowerRules.target_yaw(Vector3.RIGHT), -PI / 2.0), "Yaw faces positive X")
	_check(is_equal_approx(absf(TowerRules.step_yaw(0.0, PI, PI / 2.0, 1.0)), PI / 2.0), "Turn speed limits one step")
	_check(is_equal_approx(TowerRules.step_yaw(0.0, PI / 2.0, PI, 1.0), PI / 2.0), "Turret reaches nearby target")
	_check(is_equal_approx(TowerRules.health_after_hit(5.0, 10.0), 0.0), "Damage does not make health negative")
	_check(is_equal_approx(TowerRules.health_after_hit(5.0, -10.0), 5.0), "Negative damage does not heal")
	if failures == 0:
		print("Tower rule tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
