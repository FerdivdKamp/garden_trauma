extends Node3D

@onready var yaw_pivot: Node3D = $TurretPivot
@onready var accordion: Node3D = $TurretPivot/AccordionPivot/AccordionMesh
@onready var muzzle: Marker3D = $TurretPivot/LauncherArm/Muzzle
@onready var loaded_rocket: Node3D = $TurretPivot/LoadedRocket

var pump_tween: Tween


func _ready() -> void:
	_build_placeholder()


func pump_and_launch(launch: Callable) -> void:
	if pump_tween != null and pump_tween.is_running():
		pump_tween.kill()
	accordion.scale.y = 1.0
	loaded_rocket.visible = true
	pump_tween = create_tween()
	# Scaling a child rooted at the bellows' bottom keeps it seated on the housing.
	pump_tween.tween_property(accordion, "scale:y", 0.55, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	pump_tween.tween_callback(func() -> void:
		loaded_rocket.hide()
		launch.call()
	)
	pump_tween.tween_property(accordion, "scale:y", 1.06, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pump_tween.tween_property(accordion, "scale:y", 1.0, 0.10)
	pump_tween.tween_callback(loaded_rocket.show)


func _build_placeholder() -> void:
	# Every mesh lives below the named pivots, so a GLB can replace this scene.
	# Two crossed bars and round corner posts make a rounded-square footprint.
	for index in 2:
		var base_bar := BoxMesh.new()
		base_bar.size = Vector3(1.15, 0.26, 0.85) if index == 0 else Vector3(0.85, 0.26, 1.15)
		_add_mesh($Base, "PlasticBase%d" % index, base_bar, Color("f1e9d4"), Vector3(0, 0.14, 0))
	for x in [-0.425, 0.425]:
		for z in [-0.425, 0.425]:
			var corner := CylinderMesh.new()
			corner.top_radius = 0.15
			corner.bottom_radius = 0.15
			corner.height = 0.26
			_add_mesh($Base, "RoundCorner", corner, Color("f1e9d4"), Vector3(x, 0.14, z))
	var housing := CylinderMesh.new()
	housing.top_radius = 0.48
	housing.bottom_radius = 0.54
	housing.height = 0.68
	_add_mesh($TurretPivot/PumpHousing, "Housing", housing, Color("f5eedb"), Vector3.ZERO)
	var rim := CylinderMesh.new()
	rim.top_radius = 0.50
	rim.bottom_radius = 0.50
	rim.height = 0.10
	_add_mesh($TurretPivot/PumpHousing, "PumpRim", rim, Color("a6c2cd"), Vector3(0, 0.36, 0))
	for index in 9:
		var rib := CylinderMesh.new()
		var radius := lerpf(0.34, 0.44, float(index) / 8.0)
		rib.top_radius = radius
		rib.bottom_radius = radius
		rib.height = 0.12
		_add_mesh(accordion, "BellowsRib%d" % index, rib, Color("bbd5dc") if index % 2 == 0 else Color("dce8e9"), Vector3(0, 0.08 + index * 0.12, 0))
	var cap := CylinderMesh.new()
	cap.top_radius = 0.46
	cap.bottom_radius = 0.46
	cap.height = 0.17
	_add_mesh(accordion, "BellowsCap", cap, Color("f4e9d0"), Vector3(0, 1.15, 0))
	var arm := BoxMesh.new()
	arm.size = Vector3(0.22, 0.19, 0.82)
	_add_mesh($TurretPivot/LauncherArm, "PressureArm", arm, Color("efc36d"), Vector3(0.43, 0.83, -0.37))
	var nozzle := CylinderMesh.new()
	nozzle.top_radius = 0.17
	nozzle.bottom_radius = 0.20
	nozzle.height = 0.21
	_add_mesh($TurretPivot/LauncherArm, "LauncherSeat", nozzle, Color("f2d789"), Vector3(0.43, 1.01, -0.62))


static func _add_mesh(parent: Node3D, part_name: String, mesh: Mesh, color: Color, offset: Vector3) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.position = offset
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.42
	part.material_override = material
	parent.add_child(part)
	return part
