extends Node3D

# Shared by the original tower playground and the placement playground.
const FOOTPRINT_RADIUS := 1.05
const RangeVisual = preload("res://scripts/tower_range_visual.gd")

@onready var turret_pivot: Node3D = $TurretPivot
@onready var range_visual: RangeVisual = $RangeVisual

var tower_type := 0
var is_preview := false


func _ready() -> void:
	_build_base()
	_build_turret()


func set_tower_type(value: int) -> void:
	tower_type = value
	if is_node_ready():
		_build_turret()


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
	if tower_type == 2:
		return (turret_pivot.get_node("Orb/LightningOrigin") as Marker3D).global_position
	var barrel_name := "Barrel" if tower_type == 0 else ("LeftBarrel" if barrel_index == 0 else "RightBarrel")
	var muzzle := turret_pivot.get_node("%s/Muzzle" % barrel_name) as Marker3D
	return muzzle.global_position


func _mesh_instance(shape: Mesh, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.set_meta("tower_color", color)
	return instance


func _update_materials(valid: bool) -> void:
	var parts := [get_node("Base")]
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
