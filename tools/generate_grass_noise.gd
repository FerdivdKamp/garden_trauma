extends SceneTree

# Generates one large, smooth color field for the 40 m Garden. The shader
# samples the central 40 m of this 64 m texture in world coordinates.
const OUTPUT := "res://assets/textures/environment/garden/grass_color_noise.png"
const IMAGE_SIZE := 512


func _initialize() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 42017
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.45
	var image := Image.create(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBA8)
	for y in IMAGE_SIZE:
		for x in IMAGE_SIZE:
			var value := clampf(0.5 + noise.get_noise_2d(float(x), float(y)) * 0.4, 0.0, 1.0)
			image.set_pixel(x, y, Color(value, value, value))
	var result := image.save_png(OUTPUT)
	if result != OK:
		push_error("Could not save grass noise: %s" % error_string(result))
		quit(1)
		return
	print("Saved " + ProjectSettings.globalize_path(OUTPUT))
	quit()
