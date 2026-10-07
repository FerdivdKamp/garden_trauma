class_name DefinitionLoader
extends RefCounted

const TOWER_DIR := "res://data/towers"
const TOWER_OVERRIDE_DIR := "user://tower_definitions"
const UNIT_DIR := "res://data/units"
const ID_PATTERN := "^[a-z][a-z0-9_]*$"
const KNOWN_TAGS := ["ground", "air", "mechanical", "projectile", "physical", "electric"]
const DAMAGE_TYPES := ["physical", "electric"]

# Schemas give editor autocomplete; these checks protect the game at runtime.
# Keep their constraints in sync when adding a configuration field.
static func load_tower(path: String) -> TowerDefinition:
	var data := _read_object(path)
	if not _valid_tower(data):
		push_error("Invalid tower definition: %s" % path)
		return null
	var result := TowerDefinition.new()
	result.id = data.id
	result.name = data.name
	result.cost = data.cost
	result.damage = data.attack.damage
	result.cooldown = data.attack.cooldown
	result.attack_range = data.attack.range
	result.detection_range = data.get("detection_range", 9.0)
	result.turn_speed = data.get("turn_speed", 90.0)
	result.projectile_speed = data.attack.projectile_speed
	result.damage_type = data.get("damage_type", "physical")
	result.bonus_vs_tags = data.get("bonus_vs_tags", {}).duplicate()
	result.targets = PackedStringArray(data.targeting.targets)
	result.priority = data.targeting.priority
	result.tags = PackedStringArray(data.tags)
	for upgrade in data.get("upgrades", []):
		result.upgrades.append((upgrade as Dictionary).duplicate(true))
	return result


static func load_unit(path: String) -> UnitDefinition:
	var data := _read_object(path)
	if not _valid_unit(data):
		push_error("Invalid unit definition: %s" % path)
		return null
	var result := UnitDefinition.new()
	result.id = data.id
	result.name = data.name
	result.health = data.health
	result.speed = data.speed
	result.reward = data.reward
	result.armor = data.get("armor", {}).duplicate()
	result.tags = PackedStringArray(data.tags)
	return result


static func load_towers(override_directory := "") -> Dictionary:
	var definitions := _load_directory(TOWER_DIR, true)
	if not override_directory.is_empty() and DirAccess.dir_exists_absolute(override_directory):
		for id in definitions:
			var path := override_directory.path_join(id + ".json")
			if FileAccess.file_exists(path):
				var override := load_tower(path)
				if override != null and override.id == id:
					# Older playground saves predate upgrades; retain the built-in path.
					if override.upgrades.is_empty():
						override.upgrades = definitions[id].upgrades.duplicate(true)
					definitions[id] = override
	return definitions


static func save_tower_override(definition: TowerDefinition, directory := TOWER_OVERRIDE_DIR) -> bool:
	var data := {
		"id": definition.id, "name": definition.name, "cost": definition.cost,
		"attack": {"damage": definition.damage, "cooldown": definition.cooldown,
			"range": definition.attack_range, "projectile_speed": definition.projectile_speed},
		"targeting": {"targets": Array(definition.targets), "priority": definition.priority},
		"damage_type": definition.damage_type, "bonus_vs_tags": definition.bonus_vs_tags,
		"tags": Array(definition.tags), "detection_range": definition.detection_range,
		"turn_speed": definition.turn_speed, "upgrades": definition.upgrades
	}
	if not _valid_tower(data):
		push_error("Cannot save invalid tower definition: %s" % definition.id)
		return false
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_error("Cannot create tower override directory")
		return false
	var path := directory.path_join(definition.id + ".json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot save tower definition: %s" % path)
		return false
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	return true


static func load_units() -> Dictionary:
	return _load_directory(UNIT_DIR, false)


static func validate_tower_data(data: Dictionary) -> bool:
	return _valid_tower(data)


static func validate_unit_data(data: Dictionary) -> bool:
	return _valid_unit(data)


static func _load_directory(directory: String, towers: bool) -> Dictionary:
	var definitions := {}
	var files := DirAccess.get_files_at(directory)
	files.sort()
	for filename in files:
		if not filename.ends_with(".json"):
			continue
		var path := directory.path_join(filename)
		var definition: Resource
		if towers:
			definition = load_tower(path)
		else:
			definition = load_unit(path)
		if definition == null:
			continue
		var id: String = definition.id
		if definitions.has(id):
			push_error("Duplicate definition ID '%s' in %s" % [id, path])
			continue
		definitions[id] = definition
	return definitions


static func _read_object(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return {}
	return parser.data


static func _valid_tower(data: Dictionary) -> bool:
	if not _identity(data) or not _number(data.get("cost"), 0.0, true):
		return false
	if not _string_array(data.get("tags"), KNOWN_TAGS):
		return false
	var attack = data.get("attack")
	var targeting = data.get("targeting")
	if not attack is Dictionary or not targeting is Dictionary:
		return false
	if not _number(attack.get("damage"), 0.0) or not _number(attack.get("cooldown"), 0.0, false, true):
		return false
	if not _number(attack.get("range"), 0.0, false, true) or not _number(attack.get("projectile_speed"), 0.0, false, true):
		return false
	if not _string_array(targeting.get("targets"), ["ground", "air"]) or targeting.get("priority") not in ["first", "nearest", "last"]:
		return false
	if data.has("damage_type") and data.damage_type not in DAMAGE_TYPES:
		return false
	if data.has("detection_range") and not _number(data.detection_range, 0.0, false, true):
		return false
	if data.has("turn_speed") and not _number(data.turn_speed, 0.0):
		return false
	var bonuses = data.get("bonus_vs_tags", {})
	if not bonuses is Dictionary:
		return false
	for tag in bonuses:
		if tag not in KNOWN_TAGS or not _number(bonuses[tag], 0.0):
			return false
	if data.has("upgrades"):
		if not data.upgrades is Array or data.upgrades.size() != 3:
			return false
		var ids := {}
		for upgrade in data.upgrades:
			if not upgrade is Dictionary or not _identity(upgrade) or not _number(upgrade.get("cost"), 1.0, true):
				return false
			if ids.has(upgrade.id) or not upgrade.get("attack") is Dictionary or upgrade.attack.is_empty():
				return false
			ids[upgrade.id] = true
			for key in upgrade:
				if key not in ["id", "name", "cost", "attack"]:
					return false
			for key in upgrade.attack:
				if key not in ["damage", "cooldown", "range", "projectile_speed"]:
					return false
				if not _number(upgrade.attack[key], 0.0, false, key != "damage"):
					return false
	return true


static func _valid_unit(data: Dictionary) -> bool:
	if not _identity(data) or not _number(data.get("health"), 0.0, false, true):
		return false
	if not _number(data.get("speed"), 0.0) or not _number(data.get("reward"), 0.0, true):
		return false
	if not _string_array(data.get("tags"), KNOWN_TAGS):
		return false
	var armor = data.get("armor", {})
	if not armor is Dictionary:
		return false
	for damage_type in armor:
		if damage_type not in DAMAGE_TYPES or not _number(armor[damage_type], -1.0) or armor[damage_type] > 1.0:
			return false
	return true


static func _identity(data: Dictionary) -> bool:
	if not data.get("id") is String or not data.get("name") is String:
		return false
	var regex := RegEx.new()
	regex.compile(ID_PATTERN)
	return regex.search(data.id) != null and not data.name.strip_edges().is_empty()


static func _number(value: Variant, minimum: float, integer := false, exclusive := false) -> bool:
	if integer:
		return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	if not is_finite(float(value)):
		return false
	return value > minimum if exclusive else value >= minimum


static func _string_array(value: Variant, allowed: Array) -> bool:
	if not value is Array or value.is_empty():
		return false
	var seen := {}
	for item in value:
		if not item is String or item not in allowed or seen.has(item):
			return false
		seen[item] = true
	return true
