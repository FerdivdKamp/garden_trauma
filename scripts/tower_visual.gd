extends Node3D

# Shared by the original tower playground and the placement playground.
const FOOTPRINT_RADIUS := 0.95
const RangeVisual = preload("res://scripts/tower_range_visual.gd")
const LASER_MODELS: Array[PackedScene] = [
	preload("res://assets/models/towers/laser_tower.glb"),
	preload("res://assets/models/towers/laser_tower_mk2.glb"),
	preload("res://assets/models/towers/laser_tower_mk3.glb"),
	preload("res://assets/models/towers/laser_tower_mk4.glb"),
]
const FIRE_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/towers/tower_01_fire.ogg"),
	preload("res://assets/audio/sfx/towers/tower_02_fire.ogg"),
	preload("res://assets/audio/sfx/towers/tower_03_fire.ogg"),
]

@onready var turret_pivot: Node3D = $TurretPivot
@onready var laser_model: Node3D = $LaserTower
var laser_yaw: Node3D
var laser_pitch: Node3D
var laser_muzzle: Node3D
var laser_upgrade_level := 0
@onready var range_visual: RangeVisual = $RangeVisual
@onready var fire_audio: AudioStreamPlayer3D = $FireAudio

var tower_type := 0
var is_preview := false


func _ready() -> void:
	_bind_laser_pivots()
	if tower_type != 0:
		_build_base()
	_build_turret()
	laser_model.visible = tower_type == 0
	fire_audio.stream = FIRE_SOUNDS[tower_type]


func set_tower_type(value: int) -> void:
	tower_type = value
	if is_node_ready():
		laser_model.visible = tower_type == 0
		var base := get_node_or_null("Base")
		if tower_type == 0 and base != null:
			base.queue_free()
		elif tower_type != 0 and base == null:
			_build_base()
		_build_turret()
		fire_audio.stream = FIRE_SOUNDS[tower_type]


func set_laser_upgrade_level(level: int) -> void:
	assert(level >= 0 and level < LASER_MODELS.size())
	if laser_model != null and laser_upgrade_level == level:
		return
	var previous_yaw := laser_yaw.rotation.y if laser_yaw != null else 0.0
	var previous_pitch := laser_pitch.rotation.x if laser_pitch != null else 0.0
	if laser_model != null:
		remove_child(laser_model)
		laser_model.queue_free()
	laser_upgrade_level = level
	laser_model = LASER_MODELS[level].instantiate() as Node3D
	laser_model.name = "LaserTower"
	add_child(laser_model)
	_bind_laser_pivots()
	laser_yaw.rotation.y = previous_yaw
	laser_pitch.rotation.x = previous_pitch
	laser_model.visible = tower_type == 0
	if is_node_ready():
		_update_materials(true)


func _bind_laser_pivots() -> void:
	# Godot changes Blender's .001 style suffixes to _001 on import.
	var suffix := "" if laser_upgrade_level == 0 else "_%03d" % laser_upgrade_level
	laser_yaw = laser_model.get_node("turret_yaw%s" % suffix) as Node3D
	laser_pitch = laser_yaw.get_node("gunbase%s/turret_pitch%s" % [suffix, suffix]) as Node3D
	laser_muzzle = laser_pitch.get_node("gun%s/muzzle%s" % [suffix, suffix]) as Node3D


func play_fire_sound() -> void:
	fire_audio.play()


func set_preview(value: bool) -> void:
	is_preview = value
	if is_node_ready():
		_update_materials(true)


func set_placement_valid(valid: bool) -> void:
	if is_preview:
		_update_materials(valid)


func set_ranges(attack_radius: float, detection_radius: float) -> void:
	range_visual.set_ranges(attack_radius, detection_radius)


func set_ranges_visible(value: bool) -> void:
	range_visual.visible = value


func _build_base() -> void:
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.85
	base_mesh.bottom_radius = FOOTPRINT_RADIUS
	base_mesh.height = 0.8
	var base := _mesh_instance(base_mesh, Color("718aa2"))
	base.name = "Base"
	base.position.y = 0.4
	add_child(base)


func _build_turret() -> void:
	for child in turret_pivot.get_children():
		turret_pivot.remove_child(child)
		child.queue_free()
	if tower_type == 0:
		_update_materials(true)
		return
	if tower_type == 2:
		_build_lightning_head()
		_update_materials(true)
		return
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
		barrel.name = "Barrel" if tower_type == 0 else ("LeftBarrel" if offset < 0.0 else "RightBarrel")
		barrel.position = Vector3(offset, 0.17, -0.85)
		turret_pivot.add_child(barrel)
		# The marker is in barrel-local space, at its front face. It follows turret rotation.
		var muzzle := Marker3D.new()
		muzzle.name = "Muzzle"
		muzzle.position.z = -0.725
		barrel.add_child(muzzle)
	_update_materials(true)


func _build_lightning_head() -> void:
	var column_mesh := CylinderMesh.new()
	column_mesh.top_radius = 0.21
	column_mesh.bottom_radius = 0.32
	column_mesh.height = 1.3
	var column := _mesh_instance(column_mesh, Color("627890"))
	column.name = "Column"
	column.position.y = 0.55
	turret_pivot.add_child(column)
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.38
	orb_mesh.height = 0.76
	var orb := _mesh_instance(orb_mesh, Color("8beaff"))
	orb.name = "Orb"
	orb.position.y = 1.32
	turret_pivot.add_child(orb)
	var origin := Marker3D.new()
	origin.name = "LightningOrigin"
	origin.position.y = 0.38
	orb.add_child(origin)


func get_muzzle_position(barrel_index: int = 0) -> Vector3:
	if tower_type == 0:
		return laser_muzzle.global_position
	if tower_type == 2:
		return (turret_pivot.get_node("Orb/LightningOrigin") as Marker3D).global_position
	var barrel_name := "Barrel" if tower_type == 0 else ("LeftBarrel" if barrel_index == 0 else "RightBarrel")
	var muzzle := turret_pivot.get_node("%s/Muzzle" % barrel_name) as Marker3D
	return muzzle.global_position


func get_yaw_pivot() -> Node3D:
	return laser_yaw if tower_type == 0 else turret_pivot


func aim_pitch_at(target_position: Vector3, turn_speed: float, delta: float) -> bool:
	if tower_type != 0:
		return true
	# The Blender pitch empty points along -Z, matching Godot's forward direction.
	var local_target := laser_yaw.to_local(target_position)
	var local_pivot := laser_yaw.to_local(laser_pitch.global_position)
	var direction := local_target - local_pivot
	var desired := atan2(direction.y, Vector2(direction.x, direction.z).length())
	laser_pitch.rotation.x = move_toward(laser_pitch.rotation.x, desired, deg_to_rad(turn_speed) * delta)
	return absf(laser_pitch.rotation.x - desired) < deg_to_rad(5.0)


func _mesh_instance(shape: Mesh, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.set_meta("tower_color", color)
	return instance


func _update_materials(valid: bool) -> void:
	var parts := []
	var base := get_node_or_null("Base")
	if base != null:
		parts.append(base)
	parts.append_array(turret_pivot.get_children())
	for part in parts:
		var mesh_part := part as MeshInstance3D
		if mesh_part == null:
			continue
		var color: Color = mesh_part.get_meta("tower_color")
		if is_preview:
			color = color.lightened(0.15) if valid else Color("ed6868")
			color.a = 0.5
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.7
		if is_preview:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_part.material_override = material
	# Keep the GLB's own materials. Geometry transparency and an overlay make
	# previews readable without replacing each imported material slot.
	for mesh_part in laser_model.find_children("*", "MeshInstance3D", true, false):
		mesh_part.transparency = 0.5 if is_preview else 0.0
		if is_preview and not valid:
			var warning := StandardMaterial3D.new()
			warning.albedo_color = Color(1.0, 0.15, 0.15, 0.7)
			warning.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_part.material_overlay = warning
		else:
			mesh_part.material_overlay = null
