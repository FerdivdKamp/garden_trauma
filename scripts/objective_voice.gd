extends AudioStreamPlayer

const VOICE_DIRECTORY := "res://assets/audio/voices/attacker/objective_reached/"
const COOLDOWN_MSEC := 5000

var voice_clips: Array[AudioStream] = []
var next_play_msec: int = 0


func _ready() -> void:
	# ResourceLoader sees imported resources in exported games as well as the editor.
	for filename in ResourceLoader.list_directory(VOICE_DIRECTORY):
		if filename.to_lower().ends_with(".wav"):
			var clip := load(VOICE_DIRECTORY + filename) as AudioStream
			if clip != null:
				voice_clips.append(clip)


func play_objective_reached() -> void:
	# This is a reaction to the signal, not a count of enemies reaching the goal.
	# Ignore events during the cooldown instead of queueing delayed reactions.
	var now := Time.get_ticks_msec()
	if voice_clips.is_empty() or playing or now < next_play_msec:
		return
	stream = voice_clips.pick_random()
	play()
	next_play_msec = now + COOLDOWN_MSEC
