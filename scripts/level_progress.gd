extends Node

# IDs stay stable even when a level's display name or files change. The order
# also defines progression: finishing one level unlocks the next entry.
const LEVELS := [
	{"id": "garden_test_01", "title": "Garden 1", "map": "res://levels/data/garden_test_01.json", "waves": "res://levels/waves/garden_test_01.json"},
	{"id": "garden_test_02", "title": "Garden 2", "map": "res://levels/data/garden_test_02.json", "waves": "res://levels/waves/garden_test_02.json"},
]
const DEFAULT_LEVEL_ID := "garden_test_01"
const BATTLE_SCENE := "res://scenes/tower_placement.tscn"

var save_path := "user://progress.cfg"
var selected_level_id := DEFAULT_LEVEL_ID
var completed_ids: Array[String] = []


func _ready() -> void:
	load_progress()


func level_for(id: String) -> Dictionary:
	for level in LEVELS:
		if level.id == id:
			return level
	return {}


func is_completed(id: String) -> bool:
	return completed_ids.has(id)


func is_unlocked(id: String) -> bool:
	for index in LEVELS.size():
		if LEVELS[index].id == id:
			return index == 0 or is_completed(LEVELS[index - 1].id)
	return false


func next_level_id(id: String) -> String:
	for index in LEVELS.size() - 1:
		if LEVELS[index].id == id:
			return LEVELS[index + 1].id
	return ""


func select_level(id: String) -> bool:
	if not is_unlocked(id):
		return false
	selected_level_id = id
	return true


func complete_level(id: String) -> void:
	if level_for(id).is_empty() or is_completed(id):
		return
	completed_ids.append(id)
	save_progress()


func load_progress() -> void:
	completed_ids.clear()
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return
	var saved: Variant = config.get_value("levels", "completed_ids", [])
	if saved is Array or saved is PackedStringArray:
		for id in saved:
			if id is String and not level_for(id).is_empty() and not completed_ids.has(id):
				completed_ids.append(id)


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("levels", "completed_ids", completed_ids)
	var error := config.save(save_path)
	if error != OK:
		push_error("Could not save level progress: %s" % error_string(error))
