class_name PathTileVisual
extends Node3D

const STRAIGHT := preload("res://assets/models/environment/garden/tiles/border_straight_1.glb")
const OUTER := preload("res://assets/models/environment/garden/tiles/corner_outer_1.glb")
const INNER := preload("res://assets/models/environment/garden/tiles/corner_inner_1.glb")

# Cardinal bits: north, east, south, west. Diagonal bits: NE, SE, SW, NW.
const N := 1
const E := 2
const S := 4
const W := 8
const NE := 1
const SE := 2
const SW := 4
const NW := 8

var visual_seed := 0
var grass_sides := 0
var grass_diagonals := 0

@export_range(0.01, 1.0, 0.01, "suffix:m") var shadow_width := 0.45
@export_range(0.0, 1.0, 0.01) var shadow_strength := 0.55
@export_range(0.01, 1.0, 0.01, "suffix:m") var grass_edge_width := 0.5
@export_range(0.0, 1.0, 0.01) var grass_edge_strength := 0.3


func _ready() -> void:
	# The path uses the one lowered mesh while its height is being evaluated.
	$PathVisual.position = Vector3(0.0, -0.25, 0.0)
	_apply_path_shadow($PathVisual)
	_build_borders()


func _apply_path_shadow(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface in mesh_instance.mesh.get_surface_count():
				var material := mesh_instance.get_active_material(surface)
				if material is ShaderMaterial and material.resource_name == "GrassTop":
					# Each tile needs its own parameters; imported materials are shared.
					var shadow_material := material.duplicate() as ShaderMaterial
					_configure_edge_material(shadow_material)
					shadow_material.set_shader_parameter("path_shadow_width", shadow_width)
					shadow_material.set_shader_parameter("path_shadow_strength", shadow_strength)
					mesh_instance.set_surface_override_material(surface, shadow_material)
	for child in node.get_children():
		_apply_path_shadow(child)


func _configure_edge_material(material: ShaderMaterial) -> void:
	material.set_shader_parameter("path_shadow_sides", Vector4(float(bool(grass_sides & N)), float(bool(grass_sides & E)), float(bool(grass_sides & S)), float(bool(grass_sides & W))))
	# Diagonal borders only exist when neither adjoining side is grass.
	material.set_shader_parameter("path_shadow_corners", Vector4(
		float(bool(grass_diagonals & NE) and not bool(grass_sides & (N | E))),
		float(bool(grass_diagonals & SE) and not bool(grass_sides & (S | E))),
		float(bool(grass_diagonals & SW) and not bool(grass_sides & (S | W))),
		float(bool(grass_diagonals & NW) and not bool(grass_sides & (N | W)))))
	material.set_shader_parameter("path_tile_center", global_position)
	material.set_shader_parameter("path_tile_axis_x", global_transform.basis.x.normalized())
	material.set_shader_parameter("path_tile_axis_z", global_transform.basis.z.normalized())


func _apply_grass_edge(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			for surface in instance.mesh.get_surface_count():
				var material := instance.get_active_material(surface) as ShaderMaterial
				if material != null and material.get_shader_parameter("grass_world_variation") == true:
					# Border pieces are shared assets, so keep the edge settings local.
					var edge_material := material.duplicate() as ShaderMaterial
					_configure_edge_material(edge_material)
					edge_material.set_shader_parameter("grass_edge_width", grass_edge_width)
					edge_material.set_shader_parameter("grass_edge_strength", grass_edge_strength)
					instance.set_surface_override_material(surface, edge_material)
	for child in node.get_children():
		_apply_grass_edge(child)


func _build_borders() -> void:
	# These meshes are visual only. The logical cell stays a full path tile.
	var borders := Node3D.new()
	borders.name = "Borders"
	add_child(borders)
	var covered := 0
	for corner: Array in [[W | N, 0], [W | S, 1], [E | S, 2], [E | N, 3]]:
		var pair: int = corner[0]
		if (grass_sides & pair) == pair and (covered & pair) == 0:
			_add_border(borders, OUTER, "Outer", int(corner[1]))
			covered |= pair
	for side: Array in [[W, 0], [S, 1], [E, 2], [N, 3]]:
		if (grass_sides & int(side[0])) != 0 and (covered & int(side[0])) == 0:
			_add_border(borders, STRAIGHT, "Straight", int(side[1]))
	for corner: Array in [[SE, E | S, 0], [NE, E | N, 1], [NW, W | N, 2], [SW, W | S, 3]]:
		if (grass_diagonals & int(corner[0])) != 0 and (grass_sides & int(corner[1])) == 0:
			_add_border(borders, INNER, "Inner", int(corner[2]))


func _add_border(parent: Node3D, scene: PackedScene, kind: String, turns: int) -> void:
	var piece := scene.instantiate() as Node3D
	piece.name = "%s_%d" % [kind, turns]
	piece.rotation.y = float(turns) * PI * 0.5
	piece.position.y = -0.25
	parent.add_child(piece)
	_apply_grass_edge(piece)
