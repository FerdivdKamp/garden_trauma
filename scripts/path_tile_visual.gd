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


func _ready() -> void:
	# The path uses the one lowered mesh while its height is being evaluated.
	$PathVisual.position = Vector3(0.0, -0.25, 0.0)
	_build_borders()


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
