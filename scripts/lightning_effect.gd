extends Node3D

# One visual bolt between two world positions. Damage and target selection belong
# to the tower, so a future chain attack can call strike() for each hop.
@export_range(2, 32, 1) var segment_count := 9
@export_range(0.01, 0.3, 0.01) var width := 0.08
@export_range(0.0, 1.0, 0.01) var jitter := 0.35
@export var color := Color("77eaff")
@export_range(0.03, 1.0, 0.01) var lifetime := 0.18
@export_range(0.01, 0.2, 0.01) var refresh_interval := 0.035

var active := false
var start_point := Vector3.ZERO
var target_point := Vector3.ZERO
var remaining := 0.0
var refresh_clock := 0.0
var rng := RandomNumberGenerator.new()
var bolt_mesh: ImmediateMesh
var bolt_material: StandardMaterial3D


func _ready() -> void:
	rng.randomize()
	bolt_mesh = ImmediateMesh.new()
	bolt_material = StandardMaterial3D.new()
	bolt_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bolt_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	bolt_material.emission_enabled = true
	bolt_material.emission_energy_multiplier = 3.0
	bolt_material.albedo_color = color
	bolt_material.emission = color
	var visual := MeshInstance3D.new()
	visual.name = "BoltMesh"
	visual.mesh = bolt_mesh
	visual.material_override = bolt_material
	add_child(visual)
	# A hidden starter surface lets Godot see the triangle/material combination
	# when the scene starts, before a strike is requested.
	_draw_segment(Vector3.ZERO, Vector3.UP * 0.01)
	visible = false
	set_process(false)


func strike(start: Vector3, target: Vector3) -> void:
	if start.distance_squared_to(target) < 0.0001:
		return
	start_point = start
	target_point = target
	remaining = lifetime
	refresh_clock = 0.0
	active = true
	bolt_material.albedo_color = color
	bolt_material.emission = color
	_redraw()
	visible = true
	set_process(true)


func _process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		active = false
		visible = false
		set_process(false)
		return
	refresh_clock += delta
	if refresh_clock >= refresh_interval:
		refresh_clock = fmod(refresh_clock, refresh_interval)
		_redraw()


func _redraw() -> void:
	var from := to_local(start_point)
	var to := to_local(target_point)
	var axis := (to - from).normalized()
	var side := axis.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.01:
		side = axis.cross(Vector3.RIGHT).normalized()
	var other_side := axis.cross(side).normalized()
	var points: Array[Vector3] = []
	for index in range(segment_count + 1):
		var fraction := float(index) / float(segment_count)
		var point := from.lerp(to, fraction)
		if index > 0 and index < segment_count:
			# Taper jitter near the ends so the bolt stays attached to both points.
			var taper := sin(PI * fraction)
			point += side * rng.randf_range(-jitter, jitter) * taper
			point += other_side * rng.randf_range(-jitter, jitter) * taper
		points.append(point)
	bolt_mesh.clear_surfaces()
	bolt_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in segment_count:
		_add_crossed_segment(points[index], points[index + 1])
	bolt_mesh.surface_end()


func _draw_segment(from: Vector3, to: Vector3) -> void:
	bolt_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_crossed_segment(from, to)
	bolt_mesh.surface_end()


func _add_crossed_segment(from: Vector3, to: Vector3) -> void:
	var direction := (to - from).normalized()
	var side := direction.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.01:
		side = direction.cross(Vector3.RIGHT).normalized()
	var other_side := direction.cross(side).normalized()
	# Two crossed ribbons keep the bolt visible from the angled 3D cameras.
	_add_quad(from, to, side * width * 0.5)
	_add_quad(from, to, other_side * width * 0.5)


func _add_quad(from: Vector3, to: Vector3, half_width: Vector3) -> void:
	bolt_mesh.surface_add_vertex(from - half_width)
	bolt_mesh.surface_add_vertex(to - half_width)
	bolt_mesh.surface_add_vertex(to + half_width)
	bolt_mesh.surface_add_vertex(from - half_width)
	bolt_mesh.surface_add_vertex(to + half_width)
	bolt_mesh.surface_add_vertex(from + half_width)
