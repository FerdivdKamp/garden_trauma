extends Node3D

const TOWER_SCENE: PackedScene = preload("res://scenes/tower_visual.tscn")
const GROUND_HALF_SIZE := 18.0
const TOWER_RADIUS := 1.05

@onready var camera: Camera3D = $Camera
@onready var path: Path3D = $PlacementPath
@onready var placed_towers: Node3D = $PlacedTowers
@onready var preview_holder: Node3D = $Preview
@onready var palette: PanelContainer = $UI/Palette

var selected_type := -1
var preview: Node3D
var has_ground_point := false
var ground_point := Vector3.ZERO
var status: Label
var tower_buttons: Array[Button] = []


func _ready() -> void:
	camera.look_at(Vector3.ZERO, Vector3.UP)
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2.ONE * GROUND_HALF_SIZE * 2.0
	$Ground.mesh = ground_mesh
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("384b3b")
	$Ground.material_override = ground_material
	_build_ui()


func _process(_delta: float) -> void:
	if preview == null:
		return
	_update_cursor(get_viewport().get_mouse_position())
	preview.visible = has_ground_point
	if has_ground_point:
		preview.position = ground_point
		preview.set_placement_valid(can_place_at(ground_point))
		status.text = "Click to place" if can_place_at(ground_point) else "Blocked: path, edge, or another tower"
	else:
		status.text = "Move over the ground to place"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_select_tower(-1)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_update_cursor(event.position)
		if preview != null and has_ground_point and can_place_at(ground_point):
			place_tower(ground_point)


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


func can_place_at(point: Vector3) -> bool:
	if absf(point.x) > GROUND_HALF_SIZE - TOWER_RADIUS or absf(point.z) > GROUND_HALF_SIZE - TOWER_RADIUS:
		return false
	if path.blocks_circle(point, TOWER_RADIUS):
		return false
	for tower in placed_towers.get_children():
		var delta := Vector2(point.x - tower.position.x, point.z - tower.position.z)
		if delta.length() < TOWER_RADIUS * 2.0:
			return false
	return true


func place_tower(point: Vector3) -> void:
	if selected_type < 0 or not can_place_at(point):
		return
	var tower := TOWER_SCENE.instantiate()
	tower.set_tower_type(selected_type)
	tower.position = point
	placed_towers.add_child(tower)


func _select_tower(tower_type: int) -> void:
	selected_type = tower_type
	if preview != null:
		preview.queue_free()
		preview = null
	for index in tower_buttons.size():
		tower_buttons[index].button_pressed = index == tower_type
	if tower_type < 0:
		status.text = "Select a tower tile. Esc cancels selection."
		return
	preview = TOWER_SCENE.instantiate()
	preview.set_tower_type(tower_type)
	preview.set_preview(true)
	preview_holder.add_child(preview)
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
	for index in 2:
		var tile := Button.new()
		tile.text = "SINGLE\nBARREL" if index == 0 else "DOUBLE\nBARREL"
		tile.custom_minimum_size = Vector2(125, 100)
		tile.toggle_mode = true
		tile.pressed.connect(_select_tower.bind(index))
		row.add_child(tile)
		tower_buttons.append(tile)
	status = Label.new()
	status.text = "Select a tower tile. Esc cancels selection."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	var help := Label.new()
	help.text = "Green ground: buildable\nTan path: no towers\nClick to place repeatedly"
	column.add_child(help)
