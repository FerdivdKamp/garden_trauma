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

@onready var visual: Node3D = $Visual
@onready var sphere: MeshInstance3D = $Visual/Sphere
@onready var robot: Node3D = $Visual/Robot
@onready var destroyed_audio: AudioStreamPlayer3D = $DestroyedAudio
@onready var objective_audio: AudioStreamPlayer3D = $ObjectiveAudio

var arm_left: Node3D
var arm_right: Node3D
var leg_left: Node3D
var leg_right: Node3D
var head: Node3D
var antenna: Node3D
var key: Node3D
var animation_time := 0.0

var enemy_type := 0
var definition: UnitDefinition
var max_health := 50.0
var health := 50.0
var reached_objective := false
var auto_cleanup := true


func _ready() -> void:
	# Only the mesh is scaled: movement speed remains world units per second.
	_bind_robot_pivots()
	_update_visual_scale()
	_update_color()


func _process(delta: float) -> void:
	if health > 0.0 and not reached_objective:
		_animate_robot(delta)
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
	robot.visible = enemy_type == 0
	sphere.visible = enemy_type != 0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("555555") if health <= 0.0 else Color("619de8")
	sphere.material_override = material


func _update_visual_scale() -> void:
	visual.scale = Vector3.ONE * visual_scale


func _bind_robot_pivots() -> void:
	# Blender empties become Node3D pivots in the imported GLB. Look them up
	# inside the model so these references survive a later Blender re-export.
	arm_left = robot.find_child("Arm_L_Pivot", true, false) as Node3D
	arm_right = robot.find_child("Arm_R_Pivot", true, false) as Node3D
	leg_left = robot.find_child("Leg_L_Pivot", true, false) as Node3D
	leg_right = robot.find_child("Leg_R_Pivot", true, false) as Node3D
	head = robot.find_child("Head_Pivot", true, false) as Node3D
	antenna = robot.find_child("Antenna_pivot", true, false) as Node3D
	key = robot.find_child("Key_Pivot", true, false) as Node3D
	assert(arm_left and arm_right and leg_left and leg_right and head and antenna and key)


func _animate_robot(delta: float) -> void:
	if enemy_type != 0:
		return
	animation_time += delta
	var stride := sin(animation_time * 8.0) * 0.35
	# The robot faces local -X, so local Z is the sideways hinge axis.
	leg_left.rotation.z = stride
	leg_right.rotation.z = -stride
	arm_left.rotation.z = -stride * 0.65
	arm_right.rotation.z = stride * 0.65
	head.rotation.z = sin(animation_time * 3.0) * 0.05
	antenna.rotation.z = sin(animation_time * 11.0) * 0.11
	key.rotation.x += delta * 4.0


func _finish_after_sound(audio: AudioStreamPlayer3D) -> void:
	if not auto_cleanup:
		return
	visual.hide()
	# The audio player remains in the world until its one-shot has finished.
	audio.finished.connect(queue_free, CONNECT_ONE_SHOT)
