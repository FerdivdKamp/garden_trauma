extends Node

# The UI uses a 1152x648 design size. Godot normally enlarges canvas items
# linearly with the window; a square-root curve keeps the HUD readable on
# high-resolution displays without letting it dominate the 3D playfield.
const DESIGN_SIZE := Vector2(1152.0, 648.0)


func _ready() -> void:
	get_tree().root.size_changed.connect(_update_scale)
	_update_scale()


func _update_scale() -> void:
	var window := get_tree().root
	var window_size := Vector2(window.size)
	var automatic_scale := minf(window_size.x / DESIGN_SIZE.x, window_size.y / DESIGN_SIZE.y)
	if automatic_scale <= 0.0:
		return
	var factor := 1.0
	if automatic_scale > 1.0:
		factor = 1.0 / sqrt(automatic_scale)
	if not is_equal_approx(window.content_scale_factor, factor):
		window.content_scale_factor = factor
