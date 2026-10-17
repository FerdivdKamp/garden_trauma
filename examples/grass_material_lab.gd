extends Node3D

# Run with F6. Live edits affect scene copies; Save writes the Garden config.
const PALETTE = preload("res://scripts/grass_palette.gd")
const CONFIG = preload("res://scripts/grass_material_config.gd")
const GRASS_TILES := [
	preload("res://assets/models/environment/garden/tiles/tile_grass.glb"),
	preload("res://assets/models/environment/garden/tiles/tile_grass2.glb"),
	preload("res://assets/models/environment/garden/tiles/tile_grass3.glb"),
]

var grass_material: ShaderMaterial
var environment: Environment
var colors: Dictionary = {}
var color_controls: Dictionary = {}
var contrast_slider: HSlider
var preset_button: OptionButton
var sun_color_button: ColorPickerButton
var ambient_color_button: ColorPickerButton
var status_label: Label
var saved_settings: Dictionary = {}


func _ready() -> void:
	$Camera.look_at(Vector3(2.0, 0.0, 0.0), Vector3.UP)
	# The resource is shared by the playable Garden. Duplicate before tuning it.
	environment = ($WorldEnvironment as WorldEnvironment).environment.duplicate() as Environment
	($WorldEnvironment as WorldEnvironment).environment = environment
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("cbd2db")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("93b5d2")
	sky_material.sky_horizon_color = Color("dbe4dd")
	sky.sky_material = sky_material
	environment.sky = sky
	($Sun as DirectionalLight3D).light_color = Color("fff2dc")
	($Sun as DirectionalLight3D).light_energy = 1.0
	_build_tiles()
	if grass_material == null:
		push_error("The imported grass tiles have no world-space GrassTop material")
		return
	grass_material.set_shader_parameter("grass_three_color", true)
	grass_material.set_shader_parameter("material_metallic", 0.0)
	grass_material.set_shader_parameter("material_roughness", 0.95)
	grass_material.set_shader_parameter("material_specular", 0.25)
	saved_settings = CONFIG.load_settings()
	if not saved_settings.is_empty():
		CONFIG.apply_lighting($Sun, $WorldEnvironment, saved_settings)
		environment = ($WorldEnvironment as WorldEnvironment).environment
		var surface: Dictionary = saved_settings.get("grass", {})
		grass_material.set_shader_parameter("material_metallic", float(surface.get("metallic", 0.0)))
		grass_material.set_shader_parameter("material_roughness", float(surface.get("roughness", 0.95)))
		grass_material.set_shader_parameter("material_specular", float(surface.get("specular", 0.25)))
	_build_controls()
	_select_preset(PALETTE.SAVED_GARDEN)


func _build_tiles() -> void:
	# Fixed tile choices make color comparisons repeatable between runs.
	for z in 9:
		for x in 9:
			var tile := GRASS_TILES[(x * 7 + z * 11) % GRASS_TILES.size()].instantiate() as Node3D
			tile.name = "Grass_%d_%d" % [x, z]
			tile.position = Vector3((x - 4) * 2.0, 0.0, (z - 4) * 2.0)
			tile.rotation.y = float((x * 3 + z) % 4) * PI * 0.5
			$Tiles.add_child(tile)
			_use_shared_grass_material(tile)


func _use_shared_grass_material(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		for surface_index in instance.mesh.get_surface_count():
			var source := instance.get_surface_override_material(surface_index) as ShaderMaterial
			if source == null or source.get_shader_parameter("grass_world_variation") != true:
				continue
			if grass_material == null:
				grass_material = source.duplicate() as ShaderMaterial
			instance.set_surface_override_material(surface_index, grass_material)
	for child in node.get_children():
		_use_shared_grass_material(child)


func _build_controls() -> void:
	var panel := PanelContainer.new()
	panel.name = "TuningPanel"
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -430.0
	panel.offset_right = -12.0
	panel.offset_top = 12.0
	panel.offset_bottom = -12.0
	$Controls.add_child(panel)
	var padding := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		padding.add_theme_constant_override(side, 10)
	panel.add_child(padding)
	var scroll := ScrollContainer.new()
	padding.add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 370.0
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	_add_heading(content, "Grass material lab")
	_add_note(content, "Brightness sliders adjust each color. Click a swatch for full RGB controls. Choosing a palette resets the grass values.")
	var preset_row := HBoxContainer.new()
	content.add_child(preset_row)
	var preset_label := Label.new()
	preset_label.text = "Starting palette"
	preset_row.add_child(preset_label)
	preset_button = OptionButton.new()
	preset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_button.add_item("Current", PALETTE.CURRENT)
	preset_button.add_item("Summer late afternoon", PALETTE.SUMMER_LATE_AFTERNOON)
	preset_button.add_item("Preview green", PALETTE.PREVIEW_GREEN)
	preset_button.add_item("Saved Garden", PALETTE.SAVED_GARDEN)
	preset_button.select(PALETTE.SAVED_GARDEN)
	preset_button.item_selected.connect(_select_preset)
	preset_row.add_child(preset_button)
	_add_heading(content, "Grass colors")
	_add_color_control(content, "Dark", "dark")
	_add_color_control(content, "Middle", "middle")
	_add_color_control(content, "Light", "light")
	contrast_slider = _add_slider(content, "Contrast", 1.25, 0.0, 2.5, 0.01, _set_contrast)
	_add_heading(content, "Directional light")
	sun_color_button = _add_color_button(content, "Light color", ($Sun as DirectionalLight3D).light_color, _set_sun_color)
	_add_slider(content, "Energy", ($Sun as DirectionalLight3D).light_energy, 0.0, 3.0, 0.01, _set_sun_energy)
	_add_heading(content, "World environment")
	var ambient_source := OptionButton.new()
	ambient_source.add_item("Soft neutral color", Environment.AMBIENT_SOURCE_COLOR)
	ambient_source.add_item("Sky", Environment.AMBIENT_SOURCE_SKY)
	ambient_source.select(1 if environment.ambient_light_source == Environment.AMBIENT_SOURCE_SKY else 0)
	ambient_source.item_selected.connect(_set_ambient_source)
	content.add_child(ambient_source)
	ambient_color_button = _add_color_button(content, "Ambient color", environment.ambient_light_color, _set_ambient_color)
	_add_slider(content, "Ambient energy", environment.ambient_light_energy, 0.0, 2.0, 0.01, _set_ambient_energy)
	var tonemap_label := Label.new()
	tonemap_label.text = "Tonemap"
	content.add_child(tonemap_label)
	var tonemap := OptionButton.new()
	tonemap.add_item("Filmic", Environment.TONE_MAPPER_FILMIC)
	tonemap.add_item("AgX", Environment.TONE_MAPPER_AGX)
	tonemap.select(1 if environment.tonemap_mode == Environment.TONE_MAPPER_AGX else 0)
	tonemap.item_selected.connect(_set_tonemap)
	content.add_child(tonemap)
	_add_heading(content, "Grass surface")
	_add_slider(content, "Metallic", float(grass_material.get_shader_parameter("material_metallic")), 0.0, 1.0, 0.01, _set_metallic)
	_add_slider(content, "Roughness", float(grass_material.get_shader_parameter("material_roughness")), 0.85, 1.0, 0.005, _set_roughness)
	_add_slider(content, "Specular", float(grass_material.get_shader_parameter("material_specular")), 0.0, 0.5, 0.01, _set_specular)
	var save_button := Button.new()
	save_button.text = "Save to Garden config"
	save_button.pressed.connect(_save_settings)
	content.add_child(save_button)
	var copy_button := Button.new()
	copy_button.text = "Copy summary"
	copy_button.pressed.connect(_copy_settings)
	content.add_child(copy_button)
	status_label = Label.new()
	content.add_child(status_label)


func _add_heading(parent: VBoxContainer, title: String) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 20)
	parent.add_child(label)


func _add_note(parent: VBoxContainer, message: String) -> void:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)


func _add_color_control(parent: VBoxContainer, title: String, key: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 65.0
	row.add_child(label)
	var picker := ColorPickerButton.new()
	picker.custom_minimum_size = Vector2(72.0, 28.0)
	picker.color_changed.connect(_set_color.bind(key))
	row.add_child(picker)
	var hex_label := Label.new()
	hex_label.custom_minimum_size.x = 78.0
	row.add_child(hex_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.005
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_set_color_brightness.bind(key))
	row.add_child(slider)
	color_controls[key] = {"picker": picker, "hex": hex_label, "slider": slider}


func _add_color_button(parent: VBoxContainer, title: String, initial: Color, callback: Callable) -> ColorPickerButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var button := ColorPickerButton.new()
	button.custom_minimum_size = Vector2(100.0, 28.0)
	button.color = initial
	button.color_changed.connect(callback)
	row.add_child(button)
	return button


func _add_slider(parent: VBoxContainer, title: String, initial: float, minimum: float, maximum: float, increment: float, callback: Callable) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 120.0
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = increment
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 42.0
	value_label.text = "%.2f" % initial
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%.2f" % value
		callback.call(value)
	)
	return slider


func _select_preset(index: int) -> void:
	if index == PALETTE.SAVED_GARDEN:
		saved_settings = CONFIG.load_settings()
		var saved: Dictionary = saved_settings.get("grass", {})
		colors = {
			"dark": CONFIG.color_from(saved, "dark", PALETTE.PREVIEW_DARK),
			"middle": CONFIG.color_from(saved, "middle", PALETTE.PREVIEW_MIDDLE),
			"light": CONFIG.color_from(saved, "light", PALETTE.PREVIEW_LIGHT),
		}
		contrast_slider.value = float(saved.get("contrast", PALETTE.PREVIEW_CONTRAST))
	elif index == PALETTE.CURRENT:
		colors = {"dark": PALETTE.CURRENT_DARK, "middle": PALETTE.CURRENT_MIDDLE, "light": PALETTE.CURRENT_LIGHT}
		contrast_slider.value = PALETTE.CURRENT_CONTRAST
	elif index == PALETTE.SUMMER_LATE_AFTERNOON:
		colors = {"dark": PALETTE.SUMMER_DARK, "middle": PALETTE.SUMMER_MIDDLE, "light": PALETTE.SUMMER_LIGHT}
		contrast_slider.value = PALETTE.SUMMER_CONTRAST
	else:
		colors = {"dark": PALETTE.PREVIEW_DARK, "middle": PALETTE.PREVIEW_MIDDLE, "light": PALETTE.PREVIEW_LIGHT}
		contrast_slider.value = PALETTE.PREVIEW_CONTRAST
	for key in colors:
		_update_color_control(key)
	_apply_colors()


func _update_color_control(key: String) -> void:
	var control: Dictionary = color_controls[key]
	var color: Color = colors[key]
	var picker := control["picker"] as ColorPickerButton
	picker.set_block_signals(true)
	picker.color = color
	picker.set_block_signals(false)
	(control["hex"] as Label).text = "#" + color.to_html(false)
	(control["slider"] as HSlider).set_value_no_signal(color.v)


func _set_color(color: Color, key: String) -> void:
	colors[key] = color
	_update_color_control(key)
	_apply_colors()


func _set_color_brightness(value: float, key: String) -> void:
	var old: Color = colors[key]
	colors[key] = Color.from_hsv(old.h, old.s, value)
	_update_color_control(key)
	_apply_colors()


func _apply_colors() -> void:
	grass_material.set_shader_parameter("color_a", colors["dark"])
	grass_material.set_shader_parameter("grass_color_middle", colors["middle"])
	grass_material.set_shader_parameter("color_b", colors["light"])


func _set_contrast(value: float) -> void:
	grass_material.set_shader_parameter("grass_color_strength", value)


func _set_sun_color(value: Color) -> void:
	($Sun as DirectionalLight3D).light_color = value


func _set_sun_energy(value: float) -> void:
	($Sun as DirectionalLight3D).light_energy = value


func _set_ambient_source(index: int) -> void:
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR if index == 0 else Environment.AMBIENT_SOURCE_SKY
	ambient_color_button.disabled = index == 1


func _set_ambient_color(value: Color) -> void:
	environment.ambient_light_color = value


func _set_ambient_energy(value: float) -> void:
	environment.ambient_light_energy = value


func _set_tonemap(index: int) -> void:
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC if index == 0 else Environment.TONE_MAPPER_AGX


func _set_metallic(value: float) -> void:
	grass_material.set_shader_parameter("material_metallic", value)


func _set_roughness(value: float) -> void:
	grass_material.set_shader_parameter("material_roughness", value)


func _set_specular(value: float) -> void:
	grass_material.set_shader_parameter("material_specular", value)


func _save_settings() -> void:
	var settings := {
		"grass": {
			"dark": "#" + (colors["dark"] as Color).to_html(false),
			"middle": "#" + (colors["middle"] as Color).to_html(false),
			"light": "#" + (colors["light"] as Color).to_html(false),
			"contrast": _config_number(contrast_slider.value),
			"metallic": _config_number(float(grass_material.get_shader_parameter("material_metallic"))),
			"roughness": _config_number(float(grass_material.get_shader_parameter("material_roughness"))),
			"specular": _config_number(float(grass_material.get_shader_parameter("material_specular"))),
		},
		"sun": {
			"color": "#" + ($Sun as DirectionalLight3D).light_color.to_html(false),
			"energy": _config_number(($Sun as DirectionalLight3D).light_energy),
		},
		"ambient": {
			"source": "sky" if environment.ambient_light_source == Environment.AMBIENT_SOURCE_SKY else "color",
			"color": "#" + environment.ambient_light_color.to_html(false),
			"energy": _config_number(environment.ambient_light_energy),
		},
		"tonemap": "agx" if environment.tonemap_mode == Environment.TONE_MAPPER_AGX else "filmic",
	}
	var result: Error = CONFIG.save_settings(settings)
	if result != OK:
		status_label.text = "Save failed: " + error_string(result)
		return
	saved_settings = settings
	preset_button.select(PALETTE.SAVED_GARDEN)
	status_label.text = "Saved to " + CONFIG.PATH


func _config_number(value: float) -> float:
	# Inspector and slider floats carry tiny binary rounding differences.
	return float("%.3f" % value)


func _copy_settings() -> void:
	var text := "Grass: dark #%s, middle #%s, light #%s; contrast %.2f\n" % [colors["dark"].to_html(false), colors["middle"].to_html(false), colors["light"].to_html(false), contrast_slider.value]
	text += "Sun: #%s, energy %.2f\n" % [($Sun as DirectionalLight3D).light_color.to_html(false), ($Sun as DirectionalLight3D).light_energy]
	text += "Ambient: %s, #%s, energy %.2f; tonemap %s\n" % ["Sky" if environment.ambient_light_source == Environment.AMBIENT_SOURCE_SKY else "Color", environment.ambient_light_color.to_html(false), environment.ambient_light_energy, "AgX" if environment.tonemap_mode == Environment.TONE_MAPPER_AGX else "Filmic"]
	text += "Grass surface: metallic %.2f, roughness %.2f, specular %.2f" % [grass_material.get_shader_parameter("material_metallic"), grass_material.get_shader_parameter("material_roughness"), grass_material.get_shader_parameter("material_specular")]
	DisplayServer.clipboard_set(text)
	status_label.text = "Settings copied to clipboard."
