extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	_check(music_bus >= 0 and sfx_bus >= 0, "Music and SFX buses exist")
	var settings := root.get_node("AudioSettings")
	var music := root.get_node("AudioManager/MusicPlayer") as AudioStreamPlayer
	_check(music != null and music.bus == "Music" and music.playing, "Autoload plays music on Music bus")

	var old_music_enabled: bool = settings.music_enabled
	var old_music_volume: float = settings.music_volume
	var old_sfx_enabled: bool = settings.sfx_enabled
	var old_sfx_volume: float = settings.sfx_volume
	settings.music_enabled = false
	settings.music_volume = 35.0
	settings.sfx_enabled = false
	settings.sfx_volume = 60.0
	settings.apply()
	_check(AudioServer.is_bus_mute(music_bus) and AudioServer.is_bus_mute(sfx_bus), "Settings mute both buses")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(music_bus), linear_to_db(0.35)), "Music volume controls its bus")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus), linear_to_db(0.6)), "SFX volume controls its bus")
	var test_settings_path := "res://.godot/test_audio_settings.cfg"
	settings.save(test_settings_path)
	settings.music_enabled = true
	settings.music_volume = 100.0
	settings.sfx_enabled = true
	settings.sfx_volume = 100.0
	settings.load_settings(test_settings_path)
	_check(not settings.music_enabled and is_equal_approx(settings.music_volume, 35.0) and not settings.sfx_enabled and is_equal_approx(settings.sfx_volume, 60.0), "Audio settings survive save and reload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_settings_path))
	settings.music_enabled = old_music_enabled
	settings.music_volume = old_music_volume
	settings.sfx_enabled = old_sfx_enabled
	settings.sfx_volume = old_sfx_volume
	settings.apply()

	var menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate() as Control
	root.add_child(menu)
	current_scene = menu
	_check(menu.get_node("Center/Menu/Start") is Button, "Start button exists")
	_check(menu.get_node("Center/OptionsPanel/Settings/MusicEnabled") is CheckBox, "Options controls exist")
	menu.get_node("Center/Menu/Options").pressed.emit()
	_check(menu.get_node("Center/OptionsPanel").visible, "Options opens")
	menu.get_node("Center/OptionsPanel/Settings/Back").pressed.emit()
	_check(menu.get_node("Center/Menu").visible, "Back returns to menu")
	var music_instance_id := music.get_instance_id()
	menu.get_node("Center/Menu/Start").pressed.emit()
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/tower_placement.tscn", "Start loads garden")
	_check(is_instance_valid(music) and music.get_instance_id() == music_instance_id and music.playing, "Music survives scene change")
	var garden := current_scene
	garden.waves.start_next_wave()
	garden.waves._process(0.0)
	var enemy := garden.get_node("PlacementPath/Enemy1")
	_check(enemy.get_node("DestroyedAudio") is AudioStreamPlayer3D and enemy.get_node("ObjectiveAudio").bus == "SFX", "Enemy cues use positional SFX")
	var tower_scene := load("res://scenes/tower_visual.tscn") as PackedScene
	var streams: Array[AudioStream] = []
	for tower_type in 3:
		var tower := tower_scene.instantiate()
		tower.set_tower_type(tower_type)
		garden.add_child(tower)
		var fire_audio := tower.get_node("FireAudio") as AudioStreamPlayer3D
		_check(fire_audio != null and fire_audio.bus == "SFX", "Tower %d uses positional SFX" % (tower_type + 1))
		streams.append(fire_audio.stream)
	_check(streams[0] != streams[1] and streams[1] != streams[2] and streams[0] != streams[2], "Towers use three distinct streams")
	if failures == 0:
		print("Audio pipeline tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
