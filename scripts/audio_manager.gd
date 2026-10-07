extends Node

const GARDEN_THEME: AudioStreamOggVorbis = preload("res://assets/audio/music/garden_theme_01.ogg")

var music_player: AudioStreamPlayer


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	# The autoload and its player stay alive during change_scene_to_file().
	var looping_theme := GARDEN_THEME.duplicate() as AudioStreamOggVorbis
	looping_theme.loop = true
	music_player.stream = looping_theme
	add_child(music_player)
	music_player.play()
