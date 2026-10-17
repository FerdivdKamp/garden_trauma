extends SceneTree

const GRID_SCRIPT = preload("res://scripts/level_grid.gd")
const PALETTE = preload("res://scripts/grass_palette.gd")
const CONFIG = preload("res://scripts/grass_material_config.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var grid := GRID_SCRIPT.new() as LevelGrid
	root.add_child(grid)
	var grass := _find_material_in_tile(grid, GrassTileVisual)
	var border := _find_material_in_tile(grid, PathTileVisual)
	if grass == null or border == null:
		push_error("A grass tile and path border must both use the grass shader")
		quit(1)
		return
	var saved: Dictionary = CONFIG.load_settings().get("grass", {})
	if not _matches(grass, Color(saved.get("dark", "#000000")), Color(saved.get("middle", "#000000")), Color(saved.get("light", "#000000")), float(saved.get("contrast", -1.0))) or not _matches(border, Color(saved.get("dark", "#000000")), Color(saved.get("middle", "#000000")), Color(saved.get("light", "#000000")), float(saved.get("contrast", -1.0))):
		push_error("The saved Garden setting must cover grass tiles and path borders")
		quit(1)
		return
	if not is_equal_approx(float(grass.get_shader_parameter("material_roughness")), float(saved.get("roughness", -1.0))) or not is_equal_approx(float(grass.get_shader_parameter("material_specular")), float(saved.get("specular", -1.0))):
		push_error("The saved Garden surface values must reach the material")
		quit(1)
		return
	grid.grass_palette = PALETTE.PREVIEW_GREEN
	grass = _find_material_in_tile(grid, GrassTileVisual)
	border = _find_material_in_tile(grid, PathTileVisual)
	if not _matches(grass, PALETTE.PREVIEW_DARK, PALETTE.PREVIEW_MIDDLE, PALETTE.PREVIEW_LIGHT, PALETTE.PREVIEW_CONTRAST) or not _matches(border, PALETTE.PREVIEW_DARK, PALETTE.PREVIEW_MIDDLE, PALETTE.PREVIEW_LIGHT, PALETTE.PREVIEW_CONTRAST):
		push_error("The preview setting must cover grass tiles and path borders")
		quit(1)
		return
	grid.grass_palette = PALETTE.SUMMER_LATE_AFTERNOON
	grass = _find_material_in_tile(grid, GrassTileVisual)
	border = _find_material_in_tile(grid, PathTileVisual)
	if not _matches(grass, PALETTE.SUMMER_DARK, PALETTE.SUMMER_MIDDLE, PALETTE.SUMMER_LIGHT, PALETTE.SUMMER_CONTRAST) or not _matches(border, PALETTE.SUMMER_DARK, PALETTE.SUMMER_MIDDLE, PALETTE.SUMMER_LIGHT, PALETTE.SUMMER_CONTRAST):
		push_error("The summer setting must restore the second material pass")
		quit(1)
		return
	grid.grass_palette = PALETTE.CURRENT
	grass = _find_material_in_tile(grid, GrassTileVisual)
	border = _find_material_in_tile(grid, PathTileVisual)
	if not _matches(grass, PALETTE.CURRENT_DARK, PALETTE.CURRENT_MIDDLE, PALETTE.CURRENT_LIGHT, PALETTE.CURRENT_CONTRAST) or not _matches(border, PALETTE.CURRENT_DARK, PALETTE.CURRENT_MIDDLE, PALETTE.CURRENT_LIGHT, PALETTE.CURRENT_CONTRAST):
		push_error("The Current setting must restore the first material pass")
		quit(1)
		return
	print("Grass palette switch passed")
	quit()


func _find_material_in_tile(grid: LevelGrid, tile_type: Variant) -> ShaderMaterial:
	for child in grid.get_children():
		if is_instance_of(child, tile_type):
			var material := _find_grass_material(child)
			if material != null:
				return material
	return null


func _find_grass_material(node: Node) -> ShaderMaterial:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			for surface_index in instance.mesh.get_surface_count():
				var material := instance.get_surface_override_material(surface_index) as ShaderMaterial
				if material != null and material.get_shader_parameter("grass_world_variation") == true:
					return material
	for child in node.get_children():
		var material := _find_grass_material(child)
		if material != null:
			return material
	return null


func _matches(material: ShaderMaterial, dark: Color, middle: Color, light: Color, contrast: float) -> bool:
	return material != null \
		and material.get_shader_parameter("grass_three_color") == true \
		and (material.get_shader_parameter("color_a") as Color).is_equal_approx(dark) \
		and (material.get_shader_parameter("grass_color_middle") as Color).is_equal_approx(middle) \
		and (material.get_shader_parameter("color_b") as Color).is_equal_approx(light) \
		and is_equal_approx(float(material.get_shader_parameter("grass_color_strength")), contrast)
