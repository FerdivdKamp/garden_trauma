class_name PathTileVisual
extends Node3D

const VARIANTS := [
	preload("res://assets/models/environment/garden/tiles/tile_path.glb"),
	preload("res://assets/models/environment/garden/tiles/tile_path2.glb"),
	preload("res://assets/models/environment/garden/tiles/tile_path3.glb"),
	preload("res://assets/models/environment/garden/tiles/tile_path4.glb"),
]

var visual_seed := 0
var variant_index := -1
var quarter_turns := 0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = visual_seed
	variant_index = rng.randi_range(0, VARIANTS.size() - 1)
	quarter_turns = rng.randi_range(0, 3)
	var visual := $PathVisual as Node3D
	if variant_index != 0:
		remove_child(visual)
		visual.queue_free()
		visual = VARIANTS[variant_index].instantiate() as Node3D
		visual.name = "PathVisual"
		add_child(visual)
	visual.position = Vector3(0.0, -0.25, 0.0)
	visual.rotation.y = float(quarter_turns) * PI * 0.5
