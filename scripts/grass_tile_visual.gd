class_name GrassTileVisual
extends Node3D

const VARIANTS := [
	preload("res://assets/models/environment/garden/tiles/tile_grass.glb"),
	preload("res://assets/models/environment/garden/tiles/tile_grass2.glb"),
	preload("res://assets/models/environment/garden/tiles/tile_grass3.glb"),
	preload("res://assets/models/environment/garden/tiles/tile_grass4.glb"),
]

var visual_seed := 0
var variant_index := -1
var quarter_turns := 0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = visual_seed
	variant_index = rng.randi_range(0, VARIANTS.size() - 1)
	quarter_turns = rng.randi_range(0, 3)
	var visual := $GrassVisual as Node3D
	if variant_index != VARIANTS.size() - 1:
		remove_child(visual)
		visual.queue_free()
		visual = VARIANTS[variant_index].instantiate() as Node3D
		visual.name = "GrassVisual"
		add_child(visual)
	visual.position = Vector3(0.0, -0.25, 0.0)
	visual.rotation.y = float(quarter_turns) * PI * 0.5
