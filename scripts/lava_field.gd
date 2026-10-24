class_name LavaField
extends Node3D

const LavaProjectileScript = preload("res://scripts/lava_projectile.gd")
const LavaPuddleScript = preload("res://scripts/lava_puddle.gd")
const PlacementEnemy = preload("res://scripts/placement_enemy.gd")

var grid: LevelGrid
var enemies: Node3D
var waves: WaveController
var active := false
var puddles: Dictionary = {}
var pending: Dictionary = {}


func configure(level_grid: LevelGrid, enemy_container: Node3D, wave_controller: WaveController) -> void:
	grid = level_grid
	enemies = enemy_container
	waves = wave_controller
	waves.state_changed.connect(_on_wave_state_changed)
	_on_wave_state_changed()


func _on_wave_state_changed() -> void:
	var now_active := waves.state == WaveController.State.SPAWNING
	if active and not now_active:
		clear_wave()
	active = now_active


func is_covered(cell: Vector2i) -> bool:
	return puddles.has(cell) or pending.has(cell)


func launch(origin: Vector3, cell: Vector2i, shot: TowerDefinition) -> bool:
	if not active or not grid.is_walkable(cell) or is_covered(cell):
		return false
	# Reserve the cell during flight so a second lamp cannot launch onto it.
	pending[cell] = true
	var projectile := LavaProjectileScript.new() as LavaProjectile
	projectile.name = "LavaProjectile"
	add_child(projectile)
	projectile.configure(origin, grid.grid_to_world(cell), cell, shot)
	projectile.landed.connect(_on_projectile_landed)
	return true


func _on_projectile_landed(cell: Vector2i, shot: TowerDefinition) -> void:
	if not active or not pending.has(cell):
		return
	pending.erase(cell)
	var puddle := LavaPuddleScript.new() as LavaPuddle
	puddle.name = "LavaPuddle"
	add_child(puddle)
	puddle.configure(cell, grid.grid_to_world(cell), shot)
	puddles[cell] = puddle
	_damage_enemies(puddle, shot.damage)


func _physics_process(delta: float) -> void:
	if not active:
		return
	# One pass per enemy per puddle, using elapsed time rather than a timer per
	# collision shape. This also handles enemies entering between physics ticks.
	for puddle in puddles.values():
		if not active:
			break
		_damage_enemies(puddle as LavaPuddle, (puddle as LavaPuddle).damage_per_second * delta)


func _damage_enemies(puddle: LavaPuddle, damage: float) -> void:
	if enemies == null or not active or damage <= 0.0:
		return
	for child in enemies.get_children():
		var enemy := child as PlacementEnemy
		if enemy == null or enemy.health <= 0.0 or enemy.reached_objective or not "ground" in enemy.definition.tags:
			continue
		var delta_x := enemy.global_position.x - puddle.global_position.x
		var delta_z := enemy.global_position.z - puddle.global_position.z
		if delta_x * delta_x + delta_z * delta_z <= puddle.radius * puddle.radius:
			var multiplier := 1.0 - enemy.definition.armor_for(puddle.damage_type)
			enemy.take_damage(damage * multiplier)
			if not active:
				break


func clear_wave() -> void:
	active = false
	pending.clear()
	for child in get_children():
		if child is LavaProjectile:
			child.queue_free()
	for puddle in puddles.values():
		(puddle as LavaPuddle).cool()
	puddles.clear()
