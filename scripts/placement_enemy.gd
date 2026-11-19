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
@onready var tank: Node3D = $Visual/Tank
@onready var formula_car: Node3D = $Visual/FormulaCar
@onready var battery_car: Node3D = $Visual/BatteryCar
@onready var destroyed_audio: AudioStreamPlayer3D = $DestroyedAudio
@onready var objective_audio: AudioStreamPlayer3D = $ObjectiveAudio
@onready var health_bar: Sprite3D = $HealthBar

const BAR_WIDTH := 64
const BAR_HEIGHT := 8
const HIT_BAR_SECONDS := 1.0

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
var hovered := false
var hit_bar_remaining := 0.0
var current_speed := 0.0

const TANK_TURN_SPEED := 1.8 # Radians per second while the hull pivots.
const TANK_MOVE_ANGLE := 0.2
const CAR_CORNER_SPEED := 2.0
const CAR_ACCELERATION := 4.0
const CAR_BRAKING := 9.0
const DEBRIS_COLLISION_LAYER := 1 << 19


func _ready() -> void:
	# Only the mesh is scaled: movement speed remains world units per second.
	_bind_robot_pivots()
	if enemy_type >= 2:
		# Vehicle bodies steer themselves; PathFollow still supplies the position.
		rotation_mode = PathFollow3D.ROTATION_NONE
		visual.rotation.y = _route_heading()
	_update_visual_scale()
	_update_color()
	_update_health_bar()


func _process(delta: float) -> void:
	if hit_bar_remaining > 0.0:
		hit_bar_remaining = maxf(0.0, hit_bar_remaining - delta)
		_update_bar_visibility()
	if health > 0.0 and not reached_objective:
		_animate_robot(delta)
		var route := get_parent() as Path3D
		var step_speed := movement_speed
		if enemy_type == 2:
			var heading := _route_heading()
			visual.rotation.y = rotate_toward(visual.rotation.y, heading, TANK_TURN_SPEED * delta)
			# Pause at a bend until the hull has faced the next segment.
			if absf(wrapf(heading - visual.rotation.y, -PI, PI)) > TANK_MOVE_ANGLE:
				step_speed = 0.0
		elif enemy_type == 3 or enemy_type == 4:
			var corner := _upcoming_bend_angle()
			var target_speed := CAR_CORNER_SPEED if corner > 0.35 else movement_speed
			var acceleration := CAR_BRAKING if target_speed < current_speed else CAR_ACCELERATION
			current_speed = move_toward(current_speed, target_speed, acceleration * delta)
			step_speed = current_speed
			visual.rotation.y = _route_heading()
		progress = minf(progress + step_speed * delta, route.curve.get_baked_length())
		if progress >= route.curve.get_baked_length():
			reached_objective = true
			_update_bar_visibility()
			objective_audio.play()
			objective_reached.emit(self)
			_finish_after_sound(objective_audio)


func configure(type: int, unit: UnitDefinition, speed: float, size: float) -> void:
	enemy_type = type
	definition = unit
	movement_speed = speed
	current_speed = CAR_CORNER_SPEED if type == 3 or type == 4 else speed
	visual_scale = size
	max_health = unit.health
	health = max_health
	reached_objective = false
	if is_node_ready():
		rotation_mode = PathFollow3D.ROTATION_NONE if type >= 2 else PathFollow3D.ROTATION_XYZ
		if type >= 2:
			visual.rotation.y = _route_heading()
		_update_color()
		_update_health_bar()
		hit_bar_remaining = 0.0
		_update_bar_visibility()
	health_changed.emit()


func take_damage(amount: float) -> void:
	if health <= 0.0 or reached_objective:
		return
	var previous_health := health
	health = TowerRules.health_after_hit(health, amount)
	if health < previous_health:
		hit_bar_remaining = HIT_BAR_SECONDS
	if health <= 0.0:
		destroyed_audio.play()
		_start_destruction_visual()
		defeated.emit(self)
		_finish_after_sound(destroyed_audio, enemy_type == 0 or enemy_type == 3 or enemy_type == 4)
	_update_color()
	_update_health_bar()
	health_changed.emit()


func set_hovered(value: bool) -> void:
	hovered = value
	_update_bar_visibility()


func _update_health_bar() -> void:
	# The black pixels stay visible as health shrinks, showing the lost fraction.
	var image := Image.create(BAR_WIDTH, BAR_HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color("111111"))
	var filled_width := roundi((BAR_WIDTH - 2) * clampf(health / max_health, 0.0, 1.0))
	if filled_width > 0:
		image.fill_rect(Rect2i(1, 1, filled_width, BAR_HEIGHT - 2), Color("df353b"))
	health_bar.texture = ImageTexture.create_from_image(image)
	_update_bar_visibility()


func _update_bar_visibility() -> void:
	if health_bar != null:
		health_bar.visible = health > 0.0 and not reached_objective and (hovered or hit_bar_remaining > 0.0)


func _update_color() -> void:
	robot.visible = enemy_type == 0
	sphere.visible = enemy_type == 1
	tank.visible = enemy_type == 2
	formula_car.visible = enemy_type == 3
	battery_car.visible = enemy_type == 4
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("555555") if health <= 0.0 else Color("619de8")
	sphere.material_override = material


func _update_visual_scale() -> void:
	visual.scale = Vector3.ONE * visual_scale


func get_aim_position() -> Vector3:
	# Each imported model owns its target point, so it follows model transforms.
	# The sphere and tank placeholders retain the previous visual-origin target.
	var model: Node3D = robot if enemy_type == 0 else formula_car if enemy_type == 3 else battery_car if enemy_type == 4 else null
	if model != null:
		var aim_point := model.find_child("AimPoint*", true, false) as Node3D
		if aim_point != null:
			return aim_point.global_position
	return visual.global_position


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


func _route_heading() -> float:
	var route := get_parent() as Path3D
	if route == null or route.curve == null:
		return 0.0
	var curve := route.curve
	var start := curve.sample_baked(minf(progress, curve.get_baked_length()))
	var finish := curve.sample_baked(minf(progress + 0.25, curve.get_baked_length()))
	var direction := finish - start
	if direction.length_squared() < 0.0001:
		return visual.rotation.y
	# The placeholder models face local -Z.
	return atan2(-direction.x, -direction.z)


func _upcoming_bend_angle() -> float:
	var curve := (get_parent() as Path3D).curve
	var length := curve.get_baked_length()
	var near := curve.sample_baked(minf(progress + 0.1, length)) - curve.sample_baked(progress)
	var far := curve.sample_baked(minf(progress + 1.8, length)) - curve.sample_baked(minf(progress + 1.5, length))
	if near.length_squared() < 0.0001 or far.length_squared() < 0.0001:
		return 0.0
	return near.angle_to(far)


func _finish_after_sound(audio: AudioStreamPlayer3D, show_destruction: bool = false) -> void:
	if not auto_cleanup:
		return
	if show_destruction:
		# Both the effect and the sound need to finish before the enemy is freed.
		await get_tree().create_timer(2.5, false).timeout
	else:
		visual.hide()
	if audio.playing:
		await audio.finished
	queue_free()


func _start_destruction_visual() -> void:
	if enemy_type == 0:
		_destroy_robot()
	elif enemy_type == 3 or enemy_type == 4:
		_destroy_car(formula_car if enemy_type == 3 else battery_car)


func _destroy_robot() -> void:
	# The paths are visual meshes, so debris gets a private floor at the path
	# height. Its collision layer keeps this cosmetic physics out of gameplay.
	_add_debris_floor()
	var parts: Array[Node3D] = [arm_left, arm_right, leg_left, leg_right, head]
	var velocities: Array[Vector3] = [Vector3(-0.8, 0.2, 0.1), Vector3(0.8, 0.2, -0.1), Vector3(-0.45, 0.1, 0.45), Vector3(0.45, 0.1, 0.45), Vector3(0.15, 0.3, -0.55)]
	for index in parts.size():
		var part := parts[index]
		var mesh := part.get_child(0) as MeshInstance3D
		if mesh:
			var body := _make_debris_body(part, mesh)
			body.linear_velocity = visual.global_basis.orthonormalized() * velocities[index] * visual_scale
			body.angular_velocity = Vector3(0.4, 0.6, 2.0 if index % 2 == 0 else -2.0)
	var torso := robot.find_child("Torso", true, false) as Node3D
	if torso is MeshInstance3D:
		_make_debris_body(torso, torso as MeshInstance3D)


func _add_debris_floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "DebrisFloor"
	floor_body.collision_layer = DEBRIS_COLLISION_LAYER
	floor_body.collision_mask = 0
	add_child(floor_body)
	floor_body.top_level = true
	floor_body.global_position = visual.global_position - Vector3(0, 0.1, 0)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	collision.shape = box
	floor_body.add_child(collision)


func _make_debris_body(part: Node3D, mesh: MeshInstance3D) -> RigidBody3D:
	# Fit a simple box to the main mesh at its current walking pose. Antennas
	# and keys stay attached visually but do not make the box overly large.
	var bounds := mesh.get_aabb()
	var mesh_transform := mesh.global_transform
	var body := RigidBody3D.new()
	body.name = "Debris_" + part.name
	body.collision_layer = 0
	body.collision_mask = DEBRIS_COLLISION_LAYER
	body.mass = 1.0
	add_child(body)
	body.top_level = true
	body.global_transform = Transform3D(mesh_transform.basis.orthonormalized(), mesh_transform * bounds.get_center())
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = (bounds.size * mesh_transform.basis.get_scale().abs()).max(Vector3(0.02, 0.02, 0.02))
	collision.shape = box
	body.add_child(collision)
	part.reparent(body, true)
	return body


func _destroy_car(model: Node3D) -> void:
	# The exported tire and hub meshes contain mirrored geometry. Split each
	# mesh by side, then keep the tire and hub on one pivot per wheel.
	var wheels: Dictionary = {}
	for child in model.find_children("tire_*", "MeshInstance3D", true, false):
		var original := child as MeshInstance3D
		for side in [-1, 1]:
			var piece := _make_wheel_piece(original, model, side)
			if piece == null:
				continue
			var center := piece.mesh.get_aabb().get_center()
			var wheel_id := Vector2i(side, 1 if center.z > 0.0 else -1)
			if not wheels.has(wheel_id):
				var pivot := Node3D.new()
				pivot.name = "WheelDebris"
				pivot.set_meta("wheel_debris", true)
				model.add_child(pivot)
				pivot.position = center
				wheels[wheel_id] = pivot
			var pivot: Node3D = wheels[wheel_id]
			pivot.add_child(piece)
			piece.position = -pivot.position
		original.hide()
	var rng := RandomNumberGenerator.new()
	for wheel_id: Vector2i in wheels:
		var pivot: Node3D = wheels[wheel_id]
		# Vary distance, direction and timing per wheel, like the gumballs.
		# The car faces local -Z; the wheels tip only after rolling forward.
		var roll_distance := clampf(current_speed * 0.22, 0.5, 1.4) * rng.randf_range(0.8, 1.2)
		var roll_time := 1.15 * rng.randf_range(0.85, 1.15)
		var sideways := wheel_id.x * rng.randf_range(0.25, 0.55)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(pivot, "position", pivot.position + Vector3(sideways, -0.04, -roll_distance), roll_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(pivot, "rotation:x", roll_distance / 0.17, roll_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(pivot, "rotation:z", -wheel_id.x * 1.2, roll_time * 0.48).set_delay(roll_time * 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for name_prefix in ["body*", "canopy*"]:
		var part := model.find_child(name_prefix, true, false) as Node3D
		if part:
			var tween := create_tween()
			tween.tween_property(part, "position:y", part.position.y - 0.10, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _make_wheel_piece(source: MeshInstance3D, model: Node3D, side: int) -> MeshInstance3D:
	var result := ArrayMesh.new()
	var mesh := source.mesh
	var to_model := model.global_transform.affine_inverse() * source.global_transform
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for index in vertices.size():
				indices.append(index)
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var count := 0
		for triangle in range(0, indices.size(), 3):
			var center := Vector3.ZERO
			for corner in 3:
				center += to_model * vertices[indices[triangle + corner]]
			if center.x * side <= 0.0:
				continue
			for corner in 3:
				var index := indices[triangle + corner]
				if not normals.is_empty():
					builder.set_normal((to_model.basis.inverse().transposed() * normals[index]).normalized())
				if not uvs.is_empty():
					builder.set_uv(uvs[index])
				builder.add_vertex(to_model * vertices[index])
				count += 1
		if count > 0:
			builder.set_material(source.get_active_material(surface))
			builder.commit(result)
	if result.get_surface_count() == 0:
		return null
	var piece := MeshInstance3D.new()
	piece.mesh = result
	return piece
