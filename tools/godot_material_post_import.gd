@tool
extends EditorScenePostImport

const PROCEDURAL_SHADER: Shader = preload("res://shaders/procedural_noise_color_ramp.gdshader")
const GRASS_COLOR_NOISE: Texture2D = preload("res://assets/textures/environment/garden/grass_color_noise.png")
const GRASS_COLOR_STRENGTH := 2.0
const GRASS_NORMAL_FLATTEN := 0.7


func _post_import(scene: Node) -> Object:
	var manifest_path: String = get_source_file().get_basename() + ".materials.json"
	if not FileAccess.file_exists(manifest_path):
		return scene
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		push_warning("Invalid material manifest: " + manifest_path)
		return scene
	var entries: Dictionary = {}
	for entry: Variant in parsed.get("materials", []):
		if entry is Dictionary and entry.has("name"):
			entries[entry["name"]] = entry
	var source_name := get_source_file().get_file()
	var world_space_tile := source_name.begins_with("tile_grass") or source_name.begins_with("tile_path")
	var grass_tile := source_name.begins_with("tile_grass")
	_apply_materials(scene, entries, world_space_tile, grass_tile)
	return scene


func _apply_materials(node: Node, entries: Dictionary, world_space_tile: bool, grass_tile: bool) -> void:
	if node is MeshInstance3D:
		var instance: MeshInstance3D = node
		var mesh: Mesh = instance.mesh
		if mesh != null:
			for surface_index: int in mesh.get_surface_count():
				var original: Material = mesh.surface_get_material(surface_index)
				if original == null or not entries.has(original.resource_name):
					continue
				var entry: Dictionary = entries[original.resource_name]
				var translated: ShaderMaterial = _make_material(entry, mesh.get_aabb(), world_space_tile, grass_tile)
				if translated != null:
					instance.set_surface_override_material(surface_index, translated)
	for child: Node in node.get_children():
		_apply_materials(child, entries, world_space_tile, grass_tile)


func _make_material(entry: Dictionary, bounds: AABB, world_space_tile: bool, grass_tile: bool) -> ShaderMaterial:
	if entry.get("classification") != "translatable" or entry.get("type") != "procedural_noise_color_ramp":
		return null
	var noise: Dictionary = entry.get("noise", {})
	var ramp: Dictionary = entry.get("color_ramp", {})
	var principled: Dictionary = entry.get("principled", {})
	var stops: Array = ramp.get("elements", [])
	if noise.get("dimensions") != "3D" or noise.get("coordinates") != "Generated":
		push_warning("Unsupported noise settings for " + str(entry.get("name", "material")))
		return null
	if float(noise.get("detail", 0.0)) > 8.0:
		push_warning("Noise detail exceeds eight octaves for " + str(entry.get("name", "material")))
		return null
	if ramp.get("color_mode") != "RGB" or ramp.get("interpolation") != "LINEAR" or stops.size() != 2:
		push_warning("Only two-stop linear RGB ramps are supported for " + str(entry.get("name", "material")))
		return null
	var first: Array = stops[0].get("color", [])
	var second: Array = stops[1].get("color", [])
	if first.size() != 4 or second.size() != 4 or float(first[3]) != 1.0 or float(second[3]) != 1.0 or float(principled.get("alpha", 1.0)) != 1.0:
		push_warning("Transparent ramps are not supported for " + str(entry.get("name", "material")))
		return null

	var result := ShaderMaterial.new()
	result.resource_name = str(entry.get("name", "procedural_material"))
	result.shader = PROCEDURAL_SHADER
	# Blender's ramp values are linear; source_color uniforms convert sRGB to
	# linear in the renderer, so store their sRGB counterparts here.
	result.set_shader_parameter("color_a", Color(float(first[0]), float(first[1]), float(first[2]), float(first[3])).linear_to_srgb())
	result.set_shader_parameter("color_b", Color(float(second[0]), float(second[1]), float(second[2]), float(second[3])).linear_to_srgb())
	result.set_shader_parameter("ramp_start", float(stops[0].get("position", 0.0)))
	result.set_shader_parameter("ramp_end", float(stops[1].get("position", 1.0)))
	result.set_shader_parameter("noise_scale", float(noise.get("scale", 3.0)))
	result.set_shader_parameter("noise_detail", float(noise.get("detail", 2.0)))
	result.set_shader_parameter("noise_roughness", float(noise.get("roughness", 0.5)))
	result.set_shader_parameter("noise_lacunarity", float(noise.get("lacunarity", 2.0)))
	result.set_shader_parameter("noise_distortion", float(noise.get("distortion", 0.0)))
	result.set_shader_parameter("material_roughness", float(principled.get("roughness", 0.5)))
	result.set_shader_parameter("material_metallic", float(principled.get("metallic", 0.0)))
	result.set_shader_parameter("generated_min", bounds.position)
	result.set_shader_parameter("generated_size", bounds.size)
	result.set_shader_parameter("use_world_space", world_space_tile)
	result.set_shader_parameter("world_noise_tile_size", 2.0)
	if grass_tile:
		# A shared world-space image supplies smooth color across tile borders.
		result.set_shader_parameter("grass_world_variation", true)
		result.set_shader_parameter("grass_color_noise", GRASS_COLOR_NOISE)
		result.set_shader_parameter("grass_color_strength", GRASS_COLOR_STRENGTH)
		result.set_shader_parameter("grass_normal_flatten", GRASS_NORMAL_FLATTEN)
	return result
