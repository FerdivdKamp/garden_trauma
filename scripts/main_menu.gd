extends Control

const LEVEL_SELECT := "res://scenes/level_select.tscn"

@onready var menu: VBoxContainer = $Center/Menu
@onready var options_panel: PanelContainer = $Center/OptionsPanel
@onready var music_enabled: CheckBox = $Center/OptionsPanel/Settings/MusicEnabled
@onready var music_volume: HSlider = $Center/OptionsPanel/Settings/MusicVolume
@onready var sfx_enabled: CheckBox = $Center/OptionsPanel/Settings/SfxEnabled
@onready var sfx_volume: HSlider = $Center/OptionsPanel/Settings/SfxVolume


func _ready() -> void:
	$Center/Menu/Start.pressed.connect(_start)
	$Center/Menu/Options.pressed.connect(_show_options)
	$Center/Menu/Quit.pressed.connect(func() -> void: get_tree().quit())
	$Center/OptionsPanel/Settings/Back.pressed.connect(_show_menu)
	# Set controls before connecting signals, so loading does not rewrite the save.
	music_enabled.button_pressed = AudioSettings.music_enabled
	music_volume.value = AudioSettings.music_volume
	sfx_enabled.button_pressed = AudioSettings.sfx_enabled
	sfx_volume.value = AudioSettings.sfx_volume
	music_enabled.toggled.connect(_set_music_enabled)
	music_volume.value_changed.connect(_set_music_volume)
	sfx_enabled.toggled.connect(_set_sfx_enabled)
	sfx_volume.value_changed.connect(_set_sfx_volume)


func _start() -> void:
	get_tree().change_scene_to_file(LEVEL_SELECT)


func _show_options() -> void:
	menu.hide()
	options_panel.show()


func _show_menu() -> void:
	options_panel.hide()
	menu.show()


func _set_music_enabled(enabled: bool) -> void:
	AudioSettings.music_enabled = enabled
	AudioSettings.save()


func _set_music_volume(value: float) -> void:
	AudioSettings.music_volume = value
	AudioSettings.save()


func _set_sfx_enabled(enabled: bool) -> void:
	AudioSettings.sfx_enabled = enabled
	AudioSettings.save()


func _set_sfx_volume(value: float) -> void:
	AudioSettings.sfx_volume = value
	AudioSettings.save()
