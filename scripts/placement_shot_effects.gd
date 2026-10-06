extends Node3D

const LIGHTNING_SCENE: PackedScene = preload("res://scenes/lightning_effect.tscn")
const LightningEffect = preload("res://scripts/lightning_effect.gd")
const LIGHTNING_POOL_SIZE := 16

# Hidden instances exist from startup so Godot can prepare their GPU pipelines.
# Shot copies share the meshes and materials instead of constructing them mid-frame.
const LASER_DURATION := 0.12
const SHELL_RADIUS := 0.12

var laser_template: MeshInstance3D
var shell_template: MeshInstance3D
var red_hit_template: GPUParticles3D
var debris_template: GPUParticles3D
var smoke_template: GPUParticles3D
var lightning_pool: Array[LightningEffect] = []
var next_lightning := 0


func _ready() -> void:
	laser_template = _make_laser_template()
	shell_template = _make_shell_template()
	red_hit_template = _make_particle_template("RedHitTemplate", Color("ff4141"), 14, 0.35, 2.0, false)
	debris_template = _make_particle_template("DebrisTemplate", Color("b4a18a"), 12, 0.5, 2.8, false)
	smoke_template = _make_particle_template("SmokeTemplate", Color(0.72, 0.72, 0.68, 0.55), 8, 0.3, 0.8, true)
	for index in LIGHTNING_POOL_SIZE:
		var bolt := LIGHTNING_SCENE.instantiate() as LightningEffect
		bolt.name = "Lightning%d" % index
		add_child(bolt)
		lightning_pool.append(bolt)


func fire_lightning(start: Vector3, target: Vector3) -> void:
	# Each call is one visual hop. A chain attack can call this for every link.
	var index := next_lightning
	for offset in lightning_pool.size():
		var candidate := (next_lightning + offset) % lightning_pool.size()
		if not lightning_pool[candidate].active:
			index = candidate
			break
	var bolt := lightning_pool[index]
	next_lightning = (index + 1) % lightning_pool.size()
	bolt.strike(start, target)


func fire_laser(start: Vector3, hit: Vector3) -> void:
	var difference := hit - start
	if difference.length_squared() < 0.001:
		return
	# The template cylinder is one unit high along local Y. Scale Y for this shot.
	var beam := laser_template.duplicate() as MeshInstance3D
	beam.name = "LaserBeam"
	beam.visible = true
	beam.scale.y = difference.length()
	add_child(beam)
	beam.global_position = (start + hit) * 0.5
	beam.quaternion = Quaternion(Vector3.UP, difference.normalized())
	_spawn_burst(red_hit_template, "RedHit", hit)
	get_tree().create_timer(LASER_DURATION).timeout.connect(beam.queue_free)


func fire_shell(start: Vector3, hit: Vector3, speed: float) -> void:
	var shell := shell_template.duplicate() as MeshInstance3D
	shell.name = "Shell"
	shell.visible = true
	add_child(shell)
	shell.global_position = start
	# The smoke is emitted once at the barrel, then expands independently of it.
	_spawn_burst(smoke_template, "MuzzleSmoke", start)
	var travel_time := clampf(start.distance_to(hit) / maxf(speed, 0.01), 0.05, 2.0)
	var flight := create_tween()
	flight.tween_property(shell, "global_position", hit, travel_time)
	flight.tween_callback(_shell_impact.bind(shell, hit))


func _shell_impact(shell: MeshInstance3D, hit: Vector3) -> void:
	shell.queue_free()
	_spawn_burst(debris_template, "ImpactDebris", hit)


func _spawn_burst(template: GPUParticles3D, effect_name: String, at: Vector3) -> void:
	var particles := template.duplicate() as GPUParticles3D
	particles.name = effect_name
	particles.emitting = false
	particles.visible = true
	add_child(particles)
	particles.global_position = at
	particles.finished.connect(particles.queue_free)
	particles.emitting = true


func _make_laser_template() -> MeshInstance3D:
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.04
	beam_mesh.bottom_radius = 0.04
	beam_mesh.height = 1.0
	var beam := MeshInstance3D.new()
	beam.name = "LaserTemplate"
	beam.mesh = beam_mesh
	beam.material_override = _material(Color("ff3535"), true)
	beam.visible = false
	add_child(beam)
	return beam


func _make_shell_template() -> MeshInstance3D:
	var shell_mesh := SphereMesh.new()
	shell_mesh.radius = SHELL_RADIUS
	shell_mesh.height = SHELL_RADIUS * 2.0
	var shell := MeshInstance3D.new()
	shell.name = "ShellTemplate"
	shell.mesh = shell_mesh
	shell.material_override = _material(Color("3b4147"))
	shell.visible = false
	add_child(shell)
	return shell


func _make_particle_template(template_name: String, color: Color, count: int, lifetime: float, speed: float, smoke: bool) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = template_name
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = count
	particles.lifetime = lifetime
	particles.local_coords = false
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = speed * 0.5
	process.initial_velocity_max = speed
	process.gravity = Vector3(0.0, 0.4, 0.0) if smoke else Vector3(0.0, -4.0, 0.0)
	process.color = color
	if smoke:
		# The curves change size and opacity over each particle's short lifetime.
		var scale := Curve.new()
		scale.add_point(Vector2(0.0, 0.2))
		scale.add_point(Vector2(1.0, 1.0))
		var scale_texture := CurveTexture.new()
		scale_texture.curve = scale
		process.scale_curve = scale_texture
		var fade := Curve.new()
		fade.add_point(Vector2(0.0, 1.0))
		fade.add_point(Vector2(1.0, 0.0))
		var fade_texture := CurveTexture.new()
		fade_texture.curve = fade
		process.alpha_curve = fade_texture
	particles.process_material = process
	var piece := SphereMesh.new()
	piece.radius = 0.13 if smoke else 0.07
	piece.height = piece.radius * 2.0
	var particle_material := _material(Color.WHITE if not smoke else Color(1.0, 1.0, 1.0, 0.75))
	# ParticleProcessMaterial writes color to vertices; the draw material must read it.
	particle_material.vertex_color_use_as_albedo = true
	piece.material = particle_material
	particles.draw_pass_1 = piece
	particles.visible = false
	add_child(particles)
	# The hidden one-shot starts its particle process during scene startup.
	particles.emitting = true
	return particles


func _material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
