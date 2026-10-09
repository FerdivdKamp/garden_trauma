extends Node3D

const PAWN_SAVE_PATH := "user://pawn.json"
const TOWER_IDS := ["laser_tower", "double_tank", "lightning_tower"]
const TowerVisual = preload("res://scripts/tower_visual.gd")
const LightningEffect = preload("res://scripts/lightning_effect.gd")

@onready var tower_visual: TowerVisual = $Tower
@onready var turret_pivot: Node3D = tower_visual.get_yaw_pivot()
@onready var pawn: Node3D = $Pawn
@onready var lightning_effect: LightningEffect = $LightningEffect
@onready var settings_panel: PanelContainer = $UI/SettingsPanel

var tower_type := 0
var detection_radius := 9.0
var attack_radius := 6.0
var turn_speed := 90.0
var damage := 10.0
var fire_rate := 1.0
var pawn_distance := 8.0
var pawn_health := 50.0
var shot_clock := 0.0
var tower_definitions: Dictionary
var definition: TowerDefinition

var fields: Dictionary = {}
var tower_selector: OptionButton
var status_label: Label
var pawn_visual: MeshInstance3D


func _ready() -> void:
	tower_definitions = DefinitionLoader.load_towers(DefinitionLoader.TOWER_OVERRIDE_DIR)
	_migrate_legacy_tower_saves()
	$Camera.look_at(Vector3.ZERO, Vector3.UP)
	_build_pawn()
	_build_ui()
	_load_tower()
	_load_pawn()
	_refresh_visuals()
	# The reset action starts with the barrel facing away from the pawn.
	_reset_aim()


func _process(delta: float) -> void:
	var direction := pawn.global_position - turret_pivot.global_position
	var desired_yaw := TowerRules.target_yaw(direction)
	if TowerRules.can_detect(pawn_distance, detection_radius) and pawn_health > 0.0:
		turret_pivot.rotation.y = TowerRules.step_yaw(
			turret_pivot.rotation.y, desired_yaw, deg_to_rad(turn_speed), delta
		)
		if tower_type == 0:
			tower_visual.aim_pitch_at(pawn_visual.global_position, turn_speed, delta)

	shot_clock += delta
	var aimed := absf(angle_difference(turret_pivot.rotation.y, desired_yaw)) < deg_to_rad(5.0)
	if shot_clock >= definition.cooldown and aimed and pawn_health > 0.0 and \
			TowerRules.can_attack(pawn_distance, attack_radius, detection_radius):
		shot_clock = 0.0
		if tower_type == 2:
			lightning_effect.strike(tower_visual.get_muzzle_position(), pawn_visual.global_position)
		pawn_health = TowerRules.health_after_hit(pawn_health, definition.damage)
		_set_field_without_signal("pawn_health", pawn_health)
		_update_pawn_color()
	_update_status()


func _build_pawn() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	pawn_visual = _mesh_instance(sphere, Color("e96c6c"))
	pawn_visual.position.y = 0.55
	pawn.add_child(pawn_visual)


func _mesh_instance(shape: Mesh, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.material_override = _material(color)
	return instance


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	return material


func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	settings_panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	scroll.add_child(column)

	var title := Label.new()
	title.text = "TOWER PLAYGROUND"
	column.add_child(title)
	var help := Label.new()
	help.text = "Yellow area: detection   •   Green area: attack\nThe tower fires when aimed and its cooldown has elapsed."
	column.add_child(help)

	tower_selector = OptionButton.new()
	tower_selector.add_item("Laser Tower")
	tower_selector.add_item("Double barrel")
	tower_selector.add_item("Lightning tower")
	tower_selector.item_selected.connect(_on_tower_selected)
	column.add_child(tower_selector)

	_add_field(column, "detection_radius", "Detection radius", 2.0, 12.0, 0.1, detection_radius)
	_add_field(column, "attack_radius", "Attack radius", 1.0, 12.0, 0.1, attack_radius)
	_add_field(column, "turn_speed", "Turn speed (°/s)", 0.0, 360.0, 1.0, turn_speed)
	_add_field(column, "damage", "Damage / shot", 0.0, 100.0, 1.0, damage)
	_add_field(column, "fire_rate", "Fire rate (shots/s)", 0.1, 10.0, 0.1, fire_rate)
	_add_button(column, "Reset barrel away from pawn", _reset_aim)
	_add_button(column, "Save tower definition", _save_tower)

	var pawn_title := Label.new()
	pawn_title.text = "PAWN"
	column.add_child(pawn_title)
	_add_field(column, "pawn_distance", "Distance", 0.0, 14.0, 0.1, pawn_distance)
	_add_field(column, "pawn_health", "Health", 0.0, 500.0, 1.0, pawn_health)
	_add_button(column, "Save pawn parameters", _save_pawn)

	status_label = Label.new()
	column.add_child(status_label)
	_update_status()


func _add_field(parent: VBoxContainer, key: String, caption: String, minimum: float, maximum: float, increment: float, initial: float) -> void:
	var label := Label.new()
	label.text = caption
	parent.add_child(label)
	var row := HBoxContainer.new()
	parent.add_child(row)
	var slider := HSlider.new()
	slider.custom_minimum_size.x = 205.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = increment
	slider.value = initial
	row.add_child(slider)
	var number := SpinBox.new()
	number.custom_minimum_size.x = 90.0
	number.min_value = minimum
	number.max_value = maximum
	number.step = increment
	number.value = initial
	row.add_child(number)
	fields[key] = {"slider": slider, "number": number}
	slider.value_changed.connect(_on_field_changed.bind(key, number))
	number.value_changed.connect(_on_field_changed.bind(key, slider))


func _add_button(parent: VBoxContainer, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(callback)
	parent.add_child(button)


func _on_field_changed(value: float, key: String, partner: Range) -> void:
	partner.set_value_no_signal(value)
	match key:
		"detection_radius":
			detection_radius = value
			if attack_radius > detection_radius:
				attack_radius = detection_radius
				_set_field_without_signal("attack_radius", attack_radius)
		"attack_radius":
			attack_radius = minf(value, detection_radius)
			_set_field_without_signal("attack_radius", attack_radius)
		"turn_speed": turn_speed = value
		"damage": damage = value
		"fire_rate": fire_rate = value
		"pawn_distance": pawn_distance = value
		"pawn_health": pawn_health = value
	if definition != null:
		definition.detection_range = detection_radius
		definition.attack_range = attack_radius
		definition.turn_speed = turn_speed
		definition.damage = damage
		# Gameplay uses seconds between shots; the UI uses shots per second.
		definition.cooldown = 1.0 / fire_rate
	_refresh_visuals()


func _set_field_without_signal(key: String, value: float) -> void:
	if not fields.has(key):
		return
	fields[key]["slider"].set_value_no_signal(value)
	fields[key]["number"].set_value_no_signal(value)


func _refresh_visuals() -> void:
	pawn.position = Vector3(pawn_distance, 0.0, 0.0)
	$Tower.set_ranges(attack_radius, detection_radius)
	$Tower.set_ranges_visible(true)
	_update_pawn_color()
	_update_status()


func _update_pawn_color() -> void:
	if pawn_visual == null:
		return
	pawn_visual.material_override = _material(Color("555555") if pawn_health <= 0.0 else Color("e96c6c"))


func _update_status() -> void:
	if status_label == null:
		return
	var state := "OUTSIDE DETECTION"
	if pawn_health <= 0.0:
		state = "PAWN DEFEATED — raise health to retry"
	elif TowerRules.can_attack(pawn_distance, attack_radius, detection_radius):
		state = "IN ATTACK RANGE"
	elif TowerRules.can_detect(pawn_distance, detection_radius):
		state = "DETECTED — outside attack range"
	status_label.text = "%s\nPawn health: %.0f" % [state, pawn_health]


func _reset_aim() -> void:
	var direction := pawn.global_position - turret_pivot.global_position
	turret_pivot.rotation.y = TowerRules.target_yaw(direction) + PI
	shot_clock = 0.0


func _on_tower_selected(index: int) -> void:
	tower_type = index
	$Tower.set_tower_type(index)
	turret_pivot = tower_visual.get_yaw_pivot()
	_load_tower()
	_reset_aim()
	_refresh_visuals()


func _tower_id() -> String:
	return TOWER_IDS[tower_type]


func _migrate_legacy_tower_saves() -> void:
	# Older playground builds saved only four fields. Keep those edits when moving
	# to complete tower definitions, leaving all other fields at their defaults.
	for id in ["laser_tower", "double_tank"]:
		var override_path := DefinitionLoader.TOWER_OVERRIDE_DIR.path_join(id + ".json")
		if FileAccess.file_exists(override_path):
			continue
		var old_name := "single" if id == "laser_tower" else "double"
		var old_path := "user://tower_%s.json" % old_name
		if not FileAccess.file_exists(old_path):
			continue
		var data := _read_json(old_path)
		var tower := tower_definitions[id] as TowerDefinition
		tower.detection_range = clampf(float(data.get("detection_radius", tower.detection_range)), 2.0, 12.0)
		tower.attack_range = clampf(float(data.get("attack_radius", tower.attack_range)), 1.0, tower.detection_range)
		tower.turn_speed = clampf(float(data.get("turn_speed", tower.turn_speed)), 0.0, 360.0)
		tower.damage = clampf(float(data.get("damage", tower.damage)), 0.0, 100.0)
		# Save writes the imported values in the new format when the player asks.


func _save_tower() -> void:
	DefinitionLoader.save_tower_override(definition)


func _save_pawn() -> void:
	_write_json(PAWN_SAVE_PATH, {"distance": pawn_distance, "health": pawn_health})


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary else {}


func _load_tower() -> void:
	definition = tower_definitions[_tower_id()] as TowerDefinition
	detection_radius = definition.detection_range
	attack_radius = definition.attack_range
	turn_speed = definition.turn_speed
	damage = definition.damage
	fire_rate = 1.0 / definition.cooldown
	for key in ["detection_radius", "attack_radius", "turn_speed", "damage", "fire_rate"]:
		_set_field_without_signal(key, get(key))


func _load_pawn() -> void:
	var data := _read_json(PAWN_SAVE_PATH)
	pawn_distance = clampf(float(data.get("distance", 8.0)), 0.0, 14.0)
	pawn_health = clampf(float(data.get("health", 50.0)), 0.0, 500.0)
	_set_field_without_signal("pawn_distance", pawn_distance)
	_set_field_without_signal("pawn_health", pawn_health)
