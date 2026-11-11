extends Control

const LEVEL_SELECT := "res://scenes/level_select.tscn"

@onready var menu: VBoxContainer = $Center/Menu
@onready var options_panel: PanelContainer = $Center/OptionsPanel
@onready var player_panel: PanelContainer = $Center/PlayerPanel
@onready var player_list: VBoxContainer = $Center/PlayerPanel/Contents/Scroll/Players
@onready var player_name_input: LineEdit = $Center/PlayerPanel/Contents/Name
@onready var player_message: Label = $Center/PlayerPanel/Contents/Message
@onready var music_enabled: CheckBox = $Center/OptionsPanel/Settings/MusicEnabled
@onready var music_volume: HSlider = $Center/OptionsPanel/Settings/MusicVolume
@onready var sfx_enabled: CheckBox = $Center/OptionsPanel/Settings/SfxEnabled
@onready var sfx_volume: HSlider = $Center/OptionsPanel/Settings/SfxVolume
@onready var hints_enabled: CheckBox = $Center/OptionsPanel/Settings/HintsEnabled


func _ready() -> void:
	$Center/Menu/Start.pressed.connect(_start)
	$Center/Menu/Options.pressed.connect(_show_options)
	$Center/Menu/Quit.pressed.connect(func() -> void: get_tree().quit())
	$Center/OptionsPanel/Settings/Back.pressed.connect(_show_menu)
	$Center/PlayerPanel/Contents/Back.pressed.connect(_show_menu)
	$Center/PlayerPanel/Contents/Create.pressed.connect(_create_player.bind(false))
	$Center/PlayerPanel/Contents/Import.pressed.connect(_create_player.bind(true))
	player_name_input.text_submitted.connect(func(_text: String) -> void: _create_player(false))
	# Set controls before connecting signals, so loading does not rewrite the save.
	music_enabled.button_pressed = AudioSettings.music_enabled
	music_volume.value = AudioSettings.music_volume
	sfx_enabled.button_pressed = AudioSettings.sfx_enabled
	sfx_volume.value = AudioSettings.sfx_volume
	hints_enabled.button_pressed = AudioSettings.hints_enabled
	music_enabled.toggled.connect(_set_music_enabled)
	music_volume.value_changed.connect(_set_music_volume)
	sfx_enabled.toggled.connect(_set_sfx_enabled)
	sfx_volume.value_changed.connect(_set_sfx_volume)
	hints_enabled.toggled.connect(_set_hints_enabled)


func _start() -> void:
	menu.hide()
	player_panel.show()
	_refresh_players()


func _refresh_players() -> void:
	for child in player_list.get_children():
		child.queue_free()
	for player in LevelProgress.players:
		var button := Button.new()
		button.text = "Continue as " + player.name
		button.pressed.connect(_continue_as.bind(player.id))
		player_list.add_child(button)
	$Center/PlayerPanel/Contents/Import.visible = LevelProgress.has_legacy_save()
	player_message.text = "Select a player, or enter a name to start a new game."
	if LevelProgress.has_legacy_save():
		player_message.text += " Enter a name to import the previous game."
	if LevelProgress.player_list_error != "":
		player_message.text = LevelProgress.player_list_error


func _create_player(import_previous: bool) -> void:
	var error := LevelProgress.create_player(player_name_input.text, import_previous)
	if error != "":
		player_message.text = error
		return
	get_tree().change_scene_to_file(LEVEL_SELECT)


func _continue_as(id: String) -> void:
	if LevelProgress.select_player(id):
		get_tree().change_scene_to_file(LEVEL_SELECT)
	else:
		player_message.text = "Could not open that player's saved game."


func _show_options() -> void:
	menu.hide()
	options_panel.show()


func _show_menu() -> void:
	options_panel.hide()
	player_panel.hide()
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


func _set_hints_enabled(enabled: bool) -> void:
	AudioSettings.hints_enabled = enabled
	AudioSettings.save()
