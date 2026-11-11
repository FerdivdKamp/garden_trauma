extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var settings = root.get_node("AudioSettings")
	var old_hints: bool = settings.hints_enabled
	var old_music: bool = settings.music_enabled
	var old_volume: float = settings.music_volume
	settings.save_path = "res://.godot/pause_options_test.cfg"
	settings.hints_enabled = false
	settings.music_enabled = true
	settings.music_volume = 65.0
	var garden = (load("res://scenes/tower_placement.tscn") as PackedScene).instantiate()
	root.add_child(garden)
	_check(not garden.status.visible and not garden.help_panel.visible, "Both hint areas start hidden when hints are off")
	_check(garden.help_panel.is_ancestor_of(garden.status) and not garden.palette.is_ancestor_of(garden.status), "Placement message belongs to the top-left hint panel")
	await process_frame
	var palette_size: Vector2 = garden.palette.size
	garden._pause_battle()
	var actions = garden.get_node("UI/PauseOverlay/Center/Panel/Actions")
	var options = garden.get_node("UI/PauseOverlay/Center/Panel/Settings")
	actions.get_node("Options").pressed.emit()
	_check(paused and options.visible and not actions.visible, "Options opens without resuming the game")
	_check(options.get_node("MusicEnabled").button_pressed and is_equal_approx(options.get_node("MusicVolume").value, 65.0), "Pause controls show current settings")
	options.get_node("HintsEnabled").button_pressed = true
	_check(settings.hints_enabled and garden.status.visible and garden.help_panel.visible, "Enabling hints updates both areas immediately")
	await process_frame
	_check(garden.palette.size.is_equal_approx(palette_size), "Showing hints does not expand the tower palette")
	var checkbox := options.get_node("HintsEnabled") as CheckBox
	_check(checkbox.get_theme_stylebox("hover_pressed") == checkbox.get_theme_stylebox("normal"), "Checked hover uses the same background as the normal checkbox")
	options.get_node("MusicEnabled").button_pressed = false
	options.get_node("MusicVolume").value = 42.0
	var saved := ConfigFile.new()
	_check(saved.load(settings.save_path) == OK and saved.get_value("gameplay", "hints_enabled", false), "Pause options save the hint preference")
	_check(not saved.get_value("audio", "music_enabled", true) and is_equal_approx(saved.get_value("audio", "music_volume", 0.0), 42.0), "Pause options save audio settings")
	options.get_node("HintsEnabled").button_pressed = false
	_check(not garden.status.visible and not garden.help_panel.visible, "Disabling hints hides both areas immediately")
	options.get_node("Back").pressed.emit()
	_check(paused and actions.visible and not options.visible, "Back returns to pause menu")
	actions.get_node("Resume").pressed.emit()
	_check(not paused and not garden.pause_overlay.visible, "Resume unpauses after options")
	settings.hints_enabled = old_hints
	settings.music_enabled = old_music
	settings.music_volume = old_volume
	settings.apply()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.save_path))
	if failures == 0:
		print("Pause options tests passed")
	quit(1 if failures else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
