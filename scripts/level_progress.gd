extends Node

# IDs stay stable even when a level's display name or files change. The order
# also defines progression: finishing one level unlocks the next entry.
const LEVELS := [
	{"id": "tower_test", "title": "Tower Test", "map": "res://levels/data/tower_test.json", "waves": "res://levels/waves/tower_test.json", "test": true},
	{"id": "garden_test_01", "title": "Garden 1", "map": "res://levels/data/garden_test_01.json", "waves": "res://levels/waves/garden_test_01.json"},
	{"id": "garden_test_02", "title": "Garden 2", "map": "res://levels/data/garden_test_02.json", "waves": "res://levels/waves/garden_test_02.json"},
	{"id": "garden_test_03", "title": "Garden 3", "map": "res://levels/data/garden_test_03.json", "waves": "res://levels/waves/garden_test_03.json"},

]
const DEFAULT_LEVEL_ID := "garden_test_01"
const BATTLE_SCENE := "res://scenes/tower_placement.tscn"
const INITIAL_TOWER := "laser_tower"
const TOWER_REWARDS := {"garden_test_01": "lightning_tower"}

var save_path := "user://progress.cfg"
var selected_level_id := DEFAULT_LEVEL_ID
var completed_ids: Array[String] = []
var players_index_path := "user://players.cfg"
var players_directory := "user://players"
var legacy_save_path := "user://progress.cfg"
var players: Array[Dictionary] = []
var active_player_id := ""
var active_player_name := ""
var legacy_imported := false
var player_list_error := ""


func _ready() -> void:
	load_players()
	load_progress()


func load_players() -> void:
	players.clear()
	legacy_imported = false
	player_list_error = ""
	var config := ConfigFile.new()
	var error := config.load(players_index_path)
	if error != OK:
		if FileAccess.file_exists(players_index_path):
			player_list_error = "Could not read the player list: " + error_string(error)
		return
	legacy_imported = config.get_value("players", "legacy_imported", false) == true
	var entries: Variant = config.get_value("players", "list", [])
	if entries is not Array:
		player_list_error = "The player list has an invalid format."
		return
	for entry in entries:
		if entry is Dictionary and entry.get("id") is String and entry.get("name") is String:
			var id: String = entry.id
			# Only generated hex IDs may become part of a file path.
			if id.length() == 32 and id.is_valid_hex_number(false) and not entry.name.strip_edges().is_empty():
				players.append({"id": id, "name": entry.name})
				continue
		player_list_error = "The player list contains an invalid entry."
		players.clear()
		return


func has_legacy_save() -> bool:
	return not legacy_imported and FileAccess.file_exists(legacy_save_path)


func create_player(player_name: String, import_legacy := false) -> String:
	if player_list_error != "":
		return player_list_error
	var clean_name := player_name.strip_edges()
	if clean_name.is_empty() or clean_name.length() > 32:
		return "Enter a name between 1 and 32 characters."
	for player in players:
		if player.name.to_lower() == clean_name.to_lower():
			return "That player name is already in use."
	if import_legacy and not has_legacy_save():
		return "The previous game is no longer available to import."
	var config := ConfigFile.new()
	if import_legacy:
		var read_error := config.load(legacy_save_path)
		if read_error != OK:
			return "Could not read the previous game: " + error_string(read_error)
	else:
		config.set_value("levels", "completed_ids", [])
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(players_directory))
	if directory_error != OK:
		return "Could not create the players folder: " + error_string(directory_error)
	var id := Crypto.new().generate_random_bytes(16).hex_encode()
	var player_path := players_directory.path_join(id + ".cfg")
	var save_error := config.save(player_path)
	if save_error != OK:
		return "Could not save the player: " + error_string(save_error)
	var previous_imported := legacy_imported
	players.append({"id": id, "name": clean_name})
	if import_legacy:
		legacy_imported = true
	var index := ConfigFile.new()
	index.set_value("players", "list", players)
	index.set_value("players", "legacy_imported", legacy_imported)
	var index_error := index.save(players_index_path)
	if index_error != OK:
		players.pop_back()
		legacy_imported = previous_imported
		return "Could not save the player list: " + error_string(index_error)
	select_player(id)
	return ""


func select_player(id: String) -> bool:
	for player in players:
		if player.id == id:
			var player_path := players_directory.path_join(id + ".cfg")
			var config := ConfigFile.new()
			if config.load(player_path) != OK:
				return false
			active_player_id = id
			active_player_name = player.name
			save_path = player_path
			selected_level_id = DEFAULT_LEVEL_ID
			load_progress()
			return true
	return false


func level_for(id: String) -> Dictionary:
	for level in LEVELS:
		if level.id == id:
			return level
	return {}


func is_completed(id: String) -> bool:
	return completed_ids.has(id)


func is_unlocked(id: String) -> bool:
	var previous_campaign_id := ""
	for index in LEVELS.size():
		var level: Dictionary = LEVELS[index]
		if level.get("test", false):
			if level.id == id:
				return true
			continue
		if level.id == id:
			return previous_campaign_id == "" or is_completed(previous_campaign_id)
		previous_campaign_id = level.id
	return false


func next_level_id(id: String) -> String:
	var found := false
	for level in LEVELS:
		if level.get("test", false):
			if level.id == id:
				return ""
			continue
		if found:
			return level.id
		found = level.id == id
	return ""


func is_tower_unlocked(id: String) -> bool:
	if id == INITIAL_TOWER:
		return true
	for level_id in TOWER_REWARDS:
		if TOWER_REWARDS[level_id] == id and is_completed(level_id):
			return true
	return false


func select_level(id: String) -> bool:
	if not is_unlocked(id):
		return false
	selected_level_id = id
	return true


func complete_level(id: String) -> void:
	var level := level_for(id)
	if level.is_empty() or level.get("test", false) or is_completed(id):
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
