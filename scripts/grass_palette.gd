class_name GrassPalette
extends RefCounted

const CONFIG = preload("res://scripts/grass_material_config.gd")

# These are the exact colors from the first grass material pass. Keeping them
# here makes "Current" a durable preset, even after the summer palette changes.
const CURRENT_DARK := Color("245f19")
const CURRENT_MIDDLE := Color("508126")
const CURRENT_LIGHT := Color("699a30")
const CURRENT_CONTRAST := 1.25

const SUMMER_DARK := Color("236c15")
const SUMMER_MIDDLE := Color("65911d")
const SUMMER_LIGHT := Color("87ad24")
const SUMMER_CONTRAST := 1.7

# const PREVIEW_DARK := Color("17480f")
# const PREVIEW_MIDDLE := Color("477019")
# const PREVIEW_LIGHT := Color("608b20")
# const PREVIEW_CONTRAST := 1.8

const PREVIEW_DARK := Color("397d21")
const PREVIEW_MIDDLE := Color("72b52b")
const PREVIEW_LIGHT := Color("a1d843")
const PREVIEW_CONTRAST := 1.25


const CURRENT := 0
const SUMMER_LATE_AFTERNOON := 1
const PREVIEW_GREEN := 2
const SAVED_GARDEN := 3


static func apply_to(root: Node, preset: int) -> int:
	var materials: Dictionary = {}
	var settings := CONFIG.load_settings() if preset == SAVED_GARDEN else {}
	return _apply_recursive(root, preset, materials, settings)


static func _apply_recursive(node: Node, preset: int, materials: Dictionary, settings: Dictionary) -> int:
	var changed := 0
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var surface_count := 0 if instance.mesh == null else instance.mesh.get_surface_count()
		for surface_index in surface_count:
			var source := instance.get_surface_override_material(surface_index) as ShaderMaterial
			if source == null or source.get_shader_parameter("grass_world_variation") != true:
				continue
			var key := source.get_instance_id()
			if not materials.has(key):
				# Imported GLB materials may be shared by many tile instances. Duplicate
				# once per source so changing this grid cannot recolor another scene.
				var variant := source.duplicate() as ShaderMaterial
				variant.set_shader_parameter("grass_three_color", true)
				if preset == SAVED_GARDEN and settings.has("grass"):
					var saved: Dictionary = settings["grass"]
					variant.set_shader_parameter("color_a", CONFIG.color_from(saved, "dark", PREVIEW_DARK))
					variant.set_shader_parameter("grass_color_middle", CONFIG.color_from(saved, "middle", PREVIEW_MIDDLE))
					variant.set_shader_parameter("color_b", CONFIG.color_from(saved, "light", PREVIEW_LIGHT))
					variant.set_shader_parameter("grass_color_strength", float(saved.get("contrast", PREVIEW_CONTRAST)))
					variant.set_shader_parameter("material_metallic", float(saved.get("metallic", 0.0)))
					variant.set_shader_parameter("material_roughness", float(saved.get("roughness", 0.9)))
					variant.set_shader_parameter("material_specular", float(saved.get("specular", 0.5)))
				elif preset == PREVIEW_GREEN:
					variant.set_shader_parameter("color_a", PREVIEW_DARK)
					variant.set_shader_parameter("grass_color_middle", PREVIEW_MIDDLE)
					variant.set_shader_parameter("color_b", PREVIEW_LIGHT)
					variant.set_shader_parameter("grass_color_strength", PREVIEW_CONTRAST)
				elif preset == SUMMER_LATE_AFTERNOON:
					variant.set_shader_parameter("color_a", SUMMER_DARK)
					variant.set_shader_parameter("grass_color_middle", SUMMER_MIDDLE)
					variant.set_shader_parameter("color_b", SUMMER_LIGHT)
					variant.set_shader_parameter("grass_color_strength", SUMMER_CONTRAST)
				else:
					variant.set_shader_parameter("color_a", CURRENT_DARK)
					variant.set_shader_parameter("grass_color_middle", CURRENT_MIDDLE)
					variant.set_shader_parameter("color_b", CURRENT_LIGHT)
					variant.set_shader_parameter("grass_color_strength", CURRENT_CONTRAST)
				materials[key] = variant
			instance.set_surface_override_material(surface_index, materials[key])
			changed += 1
	for child in node.get_children():
		changed += _apply_recursive(child, preset, materials, settings)
	return changed
