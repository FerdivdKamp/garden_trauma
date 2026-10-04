extends PathFollow3D

signal health_changed

@export_range(0.0, 30.0, 0.1) var movement_speed := 3.0
@export_range(0.1, 3.0, 0.05) var visual_scale := 1.0:
	set(value):
		visual_scale = maxf(0.1, value)
		if is_node_ready():
			_update_visual_scale()

@onready var visual: MeshInstance3D = $Visual

var enemy_type := 0
var max_health := 50.0
var health := 50.0


func _ready() -> void:
	# Only the mesh is scaled: movement speed remains world units per second.
	_update_visual_scale()
	_update_color()


func _process(delta: float) -> void:
	if health > 0.0:
		var route := get_parent() as Path3D
		progress = minf(progress + movement_speed * delta, route.curve.get_baked_length())


func configure(type: int, speed: float, size: float) -> void:
	enemy_type = type
	movement_speed = speed
	visual_scale = size
	max_health = 50.0 if type == 0 else 75.0
	health = max_health
	if is_node_ready():
		_update_color()
	health_changed.emit()


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = TowerRules.health_after_hit(health, amount)
	_update_color()
	health_changed.emit()


func _update_color() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("555555") if health <= 0.0 else (Color("e96c6c") if enemy_type == 0 else Color("619de8"))
	visual.material_override = material


func _update_visual_scale() -> void:
	visual.scale = Vector3.ONE * visual_scale
	visual.position.y = 0.55 * visual_scale
