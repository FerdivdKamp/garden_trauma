extends SceneTree

const DefinitionLoader = preload("res://scripts/definition_loader.gd")
const TowerDefinition = preload("res://scripts/tower_definition.gd")
const UnitDefinition = preload("res://scripts/unit_definition.gd")

var failures := 0


func _initialize() -> void:
	var towers := DefinitionLoader.load_towers()
	var units := DefinitionLoader.load_units()
	_check(towers.size() == 1 and units.size() == 2, "Each JSON file loads once")
	var tower := towers.get("toy_tank") as TowerDefinition
	var red := units.get("red_sphere") as UnitDefinition
	_check(tower != null and red != null, "Loader returns typed resources")
	if tower != null and red != null:
		_check(tower.cost == 120 and tower.damage == 10.0 and tower.cooldown == 1.0, "Tower attack values come from JSON")
		_check(tower.attack_range == 6.0 and tower.targets.has("ground"), "Tower targeting comes from JSON")
		_check(red.health == 50.0 and red.speed == 3.0 and red.reward == 10, "Unit values come from JSON")
		_check(is_equal_approx(red.armor_for("physical"), 0.0), "Armor is accessed through the typed unit")
	_check(not DefinitionLoader.validate_tower_data(_read_fixture("invalid_tower")), "Invalid tower is rejected")
	_check(not DefinitionLoader.validate_unit_data(_read_fixture("invalid_unit")), "Invalid unit is rejected")
	if failures == 0:
		print("Definition tests passed")
	quit(1 if failures > 0 else 0)


func _read_fixture(name: String) -> Dictionary:
	var file := FileAccess.open("res://tests/fixtures/%s.json" % name, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	return data as Dictionary


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
