extends PathFollow3D

signal health_changed
signal defeated(enemy: Node)
signal objective_reached(enemy: Node)

@export_range(0.0, 30.0, 0.1) var movement_speed := 3.0
@export_range(0.1, 3.0, 0.05) var visual_scale := 1.0:
	set(value):
		visual_scale = maxf(0.1, value)
		if is_node_ready():
			_update_visual_scale()

@onready var visual: MeshInstance3D = $Visual
@onready var destroyed_audio: AudioStreamPlayer3D = $DestroyedAudio
@onready var objective_audio: AudioStreamPlayer3D = $ObjectiveAudio

var enemy_type := 0
var definition: UnitDefinition
var max_health := 50.0
var health := 50.0
var reached_objective := false
var auto_cleanup := true


func _ready() -> void:
	# Only the mesh is scaled: movement speed remains world units per second.
	_update_visual_scale()
	_update_color()


func _process(delta: float) -> void:
	if health > 0.0 and not reached_objective:
		var route := get_parent() as Path3D
		progress = minf(progress + movement_speed * delta, route.curve.get_baked_length())
		if progress >= route.curve.get_baked_length():
			reached_objective = true
			objective_audio.play()
			objective_reached.emit(self)
			_finish_after_sound(objective_audio)


func configure(type: int, unit: UnitDefinition, speed: float, size: float) -> void:
	enemy_type = type
	definition = unit
	movement_speed = speed
	visual_scale = size
	max_health = unit.health
	health = max_health
	reached_objective = false
	if is_node_ready():
		_update_color()
	health_changed.emit()


func take_damage(amount: float) -> void:
	if health <= 0.0 or reached_objective:
		return
	health = TowerRules.health_after_hit(health, amount)
	if health <= 0.0:
		destroyed_audio.play()
		defeated.emit(self)
		_finish_after_sound(destroyed_audio)
	_update_color()
	health_changed.emit()


func _update_color() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("555555") if health <= 0.0 else (Color("e96c6c") if enemy_type == 0 else Color("619de8"))
	visual.material_override = material


func _update_visual_scale() -> void:
	visual.scale = Vector3.ONE * visual_scale
	visual.position.y = 0.55 * visual_scale


func _finish_after_sound(audio: AudioStreamPlayer3D) -> void:
	if not auto_cleanup:
		return
	visual.hide()
	# The audio player remains in the world until its one-shot has finished.
	audio.finished.connect(queue_free, CONNECT_ONE_SHOT)
