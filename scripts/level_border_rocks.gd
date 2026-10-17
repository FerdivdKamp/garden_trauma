class_name LevelBorderRocks
extends Node3D

const ROCK_MODEL: PackedScene = preload("res://assets/models/props/border/rock_stylized.glb")
const TILE_SIZE := 2.0
const FENCE_CLEARANCE := 1.2
const GROUND_EMBED := 0.08
const STONE_TINT := Color(0.66, 0.71, 0.78)

# One of each baked stone. Positions are fractions of the fence's side length,
# so the same layout follows both Garden maps without editing their tile data.
const ROCKS := [
	["Icosphere_baked", -1.0, -0.55, -0.22],
	["Icosphere_001_baked", 1.0, -0.38, 0.35],
	["Icosphere_002_baked", -1.0, 0.48, 0.18],
	["Icosphere_003_baked", 1.0, 0.58, -0.3],
]


func build(grid_width: int, grid_height: int) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var source := ROCK_MODEL.instantiate() as Node3D
	var half_width := float(grid_width) * TILE_SIZE * 0.5
	var half_height := float(grid_height) * TILE_SIZE * 0.5
	_add_outer_ground(half_width, half_height)
	for entry: Array in ROCKS:
		var original := source.find_child(entry[0], true, false) as MeshInstance3D
		if original == null:
			push_error("Stone mesh %s is missing from rock_stylized.glb" % entry[0])
			continue
		var rock := MeshInstance3D.new()
		rock.name = entry[0]
		rock.mesh = original.mesh
		# The baked albedo stays in the material. This tint compensates for the
		# Garden's bright sun without changing the reusable GLB or its PNGs.
		var material := rock.mesh.surface_get_material(0) as StandardMaterial3D
		if material != null:
			var garden_material := material.duplicate() as StandardMaterial3D
			garden_material.albedo_color = STONE_TINT
			rock.material_override = garden_material
		# Keep the Blender-authored flattening and scale, then add a small yaw.
		rock.basis = Basis(Vector3.UP, entry[3]) * original.basis
		var bounds := rock.get_aabb()
		var low := Vector3(INF, INF, INF)
		var high := Vector3(-INF, -INF, -INF)
		for corner in 8:
			var point := rock.basis * bounds.get_endpoint(corner)
			low = low.min(point)
			high = high.max(point)
		var side: float = entry[1]
		var half_rock_width := (high.x - low.x) * 0.5
		var center := (low + high) * 0.5
		rock.position = Vector3(
			side * (half_width + FENCE_CLEARANCE + half_rock_width) - center.x,
			-low.y - GROUND_EMBED,
			float(entry[2]) * half_height - center.z
		)
		add_child(rock)
	source.free()


func _add_outer_ground(half_width: float, half_height: float) -> void:
	# Separate strips stay outside the fence; a full plane would cover the
	# lowered sand path tiles inside the playable grid.
	var band := 10.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.19, 0.29, 0.17)
	material.roughness = 1.0
	_add_ground_strip("GroundLeft", Vector3(-half_width - band * 0.5, -0.05, 0.0),
		Vector2(band, half_height * 2.0 + band * 2.0), material)
	_add_ground_strip("GroundRight", Vector3(half_width + band * 0.5, -0.05, 0.0),
		Vector2(band, half_height * 2.0 + band * 2.0), material)
	_add_ground_strip("GroundBack", Vector3(0.0, -0.05, -half_height - band * 0.5),
		Vector2(half_width * 2.0, band), material)
	_add_ground_strip("GroundFront", Vector3(0.0, -0.05, half_height + band * 0.5),
		Vector2(half_width * 2.0, band), material)


func _add_ground_strip(name: String, point: Vector3, size: Vector2, material: Material) -> void:
	var ground := MeshInstance3D.new()
	ground.name = name
	var plane := PlaneMesh.new()
	plane.size = size
	ground.mesh = plane
	ground.material_override = material
	ground.position = point
	add_child(ground)
