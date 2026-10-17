extends SceneTree

const Lane = preload("res://scripts/gumball_lane.gd")
const Projectile = preload("res://scripts/gumball_projectile.gd")
const Attack = preload("res://scripts/gumball_lane_attack.gd")
const Enemy = preload("res://scripts/placement_enemy.gd")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Tiny grids isolate ties, boundaries, and blocked segments from level art.
	var grid := LevelGrid.new()
	grid.width = 5
	grid.height = 5
	grid.tiles = [".....", "..=..", ".===.", "..=..", "....."]
	var options := Lane.lanes(grid, Vector2i(2, 2))
	_check(options.size() == 4 and Lane.longest_index(options) == 0, "Equal lanes prefer north")
	grid.tiles[1] = "....."
	options = Lane.lanes(grid, Vector2i(2, 2))
	_check(options.size() == 3 and options[0].name == "East", "Blocked north lane is omitted")
	grid.tiles = ["S==..", ".....", ".....", ".....", "....."]
	options = Lane.lanes(grid, Vector2i(0, 0))
	_check(options.size() == 1 and options[0].cells.size() == 2, "Boundary stops lane and spawn counts as path")

	var scene := load("res://scenes/tower_placement.tscn") as PackedScene
	var garden := scene.instantiate()
	root.add_child(garden)
	garden.currency = 1000
	var definition := garden.tower_definitions["gumball"] as TowerDefinition
	_check(definition.firing_mode == "lane" and definition.bounce_height == 0.5 and definition.bounce_frequency == 2.5 and definition.ball_count == 3, "Lane, bounce, and volley settings load from JSON")
	var invalid_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/towers/gumball.json"))
	invalid_data.attack.ball_count = 7
	_check(not DefinitionLoader.validate_tower_data(invalid_data), "Volley size cannot exceed the six unique colors")
	garden._select_tower(4)
	var cell := Vector2i(6, 4)
	var point: Vector3 = garden.grid.grid_to_world(cell)
	garden._update_lane(cell)
	_check(garden.can_place_at(point), "Gumball can sit beside a straight path")
	_check(garden.lane_options[garden.lane_index].cells.size() == 7, "Longest lane covers seven path tiles")
	_check(garden.lane_preview.get_child_count() == 9, "Preview has seven tiles and an arrow")
	garden._cycle_lane()
	_check(garden.lane_index == 0, "Only valid directions are cycled")
	var corner := Vector2i(12, 5)
	garden._update_lane(corner)
	_check(garden.lane_options.size() == 2, "Corner offers two adjacent path directions")
	var before_cycle: Vector2i = garden.lane_options[garden.lane_index].direction
	var rotate := InputEventKey.new()
	rotate.pressed = true
	rotate.keycode = KEY_R
	garden._unhandled_input(rotate)
	_check(garden.lane_options[garden.lane_index].direction != before_cycle, "R changes the selected valid direction")
	var empty := Vector2i(2, 2)
	garden._update_lane(empty)
	_check(not garden.can_place_at(garden.grid.grid_to_world(empty)), "No adjacent lane blocks placement")
	garden._update_lane(cell)
	garden.place_tower(point)
	_check(garden.placed_towers.get_child_count() == 1, "Gumball tower is placed")
	_check(garden.preview == null and garden.lane_preview == null, "Placement clears the lane preview")
	var tower: Node3D = garden.placed_towers.get_child(0)
	var attack := tower.get_node("Attack") as Attack
	attack.rng.seed = 4567
	_check(attack.lane_length == 7 and attack.lane_direction == Vector2i.RIGHT, "Placed lane is fixed")
	_check(tower.get_muzzle_position().x > tower.global_position.x, "Muzzle faces east")
	var original_yaw: float = tower.get_yaw_pivot().rotation.y
	var off_lane: Enemy = garden.spawn_enemy(0)
	off_lane.movement_speed = 0.0
	var before_shots: int = garden.shot_effects.get_child_count()
	attack.shot_clock = attack.definition.cooldown
	attack._process(0.01)
	_check(garden.shot_effects.get_child_count() == before_shots, "Off-lane enemy does not trigger fire")
	var first: Enemy = garden.spawn_enemy(0)
	first.movement_speed = 0.0
	first.progress = garden.grid.route.find(Vector2i(8, 4)) * LevelGrid.TILE_SIZE
	attack._process(0.01)
	_check(garden.shot_effects.get_child_count() == before_shots + 3, "A lane enemy triggers three balls")
	var first_ball := garden.shot_effects.get_child(before_shots) as Projectile
	var second_ball := garden.shot_effects.get_child(before_shots + 1) as Projectile
	var third_ball := garden.shot_effects.get_child(before_shots + 2) as Projectile
	_check(first_ball.ball_color != second_ball.ball_color and second_ball.ball_color != third_ball.ball_color and first_ball.ball_color != third_ball.ball_color, "One volley has distinct colors")
	_check((first_ball.visual.material_override as StandardMaterial3D).albedo_color == first_ball.ball_color, "Configured color reaches the visible sphere")
	_check(not is_equal_approx(first_ball.direction.z, second_ball.direction.z) and is_zero_approx(first_ball.direction.y), "Balls choose independent horizontal angles")
	_check(not is_equal_approx(first_ball.speed, second_ball.speed), "Balls choose independent speeds")
	_check(not is_equal_approx(first_ball.bounce_height, third_ball.bounce_height) and not is_equal_approx(first_ball.bounce_frequency, third_ball.bounce_frequency), "Balls choose independent bounces")
	before_shots = garden.shot_effects.get_child_count()
	attack.shot_clock = attack.definition.cooldown
	attack._process(0.01)
	_check(garden.shot_effects.get_child_count() == before_shots + 3, "A second volley still fires three balls")
	var next_first := garden.shot_effects.get_child(before_shots) as Projectile
	var next_second := garden.shot_effects.get_child(before_shots + 1) as Projectile
	var next_third := garden.shot_effects.get_child(before_shots + 2) as Projectile
	_check(not is_equal_approx(next_second.direction.z, second_ball.direction.z), "Consecutive volleys use different paths")
	_check(next_first.ball_color != next_second.ball_color and next_second.ball_color != next_third.ball_color, "Next volley also has distinct colors")
	_check(not is_equal_approx(next_second.bounce_phase, second_ball.bounce_phase), "Consecutive volleys vary bounce timing")
	for ball in [first_ball, second_ball, third_ball, next_first, next_second, next_third]:
		var endpoint: Vector3 = ball.global_position + ball.direction * ball.remaining_distance
		_check(absf(endpoint.z - attack.lane_end.z) < 0.8, "Random path ends inside the lane")
	var fastest_left := false
	var fastest_right := false
	for volley in 12:
		before_shots = garden.shot_effects.get_child_count()
		attack.shot_clock = attack.definition.cooldown
		attack._process(0.01)
		var fastest: Projectile
		var leftmost: Projectile
		var rightmost: Projectile
		for index in 3:
			var ball := garden.shot_effects.get_child(before_shots + index) as Projectile
			var endpoint: Vector3 = ball.global_position + ball.direction * ball.remaining_distance
			if fastest == null or ball.speed > fastest.speed:
				fastest = ball
			if leftmost == null or endpoint.z < (leftmost.global_position + leftmost.direction * leftmost.remaining_distance).z:
				leftmost = ball
			if rightmost == null or endpoint.z > (rightmost.global_position + rightmost.direction * rightmost.remaining_distance).z:
				rightmost = ball
		fastest_left = fastest_left or fastest == leftmost
		fastest_right = fastest_right or fastest == rightmost
	_check(fastest_left and fastest_right, "Fastest ball can take either side across volleys")
	first.progress = 0.0
	before_shots = garden.shot_effects.get_child_count()
	attack.shot_clock = attack.definition.cooldown
	attack._process(0.01)
	_check(garden.shot_effects.get_child_count() == before_shots, "Tower stops firing when the lane empties")
	first.progress = garden.grid.route.find(Vector2i(8, 4)) * LevelGrid.TILE_SIZE
	var price: int = attack.next_upgrade().cost
	_check(attack.buy_next_upgrade(price) == price and attack.definition.damage == 10, "First upgrade raises damage")
	price = attack.next_upgrade().cost
	_check(attack.buy_next_upgrade(price) == price and attack.definition.cooldown == 1.0 and attack.definition.projectile_speed == 8.0 and attack.definition.ball_count == 4, "Second upgrade increases fire rate, speed, and volley size")
	price = attack.next_upgrade().cost
	_check(attack.buy_next_upgrade(price) == price and attack.definition.damage == 15.0 and attack.definition.projectile_speed == 9.0 and attack.definition.ball_count == 5, "Third upgrade increases damage, speed, and volley size")
	_check(is_equal_approx(tower.get_yaw_pivot().rotation.y, original_yaw), "Upgrade keeps fixed direction")
	before_shots = garden.shot_effects.get_child_count()
	attack.shot_clock = attack.definition.cooldown
	attack._process(0.01)
	_check(garden.shot_effects.get_child_count() == before_shots + 5, "Fully upgraded tower fires five balls")
	var shot := garden.shot_effects.get_child(before_shots + 2) as Projectile
	_check(shot != null and shot.remaining_distance > 0, "Upgraded volley has a traveling ball")
	if shot != null:
		var start: Vector3 = shot.global_position
		shot._physics_process(0.1)
		_check(shot.global_position.x > start.x and absf(shot.global_position.z - start.z) < 0.2, "Center ball moves forward inside the lane")
		_check(shot.visual.position.y > 0, "Visible ball bounces above logical path")
		var second: Enemy = garden.spawn_enemy(0)
		second.movement_speed = 0.0
		second.progress = garden.grid.route.find(Vector2i(10, 4)) * LevelGrid.TILE_SIZE
		var first_health: float = first.health
		var second_health: float = second.health
		var sweep_start: Vector3 = garden.grid.grid_to_world(Vector2i(7, 4))
		var sweep_end: Vector3 = garden.grid.grid_to_world(Vector2i(11, 4))
		shot._check_hits(sweep_start, sweep_end)
		_check(first.health < first_health and second.health < second_health, "One ball damages multiple enemies")
		var health_after_hit: float = first.health
		shot._check_hits(sweep_start, sweep_end)
		_check(first.health == health_after_hit, "One ball hits each enemy only once")
		shot._physics_process(shot.remaining_distance / shot.speed + 0.01)
		_check(shot.is_queued_for_deletion(), "Ball despawns at the lane endpoint")
	if failures == 0:
		print("Gumball tower tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
