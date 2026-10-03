extends Node3D

const TOWER_SAVE_PREFIX := "user://tower_"
const PAWN_SAVE_PATH := "user://pawn.json"
const SHOT_INTERVAL := 1.0

@onready var turret_pivot: Node3D = $Tower/TurretPivot
@onready var pawn: Node3D = $Pawn
@onready var detection_ring: MeshInstance3D = $DetectionRing
@onready var attack_ring: MeshInstance3D = $AttackRing
@onready var settings_panel: PanelContainer = $UI/SettingsPanel

var tower_type := 0
var detection_radius := 9.0
var attack_radius := 6.0
var turn_speed := 90.0
var damage := 10.0
var pawn_distance := 8.0
var pawn_health := 50.0
var shot_clock := 0.0

var fields: Dictionary = {}
var tower_selector: OptionButton
var status_label: Label
var pawn_visual: MeshInstance3D


func _ready() -> void:
	$Camera.look_at(Vector3.ZERO, Vector3.UP)
	_build_ground()
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

	shot_clock += delta
	var aimed := absf(angle_difference(turret_pivot.rotation.y, desired_yaw)) < deg_to_rad(5.0)
	if shot_clock >= SHOT_INTERVAL and aimed and pawn_health > 0.0 and \
			TowerRules.can_attack(pawn_distance, attack_radius, detection_radius):
		shot_clock = 0.0
		pawn_health = TowerRules.health_after_hit(pawn_health, damage)
		_set_field_without_signal("pawn_health", pawn_health)
		_update_pawn_color()
	_update_status()


func _build_ground() -> void:
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(36.0, 36.0)
	$Ground.mesh = ground_mesh
	$Ground.material_override = _material(Color("384b3b"))

	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.85
	base_mesh.bottom_radius = 1.05
	base_mesh.height = 0.8
	var base := _mesh_instance(base_mesh, Color("718aa2"))
	base.position.y = 0.4
	$Tower.add_child(base)
	_build_turret()


func _build_turret() -> void:
	for child in turret_pivot.get_children():
		child.queue_free()
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.55
	cap_mesh.bottom_radius = 0.65
	cap_mesh.height = 0.38
	var cap := _mesh_instance(cap_mesh, Color("a9bed0"))
	cap.position.y = 0.14
	turret_pivot.add_child(cap)

	var offsets := [0.0] if tower_type == 0 else [-0.29, 0.29]
	for offset in offsets:
		var barrel_mesh := BoxMesh.new()
		barrel_mesh.size = Vector3(0.22, 0.22, 1.45)
		var barrel := _mesh_instance(barrel_mesh, Color("e5c46b"))
		barrel.position = Vector3(offset, 0.17, -0.85)
		turret_pivot.add_child(barrel)


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
	help.text = "Outer ring: detection   •   Inner ring: attack\nThe tower fires once per second when aimed."
	column.add_child(help)

	tower_selector = OptionButton.new()
	tower_selector.add_item("Single barrel")
	tower_selector.add_item("Double barrel")
	tower_selector.item_selected.connect(_on_tower_selected)
	column.add_child(tower_selector)

	_add_field(column, "detection_radius", "Detection radius", 2.0, 12.0, 0.1, detection_radius)
	_add_field(column, "attack_radius", "Attack radius", 1.0, 12.0, 0.1, attack_radius)
	_add_field(column, "turn_speed", "Turn speed (°/s)", 0.0, 360.0, 1.0, turn_speed)
	_add_field(column, "damage", "Damage / shot", 0.0, 100.0, 1.0, damage)
	_add_button(column, "Reset barrel away from pawn", _reset_aim)
	_add_button(column, "Save tower parameters", _save_tower)

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
		"pawn_distance": pawn_distance = value
		"pawn_health": pawn_health = value
	_refresh_visuals()


func _set_field_without_signal(key: String, value: float) -> void:
	if not fields.has(key):
		return
	fields[key]["slider"].set_value_no_signal(value)
	fields[key]["number"].set_value_no_signal(value)


func _refresh_visuals() -> void:
	pawn.position = Vector3(pawn_distance, 0.0, 0.0)
	_draw_ring(detection_ring, detection_radius, Color("70bce8"), 0.05)
	_draw_ring(attack_ring, attack_radius, Color("f5d06b"), 0.07)
	_update_pawn_color()
	_update_status()


func _draw_ring(instance: MeshInstance3D, radius: float, color: Color, height: float) -> void:
	var ring := ImmediateMesh.new()
	ring.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for index in range(65):
		var angle := TAU * float(index) / 64.0
		ring.surface_add_vertex(Vector3(cos(angle) * radius, height, sin(angle) * radius))
	ring.surface_end()
	instance.mesh = ring
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	instance.material_override = material


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
	_build_turret()
	_load_tower()
	_reset_aim()
	_refresh_visuals()


func _tower_path() -> String:
	return TOWER_SAVE_PREFIX + ("single" if tower_type == 0 else "double") + ".json"


func _save_tower() -> void:
	_write_json(_tower_path(), {
		"detection_radius": detection_radius,
		"attack_radius": attack_radius,
		"turn_speed": turn_speed,
		"damage": damage
	})


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
	var data := _read_json(_tower_path())
	detection_radius = clampf(float(data.get("detection_radius", 9.0)), 2.0, 12.0)
	attack_radius = clampf(float(data.get("attack_radius", 6.0)), 1.0, detection_radius)
	turn_speed = clampf(float(data.get("turn_speed", 90.0)), 0.0, 360.0)
	damage = clampf(float(data.get("damage", 10.0)), 0.0, 100.0)
	for key in ["detection_radius", "attack_radius", "turn_speed", "damage"]:
		_set_field_without_signal(key, get(key))


func _load_pawn() -> void:
	var data := _read_json(PAWN_SAVE_PATH)
	pawn_distance = clampf(float(data.get("distance", 8.0)), 0.0, 14.0)
	pawn_health = clampf(float(data.get("health", 50.0)), 0.0, 500.0)
	_set_field_without_signal("pawn_distance", pawn_distance)
	_set_field_without_signal("pawn_health", pawn_health)
