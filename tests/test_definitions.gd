extends SceneTree

const TEST_OVERRIDE_DIR := "res://tests/.generated_tower_overrides"

var failures := 0


func _initialize() -> void:
	var towers := DefinitionLoader.load_towers()
	var units := DefinitionLoader.load_units()
	_check(towers.size() == 3 and units.size() == 2, "Each JSON file loads once")
	var tower := towers.get("laser_tower") as TowerDefinition
	var double_tower := towers.get("double_tank") as TowerDefinition
	var lightning_tower := towers.get("lightning_tower") as TowerDefinition
	var red := units.get("windup_robot") as UnitDefinition
	_check(tower != null and double_tower != null and lightning_tower != null and red != null, "Loader returns typed resources")
	if lightning_tower != null:
		_check(lightning_tower.damage_type == "electric" and lightning_tower.tags.has("electric"), "Lightning tower loads electric damage")
	if tower != null and red != null:
		_check(tower.cost == 90 and tower.damage == 10.0 and tower.cooldown == 1.0, "Tower attack values come from JSON")
		_check(tower.attack_range == 6.0 and tower.targets.has("ground"), "Tower targeting comes from JSON")
		_check(tower.detection_range == 9.0 and tower.turn_speed == 90.0, "Tower aiming values come from JSON")
		_check(red.health == 50.0 and red.speed == 3.0 and red.reward == 10, "Unit values come from JSON")
		_check(is_equal_approx(red.armor_for("physical"), 0.0), "Armor is accessed through the typed unit")
	_check(not DefinitionLoader.validate_tower_data(_read_fixture("invalid_tower")), "Invalid tower is rejected")
	_check(not DefinitionLoader.validate_unit_data(_read_fixture("invalid_unit")), "Invalid unit is rejected")
	var edited := DefinitionLoader.load_tower("res://data/towers/laser_tower.json")
	edited.damage = 17.0
	_check(DefinitionLoader.save_tower_override(edited, TEST_OVERRIDE_DIR), "Tower override can be saved")
	var overridden := DefinitionLoader.load_towers(TEST_OVERRIDE_DIR).get("laser_tower") as TowerDefinition
	_check(overridden != null and overridden.damage == 17.0, "Tower override loads through the normal loader")
	DirAccess.remove_absolute(TEST_OVERRIDE_DIR.path_join("laser_tower.json"))
	DirAccess.remove_absolute(TEST_OVERRIDE_DIR)
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
