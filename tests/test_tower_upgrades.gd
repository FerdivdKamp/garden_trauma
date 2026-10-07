extends SceneTree

const Attack = preload("res://scripts/placement_tower_attack.gd")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var definitions := DefinitionLoader.load_towers()
	for id in definitions:
		var definition := definitions[id] as TowerDefinition
		_check(definition.upgrades.size() == 3, "%s has three parsed upgrades" % id)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/towers/toy_tank.json"))
	var invalid := data.duplicate(true)
	invalid.upgrades[0].attack = {}
	_check(not DefinitionLoader.validate_tower_data(invalid), "Empty attack override is rejected")
	invalid = data.duplicate(true)
	invalid.upgrades[0].attack = {"targeting": "first"}
	_check(not DefinitionLoader.validate_tower_data(invalid), "Non-attack replacement is rejected")
	invalid = data.duplicate(true)
	invalid.upgrades.pop_back()
	_check(not DefinitionLoader.validate_tower_data(invalid), "Fewer than three upgrades is rejected")

	var scene := load("res://scenes/tower_placement.tscn") as PackedScene
	var garden := scene.instantiate()
	root.add_child(garden)
	garden._select_tower(0)
	garden.place_tower(Vector3(-8, 0, 8))
	var tower: Node3D = garden.placed_towers.get_child(0)
	var attack := tower.get_node("Attack") as Attack
	var base_damage := attack.definition.damage
	var base_cooldown := attack.definition.cooldown
	var base_range := attack.definition.attack_range
	var first_cost: int = attack.next_upgrade().cost
	_check(attack.buy_next_upgrade(first_cost - 1) == 0 and attack.upgrade_level == 0, "Unaffordable upgrade is blocked")
	_check(attack.buy_next_upgrade(first_cost) == first_cost and attack.upgrade_level == 1, "First purchase uses first cost")
	_check(attack.definition.damage > base_damage and attack.definition.cooldown == base_cooldown and attack.definition.attack_range == base_range, "Partial override preserves other attack values")
	_check(garden.tower_definitions["toy_tank"].damage == base_damage, "Placed tower has independent attack stats")
	var second_cost: int = attack.next_upgrade().cost
	_check(attack.buy_next_upgrade(second_cost) == second_cost and attack.upgrade_level == 2, "Second purchase follows first")
	_check(attack.definition.cooldown < base_cooldown, "Second override replaces cooldown")
	var third_cost: int = attack.next_upgrade().cost
	_check(attack.buy_next_upgrade(third_cost) == third_cost and attack.upgrade_level == 3, "Third purchase follows second")
	_check(attack.next_upgrade().is_empty() and attack.buy_next_upgrade(10000) == 0 and attack.upgrade_level == 3, "Upgrade stops at level three")
	garden.currency = 100
	garden._select_placed_tower(tower)
	_check(garden.upgrade_panel.visible and garden.upgrade_button.disabled, "Click selection shows the maxed tower")
	garden.currency = 1000
	garden._select_tower(0)
	garden.place_tower(Vector3(8, 0, 8))
	var other: Node3D = garden.placed_towers.get_child(1)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = garden.camera.unproject_position(other.global_position + Vector3(0, 0.6, 0))
	garden._unhandled_input(click)
	_check(garden.selected_tower == other and garden.upgrade_panel.visible, "Clicking a placed tower opens its upgrade panel")
	var other_attack := other.get_node("Attack") as Attack
	var cost: int = other_attack.next_upgrade().cost
	var coins_before: int = garden.currency
	garden.upgrade_button.pressed.emit()
	_check(other_attack.upgrade_level == 1 and garden.currency == coins_before - cost, "Upgrade button pays cost and upgrades selected tower")
	_check(attack.upgrade_level == 3, "Other tower's level stays independent")

	if failures == 0:
		print("Tower upgrade tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
