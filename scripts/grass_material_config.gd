class_name GrassMaterialConfig
extends RefCounted

# This project file is the shared handoff between the tuning scene and Garden.
const PATH := "res://data/grass_material_settings.json"


static func load_settings() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		push_warning("Grass material settings are missing: " + PATH)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		push_warning("Grass material settings must be a JSON object: " + PATH)
		return {}
	return parsed


static func save_settings(settings: Dictionary) -> Error:
	# Resource files under res:// are writable while developing in the editor.
	# A packaged export is read-only; this is a design-time tuning tool.
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(settings, "\t") + "\n")
	return file.get_error()


static func color_from(section: Dictionary, key: String, fallback: Color) -> Color:
	var value: Variant = section.get(key)
	if value is String and Color.html_is_valid(value):
		return Color(value)
	return fallback


static func apply_lighting(sun: DirectionalLight3D, world: WorldEnvironment, settings: Dictionary) -> void:
	var sun_settings: Dictionary = settings.get("sun", {})
	sun.light_color = color_from(sun_settings, "color", sun.light_color)
	sun.light_energy = float(sun_settings.get("energy", sun.light_energy))
	# Scene resources may be shared. Give this scene its own Environment.
	var environment := world.environment.duplicate() as Environment
	world.environment = environment
	var ambient: Dictionary = settings.get("ambient", {})
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY if ambient.get("source", "color") == "sky" else Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = color_from(ambient, "color", environment.ambient_light_color)
	environment.ambient_light_energy = float(ambient.get("energy", environment.ambient_light_energy))
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX if settings.get("tonemap", "filmic") == "agx" else Environment.TONE_MAPPER_FILMIC
	if environment.ambient_light_source == Environment.AMBIENT_SOURCE_SKY:
		var sky := Sky.new()
		var sky_material := ProceduralSkyMaterial.new()
		sky_material.sky_top_color = Color("93b5d2")
		sky_material.sky_horizon_color = Color("dbe4dd")
		sky.sky_material = sky_material
		environment.sky = sky
