extends SceneTree

const PlacementEnemy = preload("res://scripts/placement_enemy.gd")
const PlacementTowerAttack = preload("res://scripts/placement_tower_attack.gd")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/tower_placement.tscn") as PackedScene
	var demo := scene.instantiate()
	demo.debug_mode = true
	root.add_child(demo)
	demo.currency = 1000
	await process_frame
	var path := demo.path as Path3D
	var red := path.get_node("Enemy1") as PlacementEnemy
	_check(red != null and red.enemy_type == 0, "Scene starts with a red enemy")
	_check(is_equal_approx(red.health, 50.0), "Red enemy starts at full health")
	red.movement_speed = 4.0
	red.progress = 0.0
	red._process(0.5)
	_check(is_equal_approx(red.progress, 2.0), "Path progress uses speed and delta")
	red.progress = path.curve.get_baked_length() - 0.5
	red._process(1.0)
	_check(is_equal_approx(red.progress, path.curve.get_baked_length()), "Enemy stops at route end")
	_check(red.reached_objective and red.objective_audio.playing, "Objective cue plays on arrival")

	demo.enemy_selector.select(1)
	var blue := demo.spawn_enemy() as PlacementEnemy
	_check(blue.enemy_type == 1 and blue.health == 75.0, "Selector spawns blue variant")
	_check(blue.visual_scale > red.visual_scale, "Blue visual is larger")
	demo._set_enemy_value(5.0, "blue_speed")
	demo._set_enemy_value(1.6, "blue_scale")
	_check(is_equal_approx(blue.movement_speed, 5.0) and is_equal_approx(blue.visual.scale.x, 1.6), "Speed and visual scale update existing enemy")
	_check(is_equal_approx(red.movement_speed, 4.0), "Blue settings do not change red speed")

	demo._select_tower(0)
	demo.place_tower(Vector3(-10, 0, -1))
	var tower := demo.placed_towers.get_child(0) as Node3D
	var attack := tower.get_node("Attack") as PlacementTowerAttack
	red.progress = 6.0
	# Reuse this enemy for the combat checks after testing its arrival state.
	red.reached_objective = false
	blue.progress = path.curve.get_baked_length()
	attack.definition.turn_speed = 360.0
	attack._process(1.0)
	_check(is_equal_approx(red.health, 40.0), "Tower damages nearest enemy in attack range")
	_check(demo.shot_effects.get_node_or_null("LaserBeam") != null, "Laser Tower draws a laser beam")
	var beam := demo.shot_effects.get_node_or_null("LaserBeam") as MeshInstance3D
	_check(beam != null and beam.mesh == demo.shot_effects.laser_template.mesh, "Laser reuses its preloaded mesh")
	var red_hit := demo.shot_effects.get_node_or_null("RedHit") as GPUParticles3D
	_check(red_hit != null and red_hit.process_material == demo.shot_effects.red_hit_template.process_material, "Laser reuses red hit particles")
	_check(is_equal_approx(blue.health, 75.0), "Out-of-range enemy takes no damage")
	_check(demo.enemy_health_label.text.contains("40 / 50 HP"), "Health display updates after damage")
	attack._process(0.2)
	_check(is_equal_approx(red.health, 40.0), "Shot interval limits attacks")
	# Changing typed definition data affects combat without reading JSON in the attack node.
	red.definition.armor["physical"] = 0.5
	attack.definition.bonus_vs_tags["ground"] = 2.0
	attack._process(0.8)
	_check(is_equal_approx(red.health, 30.0), "Armor and tag bonus modify damage")
	red.take_damage(100.0)
	_check(is_equal_approx(red.health, 0.0), "Health is clamped at zero")
	var stopped_at := red.progress
	red._process(1.0)
	_check(is_equal_approx(red.progress, stopped_at), "Defeated enemy stops moving")
	# The shell's mesh travels over time and is removed when its tween reaches the hit.
	demo.shot_effects.fire_shell(Vector3.ZERO, Vector3(1.0, 0.0, 0.0), 10.0)
	_check(demo.shot_effects.get_node_or_null("Shell") != null, "Shell is visible during flight")
	_check(demo.shot_effects.get_node_or_null("MuzzleSmoke") != null, "Shell creates muzzle smoke")
	var smoke := demo.shot_effects.get_node_or_null("MuzzleSmoke") as GPUParticles3D
	_check(smoke != null and smoke.process_material == demo.shot_effects.smoke_template.process_material, "Smoke reuses its particle material")
	await create_timer(0.25).timeout
	await process_frame
	_check(demo.shot_effects.get_node_or_null("Shell") == null, "Shell disappears on impact")

	demo.reset_enemies()
	_check(path.get_child_count() == 2, "Reset leaves one enemy and the path surface")
	var fresh_blue := path.get_child(1) as PlacementEnemy
	_check(fresh_blue.health == 75.0, "Reset restores selected enemy health")
	demo._select_tower(2)
	demo.place_tower(Vector3(-8.0, 0.0, -2.5))
	var lightning_attack := demo.placed_towers.get_child(1).get_node("Attack") as PlacementTowerAttack
	fresh_blue.movement_speed = 0.0
	fresh_blue.progress = 6.0
	lightning_attack.definition.turn_speed = 360.0
	lightning_attack._process(1.2)
	_check(fresh_blue.health < 75.0 and demo.shot_effects.lightning_pool[0].active, "Placed lightning tower damages and draws a bolt")
	if failures == 0:
		print("Placement combat tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
