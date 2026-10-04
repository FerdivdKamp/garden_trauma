@tool
extends Path3D

# The curve's points are in this node's local XZ plane. Width includes the
# whole no-build lane; callers add the tower radius when checking clearance.
@export_range(1.0, 10.0, 0.1) var path_width := 3.0:
	set(value):
		path_width = value
		if is_node_ready():
			_rebuild_visual()

@onready var surface: MeshInstance3D = $Surface


func _ready() -> void:
	# Keep the drawn lane in sync when Curve3D points are edited in the Inspector.
	if curve != null:
		curve.changed.connect(_rebuild_visual)
	_rebuild_visual()


func blocks_circle(world_center: Vector3, radius: float) -> bool:
	if curve == null:
		return false
	var local_center := to_local(world_center)
	var center := Vector2(local_center.x, local_center.z)
	for index in range(curve.point_count - 1):
		var start := curve.get_point_position(index)
		var finish := curve.get_point_position(index + 1)
		var a := Vector2(start.x, start.z)
		var b := Vector2(finish.x, finish.z)
		var segment := b - a
		var t := 0.0
		if segment.length_squared() > 0.0001:
			t = clampf((center - a).dot(segment) / segment.length_squared(), 0.0, 1.0)
		if center.distance_to(a + segment * t) < path_width * 0.5 + radius:
			return true
	return false


func _rebuild_visual() -> void:
	if curve == null or curve.point_count < 2:
		surface.mesh = null
		return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(curve.point_count - 1):
		var a := curve.get_point_position(index)
		var b := curve.get_point_position(index + 1)
		var flat_segment := Vector2(b.x - a.x, b.z - a.z)
		if flat_segment.length_squared() < 0.0001:
			continue
		var direction := flat_segment.normalized()
		var side := Vector3(-direction.y, 0.0, direction.x) * path_width * 0.5
		a.y = 0.025
		b.y = 0.025
		for vertex in [a - side, b - side, b + side, a - side, b + side, a + side]:
			mesh.surface_add_vertex(vertex)
	mesh.surface_end()
	surface.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("b59b71")
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.material_override = material
