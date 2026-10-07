extends Node3D

const TOWER_SCENE: PackedScene = preload("res://scenes/tower_visual.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/placement_enemy.tscn")
const PlacementEnemy = preload("res://scripts/placement_enemy.gd")
const PlacementTowerAttack = preload("res://scripts/placement_tower_attack.gd")
const ShotEffects = preload("res://scripts/placement_shot_effects.gd")
const TowerVisual = preload("res://scripts/tower_visual.gd")
const TileGrid = preload("res://scripts/level_grid.gd")
const TOWER_IDS := ["toy_tank", "double_tank", "lightning_tower"]
const TOWER_RADIUS := TowerVisual.FOOTPRINT_RADIUS

@onready var camera: Camera3D = $Camera
@onready var path: Path3D = $PlacementPath
@onready var grid: TileGrid = $LevelGrid
@onready var placed_towers: Node3D = $PlacedTowers
@onready var waves: WaveController = $Waves
@onready var shot_effects: ShotEffects = $ShotEffects
@onready var preview_holder: Node3D = $Preview
@onready var palette: PanelContainer = $UI/Palette
@onready var enemy_panel: PanelContainer = $UI/EnemyPanel
@onready var pause_overlay: Control = $UI/PauseOverlay
@onready var result_overlay: Control = $UI/ResultOverlay

@export var debug_mode := false
@export_range(1, 100, 1) var starting_objective_health := 10
@export_range(0, 10000, 1) var starting_currency := 240

@export_range(0.0, 30.0, 0.1) var red_speed := 3.0
@export_range(0.0, 30.0, 0.1) var blue_speed := 2.0
@export_range(0.1, 3.0, 0.05) var red_scale := 1.0
@export_range(0.1, 3.0, 0.05) var blue_scale := 1.3

var selected_type := -1
var preview: Node3D
var hovered_tower: Node3D
var has_ground_point := false
var ground_point := Vector3.ZERO
var status: Label
var tower_buttons: Array[Button] = []
var enemy_selector: OptionButton
var enemy_health_label: Label
var enemy_count := 0
var tower_definitions: Dictionary
var unit_definitions: Dictionary
var objective_health := 10
var currency := 240
var battle_result := ""
var currency_label: Label
var objective_label: Label
var wave_label: Label
var enemies_label: Label
var next_wave_button: Button
var pause_button: Button


func _ready() -> void:
	# Load once; scene nodes use typed definitions instead of JSON dictionaries.
	tower_definitions = DefinitionLoader.load_towers(DefinitionLoader.TOWER_OVERRIDE_DIR)
	unit_definitions = DefinitionLoader.load_units()
	assert(tower_definitions.has("toy_tank") and tower_definitions.has("double_tank") and tower_definitions.has("lightning_tower") and unit_definitions.has("red_sphere") and unit_definitions.has("blue_sphere"))
	red_speed = (unit_definitions["red_sphere"] as UnitDefinition).speed
	blue_speed = (unit_definitions["blue_sphere"] as UnitDefinition).speed
	objective_health = starting_objective_health
	currency = starting_currency
	camera.look_at(Vector3.ZERO, Vector3.UP)
	_setup_route()
	_build_ui()
	waves.spawn_requested.connect(_on_wave_spawn_requested)
	waves.state_changed.connect(_refresh_hud)
	waves.all_waves_cleared.connect(func() -> void: _finish_battle("victory"))
	$UI/PauseOverlay/Center/Panel/Actions/Resume.pressed.connect(_resume_battle)
	$UI/PauseOverlay/Center/Panel/Actions/Restart.pressed.connect(_restart_level)
	$UI/PauseOverlay/Center/Panel/Actions/MainMenu.pressed.connect(_return_to_menu)
	$UI/ResultOverlay/Center/Panel/Actions/Restart.pressed.connect(_restart_level)
	$UI/ResultOverlay/Center/Panel/Actions/MainMenu.pressed.connect(_return_to_menu)
	if debug_mode:
		spawn_enemy()
	_refresh_hud()


func _process(_delta: float) -> void:
	if battle_result != "":
		return
	_refresh_hud()
	var mouse_position := get_viewport().get_mouse_position()
	_update_cursor(mouse_position)
	_update_hovered_tower(mouse_position)
	if preview == null:
		return
	preview.visible = has_ground_point
	if has_ground_point:
		preview.position = grid.grid_to_world(grid.world_to_grid(ground_point))
		var valid := can_place_at(ground_point) and _can_afford_selected()
		preview.set_placement_valid(valid)
		if not _can_afford_selected():
			status.text = "Not enough currency for this tower"
		else:
			status.text = "Click to place" if valid else "Blocked: path, rock, edge, or another tower"
	else:
		status.text = "Move over the ground to place"


func _unhandled_input(event: InputEvent) -> void:
	if battle_result != "":
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_select_tower(-1)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_G:
		grid.show_grid = not grid.show_grid
	elif event is InputEventKey and event.pressed and event.keycode == KEY_C:
		grid.show_coordinates = not grid.show_coordinates
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		grid.show_route = not grid.show_route
	elif event is InputEventKey and event.pressed and event.keycode == KEY_I:
		_update_cursor(get_viewport().get_mouse_position())
		if has_ground_point:
			var cell := grid.world_to_grid(ground_point)
			print("Tile %s: %s, buildable=%s, walkable=%s" % [cell, grid.terrain_at(cell), grid.is_buildable(cell), grid.is_walkable(cell)])
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_update_cursor(event.position)
		if preview != null and has_ground_point and can_place_at(ground_point) and _can_afford_selected():
			place_tower(ground_point)


func _input(event: InputEvent) -> void:
	if battle_result != "":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_select_tower(-1)
		get_viewport().set_input_as_handled()


func _update_cursor(screen_position: Vector2) -> void:
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	if absf(direction.y) < 0.0001:
		has_ground_point = false
		return
	var distance := -origin.y / direction.y
	has_ground_point = distance >= 0.0
	if has_ground_point:
		ground_point = origin + direction * distance
		ground_point.y = 0.0


func _update_hovered_tower(screen_position: Vector2) -> void:
	var found: Node3D
	if get_viewport().gui_get_hovered_control() == null:
		for child in placed_towers.get_children():
			var tower := child as Node3D
			var center := tower.global_position + Vector3(0.0, 0.6, 0.0)
			if camera.is_position_behind(center):
				continue
			var center_screen := camera.unproject_position(center)
			var edge_screen := camera.unproject_position(center + Vector3(TOWER_RADIUS, 0.0, 0.0))
			var hover_radius := maxf(24.0, center_screen.distance_to(edge_screen) * 1.5)
			if screen_position.distance_to(center_screen) <= hover_radius:
				found = tower
				break
	if found == hovered_tower:
		return
	if hovered_tower != null:
		hovered_tower.set_ranges_visible(false)
	hovered_tower = found
	if hovered_tower != null:
		hovered_tower.set_ranges_visible(true)


func can_place_at(point: Vector3) -> bool:
	var cell := grid.world_to_grid(point)
	if not grid.is_buildable(cell):
		return false
	for tower in placed_towers.get_children():
		if grid.world_to_grid(tower.position) == cell:
			return false
	return true


func _setup_route() -> void:
	# PathFollow3D still drives the existing enemies. Its curve now comes from
	# the level's ordered tile route, so there is one source of path truth.
	var curve := Curve3D.new()
	for cell in grid.route:
		curve.add_point(grid.grid_to_world(cell))
	path.curve = curve
	path.path_width = TileGrid.TILE_SIZE


func place_tower(point: Vector3) -> void:
	if battle_result != "" or selected_type < 0 or not can_place_at(point) or not _can_afford_selected():
		return
	var definition := tower_definitions[TOWER_IDS[selected_type]] as TowerDefinition
	currency -= definition.cost
	var tower := TOWER_SCENE.instantiate()
	tower.set_tower_type(selected_type)
	tower.position = grid.grid_to_world(grid.world_to_grid(point))
	placed_towers.add_child(tower)
	tower.set_ranges(definition.attack_range, definition.detection_range)
	var attack := PlacementTowerAttack.new()
	attack.name = "Attack"
	attack.definition = definition
	attack.enemies = path
	attack.effects = shot_effects
	tower.add_child(attack)
	_refresh_hud()


func spawn_enemy(type: int = -1, from_wave: bool = false) -> PlacementEnemy:
	if type < 0:
		type = enemy_selector.selected if enemy_selector != null else 0
	var enemy := ENEMY_SCENE.instantiate() as PlacementEnemy
	var unit := unit_definitions["red_sphere" if type == 0 else "blue_sphere"] as UnitDefinition
	enemy_count += 1
	enemy.name = "Enemy%d" % enemy_count
	enemy.auto_cleanup = from_wave
	enemy.set_meta("wave_enemy", from_wave)
	enemy.configure(type, unit, red_speed if type == 0 else blue_speed, red_scale if type == 0 else blue_scale)
	path.add_child(enemy)
	enemy.health_changed.connect(_update_enemy_health)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.objective_reached.connect(_on_enemy_objective_reached)
	_update_enemy_health()
	return enemy


func reset_enemies() -> void:
	if not debug_mode:
		return
	for child in path.get_children():
		if child is PlacementEnemy:
			path.remove_child(child)
			child.queue_free()
	enemy_count = 0
	spawn_enemy()
	for tower in placed_towers.get_children():
		tower.get_node("Attack").shot_clock = 0.0


func _on_wave_spawn_requested(enemy_id: String) -> void:
	var type := 0 if enemy_id == "red_sphere" else 1
	if enemy_id != "red_sphere" and enemy_id != "blue_sphere":
		push_error("Unknown wave enemy: " + enemy_id)
		waves.enemy_resolved()
		return
	spawn_enemy(type, true)


func _on_enemy_defeated(enemy: Node) -> void:
	if battle_result != "":
		return
	currency += (enemy as PlacementEnemy).definition.reward
	_resolve_wave_enemy(enemy)
	_refresh_hud()


func _on_enemy_objective_reached(enemy: Node) -> void:
	if battle_result != "":
		return
	objective_health = maxi(0, objective_health - 1)
	if objective_health == 0:
		_finish_battle("defeat")
	else:
		_resolve_wave_enemy(enemy)
	_refresh_hud()


func _resolve_wave_enemy(enemy: Node) -> void:
	if enemy.get_meta("wave_enemy", false):
		waves.enemy_resolved()


func _can_afford_selected() -> bool:
	if selected_type < 0:
		return false
	return currency >= (tower_definitions[TOWER_IDS[selected_type]] as TowerDefinition).cost


func _set_enemy_value(value: float, key: String) -> void:
	set(key, value)
	for child in path.get_children():
		var enemy := child as PlacementEnemy
		if enemy == null:
			continue
		if (enemy.enemy_type == 0 and key.begins_with("red")) or (enemy.enemy_type == 1 and key.begins_with("blue")):
			if key.ends_with("speed"):
				enemy.movement_speed = value
			else:
				enemy.visual_scale = value


func _update_enemy_health() -> void:
	if enemy_health_label == null:
		return
	var lines: PackedStringArray = []
	for child in path.get_children():
		var enemy := child as PlacementEnemy
		if enemy != null:
			lines.append("%s (%s): %.0f / %.0f HP" % [enemy.name, "Red" if enemy.enemy_type == 0 else "Blue", enemy.health, enemy.max_health])
	enemy_health_label.text = "\n".join(lines)


func _select_tower(tower_type: int) -> void:
	if battle_result != "":
		return
	selected_type = tower_type
	if preview != null:
		preview.queue_free()
		preview = null
	for index in tower_buttons.size():
		tower_buttons[index].button_pressed = index == tower_type
	if tower_type < 0:
		status.text = "Select a tower tile to place it."
		return
	preview = TOWER_SCENE.instantiate()
	preview.set_tower_type(tower_type)
	preview.set_preview(true)
	preview_holder.add_child(preview)
	var definition := tower_definitions[TOWER_IDS[tower_type]] as TowerDefinition
	preview.set_ranges(definition.attack_range, definition.detection_range)
	preview.set_ranges_visible(true)
	status.text = "Move over the ground to place"


func _build_ui() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	palette.add_child(column)
	var title := Label.new()
	title.text = "TOWER PLACEMENT"
	column.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	for index in TOWER_IDS.size():
		var tile := Button.new()
		var definition := tower_definitions[TOWER_IDS[index]] as TowerDefinition
		tile.text = "%s\n%d coins" % [["LASER", "DOUBLE BARREL", "LIGHTNING"][index], definition.cost]
		tile.custom_minimum_size = Vector2(105, 100)
		tile.toggle_mode = true
		tile.pressed.connect(_select_tower.bind(index))
		row.add_child(tile)
		tower_buttons.append(tile)
	status = Label.new()
	status.text = "Select a tower tile. Esc cancels selection."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	var help := Label.new()
	help.text = "Green range: attack   Yellow range: detection\nSand and rocks: no towers\nG grid  C coords  R route  I inspect\nRight-click or Esc: empty your hand"
	column.add_child(help)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	enemy_panel.add_child(scroll)
	var sidebar := VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 9)
	scroll.add_child(sidebar)
	_build_battle_ui(sidebar)
	if debug_mode:
		_build_enemy_ui(sidebar)


func _build_battle_ui(column: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "GARDEN DEFENSE"
	column.add_child(title)
	currency_label = Label.new()
	column.add_child(currency_label)
	objective_label = Label.new()
	column.add_child(objective_label)
	wave_label = Label.new()
	column.add_child(wave_label)
	enemies_label = Label.new()
	column.add_child(enemies_label)
	next_wave_button = Button.new()
	next_wave_button.text = "Start wave 1"
	next_wave_button.pressed.connect(waves.start_next_wave)
	column.add_child(next_wave_button)
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.pressed.connect(_pause_battle)
	column.add_child(pause_button)
	var restart_button := Button.new()
	restart_button.text = "Restart level"
	restart_button.pressed.connect(_restart_level)
	column.add_child(restart_button)


func _build_enemy_ui(column: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "DEBUG: PATH ENEMIES"
	column.add_child(title)
	enemy_selector = OptionButton.new()
	enemy_selector.add_item("Red sphere")
	enemy_selector.add_item("Blue sphere")
	column.add_child(enemy_selector)
	var spawn_button := Button.new()
	spawn_button.text = "Spawn selected enemy"
	spawn_button.pressed.connect(spawn_enemy)
	column.add_child(spawn_button)
	var reset_button := Button.new()
	reset_button.text = "Reset enemies"
	reset_button.pressed.connect(reset_enemies)
	column.add_child(reset_button)
	_add_enemy_spin(column, "red_speed", "Red speed", 0.0, 30.0, 0.1)
	_add_enemy_spin(column, "blue_speed", "Blue speed", 0.0, 30.0, 0.1)
	_add_enemy_spin(column, "red_scale", "Red visual scale", 0.1, 3.0, 0.05)
	_add_enemy_spin(column, "blue_scale", "Blue visual scale", 0.1, 3.0, 0.05)
	enemy_health_label = Label.new()
	column.add_child(enemy_health_label)


func _add_enemy_spin(column: VBoxContainer, key: String, caption: String, minimum: float, maximum: float, step: float) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)
	var label := Label.new()
	label.text = caption
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step
	spin.value = get(key)
	row.add_child(spin)
	spin.value_changed.connect(_set_enemy_value.bind(key))


func _refresh_hud() -> void:
	if currency_label == null:
		return
	currency_label.text = "Coins: %d" % currency
	objective_label.text = "Garden health: %d / %d" % [objective_health, starting_objective_health]
	wave_label.text = "Wave: %d / %d" % [waves.current_wave + 1, waves.waves.size()]
	enemies_label.text = "Enemies remaining: %d" % [waves.active_enemies + waves.remaining_to_spawn]
	next_wave_button.disabled = waves.state != WaveController.State.READY or battle_result != ""
	match waves.state:
		WaveController.State.READY:
			next_wave_button.text = "Start wave %d" % [waves.current_wave + 2]
		WaveController.State.SPAWNING:
			next_wave_button.text = "Wave in progress"
		WaveController.State.INTERMISSION:
			next_wave_button.text = "Next wave in %d s" % ceili(waves.break_remaining)
		WaveController.State.DONE:
			next_wave_button.text = "Waves complete"
	for index in tower_buttons.size():
		var definition := tower_definitions[TOWER_IDS[index]] as TowerDefinition
		tower_buttons[index].disabled = battle_result != "" or currency < definition.cost


func _pause_battle() -> void:
	if battle_result != "":
		return
	pause_overlay.show()
	get_tree().paused = true


func _resume_battle() -> void:
	get_tree().paused = false
	pause_overlay.hide()


func _restart_level() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/tower_placement.tscn")


func _return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _finish_battle(result: String) -> void:
	if battle_result != "":
		return
	battle_result = result
	waves.stop()
	for tower in placed_towers.get_children():
		tower.get_node("Attack").set_process(false)
	for child in path.get_children():
		if child is PlacementEnemy:
			child.set_process(false)
	$UI/ResultOverlay/Center/Panel/Actions/Title.text = "Garden defended!" if result == "victory" else "Garden overrun"
	result_overlay.show()
	_refresh_hud()
