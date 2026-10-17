extends "res://scripts/placement_tower_attack.gd"

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/gumball_projectile.tscn")
const BALL_COLORS := [Color("ffe24c"), Color("46def0"), Color("a9ef53"), Color("ff9b42"), Color("ff6fbb"), Color("a577ef")]
const LANE_HALF_WIDTH := LevelGrid.TILE_SIZE * 0.5
const MAX_LATERAL_OFFSET := 0.62

var lane_direction := Vector2i.ZERO
var lane_length := 0
var lane_start := Vector3.ZERO
var lane_end := Vector3.ZERO
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func configure_lane(direction: Vector2i, cells: Array[Vector2i], grid: LevelGrid) -> void:
	lane_direction = direction
	lane_length = cells.size()
	if lane_length > 0:
		lane_start = grid.grid_to_world(cells.front()) - Vector3(direction.x, 0, direction.y) * LANE_HALF_WIDTH
		lane_end = grid.grid_to_world(cells.back()) + Vector3(direction.x, 0, direction.y) * (LevelGrid.TILE_SIZE * 0.4)


func _process(delta: float) -> void:
	if lane_length == 0 or enemies == null or effects == null:
		return
	shot_clock = minf(shot_clock + delta, definition.cooldown)
	if shot_clock < definition.cooldown:
		return
	if not _has_enemy_in_lane():
		return
	shot_clock = 0.0
	var tower := get_parent() as Node3D
	var start: Vector3 = tower.get_muzzle_position()
	var forward := Vector3(lane_direction.x, 0, lane_direction.y)
	var side := Vector3(-forward.z, 0, forward.x)
	var count: int = definition.ball_count
	var shot_definition := definition.copy()
	# Shuffle the palette so neither a color nor a speed owns one side of the lane.
	var colors := BALL_COLORS.duplicate()
	for index in range(colors.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var previous_color: Color = colors[index]
		colors[index] = colors[swap_index]
		colors[swap_index] = previous_color
	for index in count:
		# Each ball chooses its own path. The endpoint leaves room for its radius
		# before the edge of the final path tile.
		var lateral_offset := rng.randf_range(-MAX_LATERAL_OFFSET, MAX_LATERAL_OFFSET)
		var start_offset := start + side * rng.randf_range(-0.08, 0.08)
		var endpoint := lane_end + side * lateral_offset
		endpoint.y = start_offset.y
		var variation := {
			"speed": rng.randf_range(0.82, 1.18),
			"height": rng.randf_range(0.75, 1.25),
			"frequency": rng.randf_range(0.8, 1.2),
			"phase": rng.randf_range(0.0, 0.9),
		}
		var shot := PROJECTILE_SCENE.instantiate()
		effects.add_child(shot)
		shot.configure(start_offset, endpoint, shot_definition, enemies, colors[index], variation)
	tower.play_fire_sound()


func _has_enemy_in_lane() -> bool:
	var forward := Vector3(lane_direction.x, 0, lane_direction.y)
	var lane_distance := (lane_end - lane_start).dot(forward)
	for child in enemies.get_children():
		var enemy := child as PlacementEnemy
		if enemy == null or enemy.health <= 0.0 or enemy.reached_objective or not "ground" in enemy.definition.tags:
			continue
		var offset := enemy.global_position - lane_start
		var along := offset.dot(forward)
		var sideways := (offset - forward * along).length()
		if along >= 0.0 and along <= lane_distance and sideways <= LANE_HALF_WIDTH:
			return true
	return false
