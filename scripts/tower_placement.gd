extends Node3D

const TOWER_SCENE: PackedScene = preload("res://scenes/tower_visual.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/placement_enemy.tscn")
const PlacementEnemy = preload("res://scripts/placement_enemy.gd")
const PlacementTowerAttack = preload("res://scripts/placement_tower_attack.gd")
const ShotEffects = preload("res://scripts/placement_shot_effects.gd")
const TowerVisual = preload("res://scripts/tower_visual.gd")
const TileGrid = preload("res://scripts/level_grid.gd")
const TOWER_IDS := ["laser_tower", "double_tank", "lightning_tower"]
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
var selected_tower: Node3D
var upgrade_panel: PanelContainer
var upgrade_details: Label
var upgrade_button: Button
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
	# Load once; scene nodes use typed definitions instead of JSON dictionaries.
	tower_definitions = DefinitionLoader.load_towers(DefinitionLoader.TOWER_OVERRIDE_DIR)
	unit_definitions = DefinitionLoader.load_units()
	assert(tower_definitions.has("laser_tower") and tower_definitions.has("double_tank") and tower_definitions.has("lightning_tower") and unit_definitions.has("red_sphere") and unit_definitions.has("blue_sphere"))
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
		if selected_tower != null:
			_select_placed_tower(null)
		else:
			_select_tower(-1)
	elif debug_mode and event is InputEventKey and event.pressed and event.keycode == KEY_G:
		grid.show_grid = not grid.show_grid
	elif debug_mode and event is InputEventKey and event.pressed and event.keycode == KEY_C:
		grid.show_coordinates = not grid.show_coordinates
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
	# A placed tower uses the whole cell; remove its decorative meshes.
	var dressing := grid.get_node_or_null("Dressing") as LevelDressing
	if dressing != null:
		dressing.clear_cell(grid.world_to_grid(point))
	tower.set_tower_type(selected_type)
	tower.position = grid.grid_to_world(grid.world_to_grid(point))
	placed_towers.add_child(tower)
	tower.set_ranges(definition.attack_range, definition.detection_range)
	var attack := PlacementTowerAttack.new()
	attack.name = "Attack"
	attack.definition = definition.copy()
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
	_select_placed_tower(null)
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


func _build_upgrade_ui(column: VBoxContainer) -> void:
	upgrade_panel = PanelContainer.new()
	upgrade_panel.visible = false
	column.add_child(upgrade_panel)
	var contents := VBoxContainer.new()
	upgrade_panel.add_child(contents)
	upgrade_details = Label.new()
	upgrade_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contents.add_child(upgrade_details)
	upgrade_button = Button.new()
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
	var stats := "Damage %.0f   Cooldown %.2fs   Range %.1f   Speed %.1f" % [definition.damage, definition.cooldown, definition.attack_range, definition.projectile_speed]
	if upgrade.is_empty():
		upgrade_details.text = "%s  |  Level 3/3\n%s\nFully upgraded" % [definition.name, stats]
		upgrade_button.disabled = true
		upgrade_button.text = "Max level"
		return
	var changes: PackedStringArray = []
	for key in upgrade.attack:
		changes.append("%s: %s" % [key.capitalize(), str(upgrade.attack[key])])
	upgrade_details.text = "%s  |  Level %d/3\n%s\nNext: %s (%d coins)\nReplaces %s" % [definition.name, attack.upgrade_level, stats, upgrade.name, upgrade.cost, ", ".join(changes)]
	upgrade_button.text = "Buy %s - %d coins" % [upgrade.name, upgrade.cost]
	upgrade_button.disabled = currency < int(upgrade.cost)


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
	help.text = "Select a tower, then click grass to place it.\nClick a placed tower to upgrade it.\nRight-click or Esc: cancel selection."
	if debug_mode:
		help.text += "\nDebug: G grid  C coords  R route  I inspect"
	column.add_child(help)
	_build_upgrade_ui(column)
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
	var hint := Label.new()
	hint.text = "Garden health: enemies that reach GOAL reduce it.\nBuild towers, then press Start wave."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)
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
