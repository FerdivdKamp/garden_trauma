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
	var left := garden.shot_effects.get_child(before_shots) as Projectile
	var middle := garden.shot_effects.get_child(before_shots + 1) as Projectile
	var right := garden.shot_effects.get_child(before_shots + 2) as Projectile
	_check(left.ball_color != middle.ball_color and middle.ball_color != right.ball_color and left.ball_color != right.ball_color, "One volley has distinct colors")
	_check((left.visual.material_override as StandardMaterial3D).albedo_color == left.ball_color, "Configured color reaches the visible sphere")
	_check(left.direction.z < middle.direction.z and middle.direction.z < right.direction.z and is_zero_approx(left.direction.y), "Volley uses slight horizontal angles")
	_check(left.speed < middle.speed and middle.speed < right.speed, "Volley uses different speeds")
	_check(left.bounce_height != right.bounce_height and left.bounce_frequency != right.bounce_frequency, "Volley uses different bounces")
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
		_check(shot.global_position.x > start.x and is_equal_approx(shot.global_position.z, start.z), "Center ball moves straight")
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
