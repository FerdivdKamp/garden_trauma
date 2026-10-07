extends Node

const SETTINGS_PATH := "user://settings.cfg"

var music_enabled := true
var music_volume := 80.0
var sfx_enabled := true
var sfx_volume := 80.0


func _ready() -> void:
	load_settings()


func load_settings(path: String = SETTINGS_PATH) -> void:
	var config := ConfigFile.new()
	if config.load(path) == OK:
		music_enabled = bool(config.get_value("audio", "music_enabled", music_enabled))
		music_volume = clampf(float(config.get_value("audio", "music_volume", music_volume)), 0.0, 100.0)
		sfx_enabled = bool(config.get_value("audio", "sfx_enabled", sfx_enabled))
		sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 100.0)
	apply()


func apply() -> void:
	_set_bus("Music", music_enabled, music_volume)
	_set_bus("SFX", sfx_enabled, sfx_volume)


func save(path: String = SETTINGS_PATH) -> void:
	apply()
	var config := ConfigFile.new()
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	config.set_value("audio", "sfx_volume", sfx_volume)
	var error := config.save(path)
	if error != OK:
		push_error("Could not save audio settings: %s" % error_string(error))


func _set_bus(bus_name: String, enabled: bool, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_error("Missing audio bus: " + bus_name)
		return
	AudioServer.set_bus_mute(index, not enabled or volume <= 0.0)
	# Never pass zero to the logarithmic decibel conversion.
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume / 100.0, 0.001)))
