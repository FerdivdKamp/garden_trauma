extends Node3D

const TOWER_SCENE: PackedScene = preload("res://scenes/tower_visual.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/placement_enemy.tscn")
const PlacementEnemy = preload("res://scripts/placement_enemy.gd")
const PlacementTowerAttack = preload("res://scripts/placement_tower_attack.gd")
const GumballLaneAttack = preload("res://scripts/gumball_lane_attack.gd")
const GumballLane = preload("res://scripts/gumball_lane.gd")
const GumballLanePreview = preload("res://scripts/gumball_lane_preview.gd")
const ShotEffects = preload("res://scripts/placement_shot_effects.gd")
const TowerVisual = preload("res://scripts/tower_visual.gd")
const TileGrid = preload("res://scripts/level_grid.gd")
const GrassPaletteScript = preload("res://scripts/grass_palette.gd")
const GrassMaterialConfigScript = preload("res://scripts/grass_material_config.gd")
const TOWER_IDS := ["laser_tower", "double_tank", "lightning_tower", "water_rocket", "gumball"]
const GUMBALL_INDEX := 4
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

@export_range(0.0, 30.0, 0.1) var robot_speed := 3.0
@export_range(0.0, 30.0, 0.1) var blue_speed := 2.0
@export_range(0.1, 3.0, 0.05) var robot_scale := 1.0
@export_range(0.1, 3.0, 0.05) var blue_scale := 1.3

var selected_type := -1
var preview: Node3D
var lane_preview: Node3D
var lane_options: Array[Dictionary] = []
var lane_index := -1
var lane_cell := Vector2i(-999, -999)
var hovered_tower: Node3D
var selected_tower: Node3D
var upgrade_panel: PanelContainer
var upgrade_details: Label
var upgrade_button: Button
var help_panel: PanelContainer
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
var level_id := LevelProgress.DEFAULT_LEVEL_ID
var result_action_button: Button


func _enter_tree() -> void:
	# Child _ready calls load the grid and waves. Set their files first.
	level_id = LevelProgress.selected_level_id
	var level := LevelProgress.level_for(level_id)
	if level.is_empty():
		level_id = LevelProgress.DEFAULT_LEVEL_ID
		level = LevelProgress.level_for(level_id)
	$LevelGrid.level_file = level.map
	$Waves.schedule_file = level.waves


func _ready() -> void:
	if grid.grass_palette == GrassPaletteScript.SAVED_GARDEN:
		GrassMaterialConfigScript.apply_lighting($Sun, $WorldEnvironment, GrassMaterialConfigScript.load_settings())
	# Load once; scene nodes use typed definitions instead of JSON dictionaries.
	tower_definitions = DefinitionLoader.load_towers(DefinitionLoader.TOWER_OVERRIDE_DIR)
	unit_definitions = DefinitionLoader.load_units()
	assert(tower_definitions.has("laser_tower") and tower_definitions.has("double_tank") and tower_definitions.has("lightning_tower") and tower_definitions.has("water_rocket") and tower_definitions.has("gumball") and unit_definitions.has("windup_robot") and unit_definitions.has("blue_sphere"))
	robot_speed = (unit_definitions["windup_robot"] as UnitDefinition).speed
	blue_speed = (unit_definitions["blue_sphere"] as UnitDefinition).speed
	objective_health = starting_objective_health
	currency = starting_currency
	
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
	result_action_button = $UI/ResultOverlay/Center/Panel/Actions/NextLevel
	result_action_button.pressed.connect(_advance_from_result)
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
	if lane_preview != null:
		lane_preview.visible = has_ground_point
	if has_ground_point:
		var cell := grid.world_to_grid(ground_point)
		preview.position = grid.grid_to_world(cell)
		if selected_type == GUMBALL_INDEX and cell != lane_cell:
			_update_lane(cell)
		var valid := can_place_at(ground_point) and _can_afford_selected()
		preview.set_placement_valid(valid)
		if not _can_afford_selected():
			status.text = "Not enough currency for this tower"
		elif selected_type == GUMBALL_INDEX and lane_options.is_empty() and grid.is_buildable(cell):
			status.text = "No adjacent straight path lane"
		elif selected_type == GUMBALL_INDEX and valid:
			var option: Dictionary = lane_options[lane_index]
			status.text = "Gumball lane: %s - %d tiles (R to rotate)" % [option.name, option.cells.size()]
		else:
			status.text = "Click to place" if valid else "Blocked: path, rock, edge, or another tower"
	else:
		status.text = "Move over the ground to place"


func _unhandled_input(event: InputEvent) -> void:
	if battle_result != "":
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if selected_tower != null:
			_select_placed_tower(null)
		else:
			_select_tower(-1)
	elif debug_mode and event is InputEventKey and event.pressed and event.keycode == KEY_G:
		grid.show_grid = not grid.show_grid
	elif debug_mode and event is InputEventKey and event.pressed and event.keycode == KEY_C:
		grid.show_coordinates = not grid.show_coordinates
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R and selected_type == GUMBALL_INDEX and not event.echo:
		_cycle_lane()
	elif debug_mode and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		grid.show_route = not grid.show_route
	elif debug_mode and event is InputEventKey and event.pressed and event.keycode == KEY_I:
		_update_cursor(get_viewport().get_mouse_position())
		if has_ground_point:
			var cell := grid.world_to_grid(ground_point)
			print("Tile %s: %s, buildable=%s, walkable=%s" % [cell, grid.terrain_at(cell), grid.is_buildable(cell), grid.is_walkable(cell)])
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_update_cursor(event.position)
		_update_hovered_tower(event.position)
		if hovered_tower != null:
			_select_placed_tower(hovered_tower)
		elif preview != null and has_ground_point and can_place_at(ground_point) and _can_afford_selected():
			place_tower(ground_point)
		else:
			_select_placed_tower(null)


func _input(event: InputEvent) -> void:
	if battle_result != "":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_select_placed_tower(null)
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
	if hovered_tower != null and hovered_tower != selected_tower:
		hovered_tower.set_ranges_visible(false)
	hovered_tower = found
	if hovered_tower != null:
		hovered_tower.set_ranges_visible(true)


func can_place_at(point: Vector3) -> bool:
	var cell := grid.world_to_grid(point)
	if not grid.is_buildable(cell):
		return false
	if selected_type == GUMBALL_INDEX and GumballLane.lanes(grid, cell).is_empty():
		return false
	for tower in placed_towers.get_children():
		if grid.world_to_grid(tower.position) == cell:
			return false
	return true


func _setup_route() -> void:
	# PathFollow3D still drives the existing enemies. Its curve now comes from
	# the level's ordered tile route, so there is one source of path truth.
	# The Path3D Surface is hidden in this scene: the imported tiles draw the
	# sand and borders, while the curve alone handles enemy movement.
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
	# A placed tower uses the whole cell; remove its decorative meshes.
	var dressing := grid.get_node_or_null("Dressing") as LevelDressing
	if dressing != null:
		dressing.clear_cell(grid.world_to_grid(point))
	tower.set_tower_type(selected_type)
	tower.position = grid.grid_to_world(grid.world_to_grid(point))
	placed_towers.add_child(tower)
	tower.set_ranges(definition.attack_range, definition.detection_range)
	var attack: PlacementTowerAttack
	if selected_type == GUMBALL_INDEX:
		attack = GumballLaneAttack.new()
		if lane_cell != grid.world_to_grid(point):
			_update_lane(grid.world_to_grid(point))
		var option: Dictionary = lane_options[lane_index]
		tower.set_lane_direction(option.direction)
		(attack as GumballLaneAttack).configure_lane(option.direction, option.cells, grid)
	else:
		attack = PlacementTowerAttack.new()
	attack.name = "Attack"
	attack.definition = definition.copy()
	attack.enemies = path
	attack.effects = shot_effects
	tower.add_child(attack)
	if selected_type == GUMBALL_INDEX:
		# This lane choice belongs to this placement; clear its coverage overlay.
		_select_tower(-1)
	_refresh_hud()


func spawn_enemy(type: int = -1, from_wave: bool = false) -> PlacementEnemy:
	if type < 0:
		type = enemy_selector.selected if enemy_selector != null else 0
	var enemy := ENEMY_SCENE.instantiate() as PlacementEnemy
	var unit := unit_definitions["windup_robot" if type == 0 else "blue_sphere"] as UnitDefinition
	enemy_count += 1
	enemy.name = "Enemy%d" % enemy_count
	enemy.auto_cleanup = from_wave
	enemy.set_meta("wave_enemy", from_wave)
	enemy.configure(type, unit, robot_speed if type == 0 else blue_speed, robot_scale if type == 0 else blue_scale)
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
	var type := 0 if enemy_id == "windup_robot" else 1
	if enemy_id != "windup_robot" and enemy_id != "blue_sphere":
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
		if (enemy.enemy_type == 0 and key.begins_with("robot")) or (enemy.enemy_type == 1 and key.begins_with("blue")):
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
			lines.append("%s (%s): %.0f / %.0f HP" % [enemy.name, enemy.definition.name, enemy.health, enemy.max_health])
	enemy_health_label.text = "\n".join(lines)


func _select_tower(tower_type: int) -> void:
	if battle_result != "":
		return
	_select_placed_tower(null)
	selected_type = tower_type
	if preview != null:
		preview.queue_free()
		preview = null
	if lane_preview != null:
		lane_preview.queue_free()
		lane_preview = null
	lane_options.clear()
	lane_index = -1
	lane_cell = Vector2i(-999, -999)
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
	preview.set_ranges_visible(tower_type != GUMBALL_INDEX)
	if tower_type == GUMBALL_INDEX:
		lane_preview = GumballLanePreview.new()
		preview_holder.add_child(lane_preview)
	status.text = "Move over the ground to place"


func _update_lane(cell: Vector2i) -> void:
	lane_cell = cell
	if grid.is_buildable(cell):
		lane_options = GumballLane.lanes(grid, cell)
	else:
		lane_options.clear()
	lane_index = GumballLane.longest_index(lane_options)
	_show_selected_lane()


func _cycle_lane() -> void:
	if lane_options.is_empty():
		return
	lane_index = (lane_index + 1) % lane_options.size()
	_show_selected_lane()


func _show_selected_lane() -> void:
	if lane_preview == null:
		return
	var option: Dictionary = lane_options[lane_index] if lane_index >= 0 else {}
	lane_preview.show_lane(grid, lane_cell, option)
	if preview != null and not option.is_empty():
		preview.set_lane_direction(option.direction)


func _build_upgrade_ui() -> void:
	upgrade_panel = PanelContainer.new()
	upgrade_panel.visible = false
	# The selected tower's actions appear above the tile row without expanding it.
	$UI.add_child(upgrade_panel)
	$UI.move_child(upgrade_panel, pause_overlay.get_index())
	upgrade_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	upgrade_panel.offset_left = 12
	upgrade_panel.offset_top = -300
	upgrade_panel.offset_right = 276
	upgrade_panel.offset_bottom = -120
	upgrade_panel.custom_minimum_size = Vector2(264, 0)
	var contents := VBoxContainer.new()
	upgrade_panel.add_child(contents)
	upgrade_details = Label.new()
	upgrade_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrade_details.add_theme_font_size_override("font_size", 15)
	contents.add_child(upgrade_details)
	upgrade_button = Button.new()
	upgrade_button.text = "Upgrade"
	upgrade_button.pressed.connect(_buy_selected_upgrade)
	contents.add_child(upgrade_button)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(func() -> void: _select_placed_tower(null))
	contents.add_child(close_button)


func _select_placed_tower(tower: Node3D) -> void:
	if tower != null and selected_type >= 0:
		selected_type = -1
		if preview != null:
			preview.queue_free()
			preview = null
		if lane_preview != null:
			lane_preview.queue_free()
			lane_preview = null
		for button in tower_buttons:
			button.button_pressed = false
	if selected_tower != null and selected_tower != hovered_tower:
		selected_tower.set_ranges_visible(false)
	selected_tower = tower
	if selected_tower != null:
		selected_tower.set_ranges_visible(true)
	_refresh_upgrade_ui()


func _refresh_upgrade_ui() -> void:
	if upgrade_panel == null:
		return
	upgrade_panel.visible = selected_tower != null and battle_result == ""
	if not upgrade_panel.visible:
		return
	var attack := selected_tower.get_node("Attack") as PlacementTowerAttack
	var definition := attack.definition
	var upgrade := attack.next_upgrade()
	var stats := "Damage %.0f  •  Cooldown %.2fs  •  Speed %.1f  •  Balls %d" % [definition.damage, definition.cooldown, definition.projectile_speed, definition.ball_count] if definition.id == "gumball" else "Damage %.0f  •  Cooldown %.2fs  •  Range %.1f" % [definition.damage, definition.cooldown, definition.attack_range]
	if upgrade.is_empty():
		upgrade_details.text = "%s  |  Level 3/3\n%s" % [definition.name, stats]
		upgrade_button.disabled = true
		upgrade_button.text = "Max level"
		upgrade_button.tooltip_text = "This tower is fully upgraded."
		return
	var changes: PackedStringArray = []
	for key in upgrade.attack:
		var property_name: String = "attack_range" if key == "range" else key
		var old_value: float = definition.get(property_name)
		var new_value: float = float(upgrade.attack[key])
		changes.append("%s: %s → %s" % [key.capitalize(), _stat_text(old_value), _stat_text(new_value)])
	upgrade_details.text = "%s  |  Level %d/3\n%s" % [definition.name, attack.upgrade_level, stats]
	upgrade_button.text = "Upgrade  •  %d coins" % int(upgrade.cost)
	upgrade_button.tooltip_text = "%s — %d coins\n%s" % [upgrade.name, int(upgrade.cost), "\n".join(changes)]
	upgrade_panel.tooltip_text = upgrade_button.tooltip_text
	upgrade_button.disabled = currency < int(upgrade.cost)


func _stat_text(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else str(value)


func _buy_selected_upgrade() -> void:
	if selected_tower == null or battle_result != "":
		return
	var attack := selected_tower.get_node("Attack") as PlacementTowerAttack
	var paid := attack.buy_next_upgrade(currency)
	if paid > 0:
		currency -= paid
		_refresh_hud()


func _build_ui() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	palette.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	column.add_child(row)
	for index in TOWER_IDS.size():
		var tile := Button.new()
		var definition := tower_definitions[TOWER_IDS[index]] as TowerDefinition
		tile.custom_minimum_size = Vector2(72, 66)
		tile.tooltip_text = "%s — %d coins" % [definition.name, definition.cost]
		tile.icon = _make_tower_thumbnail(index)
		tile.expand_icon = true
		tile.toggle_mode = true
		tile.pressed.connect(_select_tower.bind(index))
		row.add_child(tile)
		tower_buttons.append(tile)
	status = Label.new()
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	_build_upgrade_ui()
	var hud := VBoxContainer.new()
	hud.add_theme_constant_override("separation", 4)
	enemy_panel.add_child(hud)
	_build_battle_ui(hud)
	help_panel = PanelContainer.new()
	help_panel.visible = AudioSettings.hints_enabled
	$UI.add_child(help_panel)
	$UI.move_child(help_panel, pause_overlay.get_index())
	help_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	help_panel.position = Vector2(12, 12)
	var help_column := VBoxContainer.new()
	help_panel.add_child(help_column)
	var help := Label.new()
	help.text = "Select a tower tile, then click grass to build.\nClick a placed tower to upgrade. Right-click or Esc cancels.\nEnemies reaching FINISH reduce garden life."
	help.add_theme_font_size_override("font_size", 15)
	help_column.add_child(help)
	help_column.add_child(enemies_label)
	if debug_mode:
		_build_enemy_ui(hud)


func _make_tower_thumbnail(index: int) -> Texture2D:
	# Each icon renders the same scene as the placed tower, so artwork stays in sync.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(96, 96)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	$UI.add_child(viewport)
	var tower := TOWER_SCENE.instantiate()
	tower.set_tower_type(index)
	viewport.add_child(tower)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	viewport.add_child(light)
	var icon_camera := Camera3D.new()
	icon_camera.position = Vector3(2.5, 3.3, 4.5)
	icon_camera.fov = 40.0
	viewport.add_child(icon_camera)
	icon_camera.look_at(Vector3(0, 0.9, 0))
	icon_camera.current = true
	# The model is static in this icon; render one frame to avoid three extra
	# 3D views running throughout the battle.
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	return viewport.get_texture()


func _build_battle_ui(column: VBoxContainer) -> void:
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 12)
	column.add_child(stats)
	currency_label = Label.new()
	stats.add_child(currency_label)
	objective_label = Label.new()
	stats.add_child(objective_label)
	wave_label = Label.new()
	stats.add_child(wave_label)
	enemies_label = Label.new()
	enemies_label.add_theme_font_size_override("font_size", 15)
	next_wave_button = Button.new()
	next_wave_button.text = "Start wave 1"
	next_wave_button.pressed.connect(waves.start_next_wave)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	column.add_child(actions)
	actions.add_child(next_wave_button)
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.pressed.connect(_pause_battle)
	actions.add_child(pause_button)


func _build_enemy_ui(column: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "DEBUG: PATH ENEMIES"
	column.add_child(title)
	enemy_selector = OptionButton.new()
	enemy_selector.add_item("Wind-up Robot")
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
	_add_enemy_spin(column, "robot_speed", "Robot speed", 0.0, 30.0, 0.1)
	_add_enemy_spin(column, "blue_speed", "Blue speed", 0.0, 30.0, 0.1)
	_add_enemy_spin(column, "robot_scale", "Robot visual scale", 0.1, 3.0, 0.05)
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
	currency_label.text = "◈ %d" % currency
	objective_label.text = "♥ %d/%d" % [objective_health, starting_objective_health]
	wave_label.text = "Wave %d/%d" % [waves.current_wave + 1, waves.waves.size()]
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
	_refresh_upgrade_ui()


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
	get_tree().change_scene_to_file(LevelProgress.BATTLE_SCENE)


func _return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _advance_from_result() -> void:
	var next_id := LevelProgress.next_level_id(level_id)
	if battle_result == "victory" and next_id != "" and LevelProgress.select_level(next_id):
		get_tree().change_scene_to_file(LevelProgress.BATTLE_SCENE)
	else:
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _finish_battle(result: String) -> void:
	if battle_result != "":
		return
	battle_result = result
	if result == "victory":
		LevelProgress.complete_level(level_id)
	waves.stop()
	for tower in placed_towers.get_children():
		tower.get_node("Attack").set_process(false)
	for child in path.get_children():
		if child is PlacementEnemy:
			child.set_process(false)
	$UI/ResultOverlay/Center/Panel/Actions/Title.text = "Garden defended!" if result == "victory" else "Garden overrun"
	var next_id := LevelProgress.next_level_id(level_id)
	result_action_button.text = "Next level" if result == "victory" and next_id != "" else "Level selection"
	result_overlay.show()
	_refresh_hud()
