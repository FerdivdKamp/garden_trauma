extends SceneTree

const MODEL: PackedScene = preload("res://assets/models/environment/garden/tiles/tile_grass4.glb")
const PATH_MODEL: PackedScene = preload("res://assets/models/environment/garden/tiles/tile_path.glb")
const PREVIEW: PackedScene = preload("res://examples/grass_material_preview.tscn")
const SHADER: Shader = preload("res://shaders/procedural_noise_color_ramp.gdshader")
const MANIFEST_PATH := "res://assets/models/environment/garden/tiles/tile_grass4.materials.json"

var failures: int = 0


func _initialize() -> void:
	var scene: Node = MODEL.instantiate()
	var mesh_instance: MeshInstance3D = _find_mesh(scene)
	if mesh_instance == null:
		push_error("Imported tile has no MeshInstance3D")
		scene.free()
		quit(1)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	var grass_top: Dictionary = {}
	for material: Dictionary in manifest["materials"]:
		if material["name"] == "GrassTop":
			grass_top = material
	_expect(not grass_top.is_empty(), "GrassTop is present in the manifest")
	var translated_count: int = 0
	for index: int in mesh_instance.mesh.get_surface_count():
		var original: Material = mesh_instance.mesh.surface_get_material(index)
		var override: Material = mesh_instance.get_surface_override_material(index)
		if original == null:
			continue
		if original.resource_name == "GrassTop":
			translated_count += 1
			_expect(override is ShaderMaterial, "GrassTop has a ShaderMaterial override")
			if override is ShaderMaterial:
				var translated: ShaderMaterial = override
				_expect(translated.shader == SHADER, "GrassTop uses the shared shader")
				_expect(is_equal_approx(float(translated.get_shader_parameter("noise_scale")), float(grass_top["noise"]["scale"])), "Noise scale matches Blender")
				_expect(is_equal_approx(float(translated.get_shader_parameter("material_roughness")), float(grass_top["principled"]["roughness"])), "Roughness matches Blender")
				var first_color: Color = translated.get_shader_parameter("color_a")
				first_color = first_color.srgb_to_linear()
				_expect(is_equal_approx(first_color.r, float(grass_top["color_ramp"]["elements"][0]["color"][0])), "Ramp color matches Blender")
		elif original.resource_name == "GrassSides":
			_expect(override == null, "GrassSides keeps its GLB material")
	_expect(translated_count == 1, "One GrassTop surface was translated")
	var path_scene: Node = PATH_MODEL.instantiate()
	var path_mesh: MeshInstance3D = _find_mesh(path_scene)
	_expect(path_mesh != null, "Imported path has a MeshInstance3D")
	if path_mesh != null:
		var path_shader_count := 0
		for index: int in path_mesh.mesh.get_surface_count():
			var original: Material = path_mesh.mesh.surface_get_material(index)
			if original != null and original.resource_name == "GrassTop":
				var path_override: Material = path_mesh.get_surface_override_material(index)
				_expect(path_override is ShaderMaterial, "Path top has a ShaderMaterial override")
				if path_override is ShaderMaterial:
					_expect(path_override.shader == SHADER, "Path top uses the shared shader")
				path_shader_count += 1
		_expect(path_shader_count == 1, "One path top surface was translated")
	path_scene.free()
	var preview: Node = PREVIEW.instantiate()
	_expect(preview.get_node_or_null("Camera") is Camera3D, "Preview scene has a camera")
	preview.free()
	scene.free()
	if failures == 0:
		print("Asset material import passed")
	quit(1 if failures else 0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child: Node in node.get_children():
		var result: MeshInstance3D = _find_mesh(child)
		if result != null:
			return result
	return null
