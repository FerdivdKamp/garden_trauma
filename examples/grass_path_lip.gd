extends Node3D

# V2.1 visual study. The logical cells stay 2 m wide; only grass is raised.
# Run this scene directly with F6. Toggle these in the Inspector to compare.
@export var show_lip := true
@export var show_blades := true

const GRASS := preload("res://scenes/tiles/tile_grass.tscn")
const PATH := preload("res://scenes/tiles/tile_path.tscn")
const MAP := [".....", "..=..", "..=..", "..==.", "....."]
const GRASS_RISE := 0.18
const EDGE_TOP := 0.19
const PATH_TOP := 0.04

var grass_material: Material
var soil_material: StandardMaterial3D
var blade_material: StandardMaterial3D


func _ready() -> void:
	var camera := $Camera as Camera3D
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	soil_material = StandardMaterial3D.new()
	soil_material.albedo_color = Color("93704a")
	soil_material.roughness = 1.0
	blade_material = StandardMaterial3D.new()
	blade_material.albedo_color = Color("659d3b")
	blade_material.roughness = 1.0
	blade_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for z in MAP.size():
		for x in MAP[z].length():
			var tile := (PATH if MAP[z][x] == "=" else GRASS).instantiate() as Node3D
			tile.name = "Path_%d_%d" % [x, z] if MAP[z][x] == "=" else "Grass_%d_%d" % [x, z]
			tile.position = Vector3((x - 2) * 2.0, 0.0 if MAP[z][x] == "=" else GRASS_RISE, (z - 2) * 2.0)
			# Fixed seeds make before/after screenshots use identical base tiles.
			tile.set("visual_seed", x * 97 + z * 13)
			$Tiles.add_child(tile)
	await get_tree().process_frame
	grass_material = _find_grass_material($Tiles)
	if grass_material == null:
		push_error("GrassTop import material was not found")
		return
	for z in MAP.size():
		for x in MAP[z].length():
			if MAP[z][x] != ".":
				continue
			var center := Vector3((x - 2) * 2.0, 0.0, (z - 2) * 2.0)
			for side in 4:
				var neighbor: Vector2i = Vector2i(x, z) + [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)][side]
				if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= MAP[0].length() or neighbor.y >= MAP.size():
					continue
				if MAP[neighbor.y][neighbor.x] != "=":
					continue
				var edge := _make_edge(x, z, side)
				edge.position = center
				edge.rotation.y = -float(side) * PI * 0.5
				$Edges.add_child(edge)
	$Edges.visible = show_lip
	$Blades.visible = show_blades


func _find_grass_material(node: Node) -> Material:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		for index in instance.mesh.get_surface_count():
			var material := instance.get_active_material(index)
			if material != null and material.resource_name == "GrassTop":
				return material
	for child in node.get_children():
		var found := _find_grass_material(child)
		if found != null:
			return found
	return null


func _make_edge(cell_x: int, cell_z: int, side: int) -> Node3D:
	var edge := Node3D.new()
	edge.name = "GrassLip_%d_%d_%d" % [cell_x, cell_z, side]
	var green := SurfaceTool.new()
	green.begin(Mesh.PRIMITIVE_TRIANGLES)
	var soil := SurfaceTool.new()
	soil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = cell_x * 92821 + cell_z * 68917 + side * 4099 + 1
	var previous_inner := Vector3(0.94, EDGE_TOP + 0.012, -1.0)
	var previous_outer := Vector3(1.10, EDGE_TOP, -1.0)
	for segment in 1 + 12:
		var along := -1.0 + float(segment) / 12.0 * 2.0
		var outer := Vector3(1.10 + rng.randf_range(-0.025, 0.025), EDGE_TOP + rng.randf_range(-0.008, 0.008), along)
		var inner := Vector3(0.94, EDGE_TOP + 0.012, along)
		if segment > 0:
			_quad(green, previous_inner, previous_outer, outer, inner)
			_quad(soil, previous_outer, Vector3(previous_outer.x, PATH_TOP, previous_outer.z), Vector3(outer.x, PATH_TOP, outer.z), outer)
		previous_inner = inner
		previous_outer = outer
	green.generate_normals()
	soil.generate_normals()
	var top_mesh := MeshInstance3D.new()
	top_mesh.name = "WorldMatchedGrassTop"
	top_mesh.mesh = green.commit()
	top_mesh.material_override = grass_material
	edge.add_child(top_mesh)
	var soil_mesh := MeshInstance3D.new()
	soil_mesh.name = "ExposedSoil"
	soil_mesh.mesh = soil.commit()
	soil_mesh.material_override = soil_material
	edge.add_child(soil_mesh)
	_make_blades(cell_x, cell_z, side, rng)
	return edge


func _make_blades(cell_x: int, cell_z: int, side: int, rng: RandomNumberGenerator) -> void:
	var holder := Node3D.new()
	holder.name = "Blades_%d_%d_%d" % [cell_x, cell_z, side]
	holder.position = Vector3((cell_x - 2) * 2.0, 0.0, (cell_z - 2) * 2.0)
	holder.rotation.y = -float(side) * PI * 0.5
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade in 15:
		var x := rng.randf_range(0.94, 1.17)
		var z := rng.randf_range(-0.92, 0.92)
		var base_y := EDGE_TOP + 0.005 if x < 1.10 else PATH_TOP + 0.005
		var height := rng.randf_range(0.07, 0.16)
		var width := rng.randf_range(0.015, 0.03)
		var tilt := rng.randf_range(-0.05, 0.05)
		var base := Vector3(x, base_y, z)
		_triangle(surface, base + Vector3(0, 0, -width), base + Vector3(tilt, height, 0), base + Vector3(0, 0, width))
		_triangle(surface, base + Vector3(-width, 0, 0), base + Vector3(0, height, tilt), base + Vector3(width, 0, 0))
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = "SparseBlades"
	mesh.mesh = surface.commit()
	mesh.material_override = blade_material
	holder.add_child(mesh)
	$Blades.add_child(holder)


func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_triangle(surface, a, b, c)
	_triangle(surface, a, c, d)


func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
