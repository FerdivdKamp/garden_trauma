extends SceneTree

const LightningEffect = preload("res://scripts/lightning_effect.gd")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/lightning_effect.tscn") as PackedScene
	var effect := scene.instantiate() as LightningEffect
	effect.segment_count = 5
	effect.width = 0.12
	effect.jitter = 0.5
	effect.color = Color("66ccff")
	effect.lifetime = 0.15
	root.add_child(effect)
	await process_frame
	_check(effect.bolt_mesh != null and effect.bolt_material.emission_enabled, "Effect preloads emissive geometry")
	var start := Vector3(0.0, 1.0, 0.0)
	var target := Vector3(4.0, 1.0, 0.0)
	effect.strike(start, target)
	_check(effect.active and effect.visible, "Strike shows the bolt")
	var vertices: PackedVector3Array = effect.bolt_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	_check(vertices.size() == 5 * 12, "Configurable segment count creates crossed ribbons")
	_check(vertices[0].distance_to(start) < effect.width, "Bolt starts at requested point")
	var closest_end := INF
	for index in range(vertices.size() - 12, vertices.size()):
		closest_end = minf(closest_end, vertices[index].distance_to(target))
	_check(closest_end < effect.width, "Bolt ends at requested point")
	var first_vertices := vertices.duplicate()
	effect._process(effect.refresh_interval)
	vertices = effect.bolt_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	_check(vertices != first_vertices, "Bolt jitter refreshes during the strike")
	effect._process(effect.lifetime)
	_check(not effect.active and not effect.visible, "Bolt hides after its lifetime")
	if failures == 0:
		print("Lightning effect tests passed")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
