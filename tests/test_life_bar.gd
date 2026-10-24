extends SceneTree

const PlacementEnemy = preload("res://scripts/placement_enemy.gd")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var battle := (load("res://scenes/tower_placement.tscn") as PackedScene).instantiate()
	battle.debug_mode = true
	root.add_child(battle)
	await process_frame

	var enemy := battle.path.get_node("Enemy1") as PlacementEnemy
	_check(not enemy.health_bar.visible, "Full health bar starts hidden")
	_check(battle.currency_label.text == str(battle.currency), "Gold icon sits beside the amount")
	_check(battle.objective_label.text == "%d/%d" % [battle.objective_health, battle.starting_objective_health], "Heart icon sits beside remaining lives")
	var stats: HBoxContainer = battle.currency_label.get_parent()
	_check((stats.get_child(0) as TextureRect).texture == battle.COIN_ICON, "Gold icon is present")
	_check((stats.get_child(2) as TextureRect).texture == battle.HEART_ICON, "Heart icon is present")

	enemy.progress = battle.path.curve.get_baked_length() * 0.5
	var enemy_screen: Vector2 = battle.camera.unproject_position(enemy.global_position + Vector3(0.0, 1.0, 0.0))
	battle._update_hovered_enemy(enemy_screen)
	_check(battle.hovered_enemy == enemy and enemy.health_bar.visible, "Pointing at an enemy reveals its bar")
	battle._update_hovered_enemy(Vector2(-1000.0, -1000.0))
	_check(not enemy.health_bar.visible, "Moving the pointer away hides the bar")
	enemy.set_hovered(true)
	_check(enemy.health_bar.visible, "Hover reveals the bar")
	enemy.set_hovered(false)
	_check(not enemy.health_bar.visible, "Leaving an unhurt enemy hides the bar")
	enemy.movement_speed = 0.0
	enemy.take_damage(enemy.max_health * 0.5)
	_check(enemy.health_bar.visible and enemy.hit_bar_remaining == 1.0, "A hit reveals the bar for one second")
	var image := (enemy.health_bar.texture as ImageTexture).get_image()
	_check(image.get_pixel(10, 4).r > image.get_pixel(50, 4).r, "Red fill shrinks over black backing")
	enemy._process(1.01)
	_check(not enemy.health_bar.visible, "Hit bar hides after one second")
	enemy.set_hovered(true)
	enemy.take_damage(enemy.max_health)
	_check(not enemy.health_bar.visible, "Defeated enemy does not show a bar")

	if failures == 0:
		print("Life bar tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
