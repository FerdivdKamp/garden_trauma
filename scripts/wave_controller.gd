class_name WaveController
extends Node

signal spawn_requested(enemy_id: String)
signal state_changed
signal all_waves_cleared

enum State { READY, SPAWNING, INTERMISSION, DONE }

@export_file("*.json") var schedule_file := "res://levels/waves/garden_test_01.json"

var waves: Array[Dictionary] = []
var state := State.READY
var current_wave := -1
var remaining_to_spawn := 0
var active_enemies := 0
var spawn_clock := 0.0
var break_remaining := 0.0


func _ready() -> void:
	var file := FileAccess.open(schedule_file, FileAccess.READ)
	if file == null:
		push_error("Cannot open wave schedule: " + schedule_file)
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or not data.get("waves") is Array:
		push_error("Wave schedule needs a waves array: " + schedule_file)
		return
	for entry in data.waves:
		if not entry is Dictionary or not _valid_enemies(entry) or float(entry.get("spawn_interval", 0.0)) <= 0.0 or float(entry.get("break_seconds", -1.0)) < 0.0:
			push_error("Invalid wave in " + schedule_file)
			waves.clear()
			return
		waves.append(entry)
	if waves.is_empty():
		push_error("Wave schedule is empty: " + schedule_file)


# Mixed waves list each spawn in order; older single-type schedules stay valid.
func _valid_enemies(entry: Dictionary) -> bool:
	if entry.has("enemy_ids"):
		var ids: Variant = entry.enemy_ids
		if not ids is Array or ids.is_empty():
			return false
		for id in ids:
			if not id is String or id.is_empty():
				return false
		return true
	return entry.get("enemy_id") is String and not entry.enemy_id.is_empty() and int(entry.get("count", 0)) > 0


func start_next_wave() -> bool:
	if state != State.READY or current_wave + 1 >= waves.size():
		return false
	current_wave += 1
	var wave := waves[current_wave]
	remaining_to_spawn = wave.enemy_ids.size() if wave.has("enemy_ids") else int(wave.count)
	spawn_clock = 0.0
	state = State.SPAWNING
	state_changed.emit()
	return true


func _process(delta: float) -> void:
	if state == State.SPAWNING:
		spawn_clock -= delta
		while remaining_to_spawn > 0 and spawn_clock <= 0.0:
			remaining_to_spawn -= 1
			active_enemies += 1
			var wave := waves[current_wave]
			var enemy_id: String = wave.enemy_ids[wave.enemy_ids.size() - remaining_to_spawn - 1] if wave.has("enemy_ids") else wave.enemy_id
			spawn_requested.emit(enemy_id)
			spawn_clock += float(waves[current_wave].spawn_interval)
		state_changed.emit()
		_check_wave_cleared()
	elif state == State.INTERMISSION:
		break_remaining = maxf(0.0, break_remaining - delta)
		if break_remaining <= 0.0:
			state = State.READY
			state_changed.emit()


func enemy_resolved() -> void:
	active_enemies = maxi(0, active_enemies - 1)
	state_changed.emit()
	_check_wave_cleared()


func stop() -> void:
	state = State.DONE
	set_process(false)
	state_changed.emit()


func _check_wave_cleared() -> void:
	if state != State.SPAWNING or remaining_to_spawn > 0 or active_enemies > 0:
		return
	if current_wave == waves.size() - 1:
		state = State.DONE
		state_changed.emit()
		all_waves_cleared.emit()
	else:
		break_remaining = float(waves[current_wave].break_seconds)
		state = State.INTERMISSION if break_remaining > 0.0 else State.READY
		state_changed.emit()
