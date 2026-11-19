extends Node3D

const EnemyScene := preload("res://scenes/placement_enemy.tscn")
var enemies: Array[Node] = []


func _ready() -> void:
	_spawn_examples()


func _spawn_examples() -> void:
	for child in $Route.get_children():
		child.queue_free()
	enemies.clear()
	for entry in [[0, "windup_robot", 1.5], [3, "formula_car", 4.5], [4, "race_car_battery", 7.5]]:
		var unit := DefinitionLoader.load_unit("res://data/units/%s.json" % entry[1])
		var enemy := EnemyScene.instantiate()
		enemy.configure(entry[0], unit, 0.0, 1.0)
		$Route.add_child(enemy)
		enemy.progress = entry[2]
		enemy.set_process(false) # Keep the examples still until the button is pressed.
		enemies.append(enemy)


func _on_destroy_pressed() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.take_damage(enemy.health)
