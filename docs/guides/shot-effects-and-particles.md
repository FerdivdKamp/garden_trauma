# Tower shot effects

Open `scenes/tower_placement.tscn`, place the Laser Tower and Double Tank near the path, and start a wave. To spawn enemies manually, enable `debug_mode` on the scene root in the Inspector. The Laser Tower draws a short red laser and a red hit burst. The Double Tank alternates small shells between its barrels; each shot emits a little expanding smoke at the muzzle and debris when the shell reaches its captured hit point.

## How the nodes work

1. The Laser Tower uses the `turret_yaw`, `turret_pitch`, and `muzzle` empties from `laser_tower.blend`. Their imported `Node3D` transforms drive aiming and the shot origin. The placeholder Double Tank still creates `Marker3D` muzzle nodes in `tower_visual.gd`. In the editor's **Remote** scene tree, expand `LaserTower` or `TurretPivot` on a placed tower to inspect them.
2. `placement_tower_attack.gd` chooses a target and applies the existing damage rules. It asks `ShotEffects` to show the corresponding shot. Damage still occurs when the attack fires; the shell's flight is visual feedback and does not change combat timing.
3. `placement_shot_effects.gd` keeps a hidden, one-unit `CylinderMesh` ready from startup. A shot copies its node, scales its local Y axis to the muzzle-to-target distance, places it at the midpoint, and rotates it toward the target. A scene timer removes it after 0.12 seconds.
4. A shell copies a ready `SphereMesh` and moves it with a `Tween`. The tween calls `_shell_impact()` when it reaches the captured target position. Capturing that position makes the shot understandable even when an enemy moves or is defeated during flight.
5. The smoke and hit bursts are one-shot `GPUParticles3D` nodes. `ParticleProcessMaterial` controls direction, spread, speed, gravity, color, and the smoke's growth and fade curves; the particle `draw_pass_1` is a tiny sphere mesh. Its `StandardMaterial3D` enables **Vertex Color > Use as Albedo** so particle colors are visible. Each burst frees itself through the `finished` signal. These built-in resources provide the particle behavior without a custom shader.

## Try changing it

- In `placement_shot_effects.gd`, change `LASER_DURATION` or the laser cylinder radius to see how beam timing and width affect readability.
- Change the smoke `Curve` points from `(0, 0.2)` and `(1, 1)` to make puffs grow faster or slower.
- Change `_burst()`'s `count`, `lifetime`, `speed`, `spread`, or `gravity` values to compare a tight spark with a broad dust cloud.
- Change `attack.projectile_speed` in `data/towers/double_tank.json` to see the shell tween use the tower definition's speed.

The **Remote** scene tree is useful here: select a live `MuzzleSmoke` or `ImpactDebris` node and inspect its `GPUParticles3D` settings and `ParticleProcessMaterial` in the Inspector. The laser and shell meshes are separate from particles because each is one deliberate shot with a known start and end; particles are for a short burst of many small pieces.

## First-shot pause

The original version built every mesh, material, curve, and particle emitter when a shot fired. That work can delay the attack frame, and the GPU may need to compile a rendering pipeline the first time it sees an effect. The current version creates hidden templates for the laser, shell, red hit, debris, and smoke when the placement scene starts. A shot duplicates a template node and shares its mesh and material resources. The hidden particle templates run one invisible burst at startup to initialize their particle process. This moves the setup work out of the first attack and lets Godot see all effect types early. It can make scene startup slightly slower; the GPU driver may still need to compile pipelines on a new machine or after a driver update. See [Godot's pipeline compilation guide](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html).

Godot reference: [GPUParticles3D](https://docs.godotengine.org/en/4.7/classes/class_gpuparticles3d.html) and [ParticleProcessMaterial](https://docs.godotengine.org/en/4.7/classes/class_particleprocessmaterial.html).
