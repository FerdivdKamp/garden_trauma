class_name LevelBorder
extends Node3D

const FENCE_SCENE: PackedScene = preload("res://assets/models/props/border/fence_straight_01.glb")
const SEGMENT_LENGTH := 2.0


func build(grid_width: int, grid_height: int, horizontal_scale: int = 2, height_scale: float = 4.0) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var half_width := grid_width * SEGMENT_LENGTH * 0.5
	var half_height := grid_height * SEGMENT_LENGTH * 0.5
	# The imported module runs from its origin toward local -Z. Each side starts
	# at a corner, so the source post hides the join between neighboring rails.
	_add_side(Vector3(-half_width, 0.0, -half_height), -PI * 0.5, grid_width, horizontal_scale, height_scale)
	_add_side(Vector3(half_width, 0.0, -half_height), PI, grid_height, horizontal_scale, height_scale)
	_add_side(Vector3(half_width, 0.0, half_height), PI * 0.5, grid_width, horizontal_scale, height_scale)
	_add_side(Vector3(-half_width, 0.0, half_height), 0.0, grid_height, horizontal_scale, height_scale)


func _add_side(start: Vector3, yaw: float, cell_count: int, horizontal_scale: int, height_scale: float) -> void:
	var direction := Vector3.FORWARD.rotated(Vector3.UP, yaw)
	var cell_index := 0
	while cell_index < cell_count:
		# A short final section also closes sides whose cell count is odd.
		var span_cells := mini(horizontal_scale, cell_count - cell_index)
		var segment := FENCE_SCENE.instantiate() as Node3D
		segment.name = "Fence_%d" % get_child_count()
		segment.position = start + direction * (float(cell_index) * SEGMENT_LENGTH)
		segment.rotation.y = yaw
		segment.scale = Vector3(float(horizontal_scale), height_scale, float(span_cells))
		add_child(segment)
		cell_index += span_cells
