# Implement Water Rocket Tower — Garden Defense

Implement a new **Water Rocket Tower** for the Godot 4 tower-defense game, including a procedural placeholder model, tower configuration, firing animation, homing projectiles, and water particle effects.

Inspect the existing laser tower and double-barrel tank implementations first. Reuse their architecture, configuration format, targeting, upgrade, placement, and pivot conventions wherever possible. Do not introduce a separate tower framework.

## 1. Visual design

The tower resembles a whimsical plastic garden water-pressure rocket launcher, like a toy constructed from a small water pump.

Its silhouette should consist of:

- **Base:** A compact, chunky, rounded-square plastic base, approximately 1.0–1.2 m wide.
- **Main body:** A short cylindrical pump housing mounted on the base.
- **Accordion top:** A tall, vertically ribbed, flexible cylindrical bellows extending upward from the housing, resembling the expandable portion of a manual water pump. It should be wider near the top and taper slightly toward the bottom.
- **Rocket mount:** A small horizontal arm extending from the lower pump body, with an upward-facing nozzle or launcher seat.
- **Rocket:** A small, colorful toy rocket resting vertically on the nozzle, with a pointed tip and simple fins.

The overall appearance should be friendly, chunky, slightly exaggerated, and consistent with the bright plastic toy-diorama art direction.

Suggested placeholder colors:
- Pump housing: warm off-white plastic
- Accordion: light grey or pale blue
- Base: cream-white
- Rocket: yellow with red fins
- Water: bright translucent cyan

Avoid realistic military weapon styling.

Build the placeholder using Godot primitive meshes (cylinders, boxes, spheres, etc.), rather than requiring a Blender model. Keep its construction isolated so it can be replaced later.

## 2. Scene hierarchy and pivots

Follow the existing laser tower's pivot conventions and rotation implementation.

Conceptual hierarchy:

```text
WaterRocketTower
├── Base
├── TurretPivot                 # Yaw, rotates toward target
│   ├── PumpHousing
│   ├── AccordionPivot
│   │   └── AccordionMesh       # Animated vertically
│   ├── LauncherArm
│   │   └── Muzzle              # Marker3D
│   └── LoadedRocket            # Visual only
├── DetectionArea
├── AttackArea
└── Other existing tower components
```

This is conceptual; adapt it to the current scene architecture.

Requirements:
- The turret should rotate in yaw toward its selected target.
- The pump, accordion, launcher arm, and loaded rocket should rotate together.
- The actual fired rocket must become independent from the tower and travel through world space.
- Use `Marker3D` for the projectile spawn point.
- Clearly name pivots and animated components.
- Keep transforms compatible with replacing the placeholder with a Blender-exported GLB.
- Do not add barrel pitch rotation for V1.

Ensure the nozzle and rocket remain visually aligned during rotation.

## 3. Accordion firing animation

The defining feature of this tower is its spring-loaded water pump.

On firing:

1. Accordion begins at full height.
2. Accordion compresses vertically to approximately 55% of its original height.
3. Rocket launches as the compression reaches its lowest point.
4. Accordion quickly springs back to its original height.
5. A small overshoot/bounce gives it a rubbery toy-like feel.

Suggested timings:
- Compression: 0.18 seconds
- Launch at maximum compression
- Expansion: 0.25 seconds
- Small settling bounce: 0.10 seconds

Use a Tween with suitable easing.

Animate only the accordion visual component, not the entire tower. Keep the bottom of the accordion anchored so it does not sink into the pump housing.

Make the animation reusable and independent from target selection and projectile movement.

The cooldown should remain governed by the tower's existing attack system.

## 4. Homing water rocket

Implement a dedicated homing projectile scene and script, reusing existing projectile code where practical.

The rocket should:
- Move slowly enough that players can visually follow it.
- Spawn from the muzzle.
- Initially travel upward and slightly forward before steering toward its target.
- Gradually turn toward the target rather than instantly snapping to face it.
- Continuously adjust its direction as the target moves.
- Point its nose along its travel direction.
- Deal damage once on impact.
- Despawn after impact or when its maximum lifetime expires.

Suggested initial configuration:

```json
{
  "id": "water_rocket",
  "name": "Water Rocket",
  "cost": 140,
  "detection_range": 10.0,
  "turn_speed": 100.0,
  "attack": {
    "damage": 18,
    "cooldown": 2.5,
    "range": 8.0,
    "projectile_speed": 5.0,
    "homing_turn_speed": 120.0,
    "projectile_lifetime": 8.0
  },
  "targeting": {
    "targets": ["ground"],
    "priority": "nearest"
  },
  "damage_type": "water",
  "tags": ["projectile", "homing", "water"]
}
```

Adapt this to the actual tower schema. Do not change existing towers unnecessarily.

For V1, use a simple steering implementation:
- Store the current movement direction.
- Calculate the desired direction toward the target's current position.
- Rotate the current direction toward the desired direction by a maximum angular amount each physics frame.
- Move forward along the current direction.

Use delta-based movement and steering.

If the target disappears before impact, continue briefly along the last known direction, then despawn when the projectile lifetime expires. Do not crash or select an unrelated target.

For now, use direct-hit damage with no area-of-effect damage.

## 5. Water particle effects

Create two separate water effects.

### A. Rocket water trail

The rocket should continuously leave a short trail of bright cyan water droplets.

Use `GPUParticles3D` or an equivalent lightweight Godot particle solution.

Visual characteristics:
- Small blue/cyan droplets
- Slight random variation in size
- Short particle lifetime, approximately 0.4–0.8 seconds
- Gentle spread and falling motion
- A playful watery spray rather than smoke or fire

Particles should remain in world space after emission so they form a visible trail behind the moving rocket.

The particle trail should be attached to the rear of the rocket, opposite the direction of travel.

### B. Launch nozzle spray

When the rocket fires, the launcher nozzle should emit a short burst of water.

Suggested behavior:
- Short cyan spray upward and outward
- Duration approximately 0.2–0.35 seconds
- Slightly larger droplets than the rocket trail
- Coincides with the rocket's departure
- Automatically stops emitting after the burst

Use a separate particle emitter located at the muzzle.

The effects should be easy to tune and should not depend on external textures.

If a splash effect can be added cleanly, create a brief water-droplet burst on impact. Keep this optional and lightweight.

## 6. Integration

Integrate this tower with existing gameplay:

- Tower placement
- Cost deduction
- Target acquisition
- Yaw rotation
- Attack range and detection range
- Cooldown
- Damage system
- Existing upgrade mechanism
- Tower selection and UI
- Existing audio hooks, if present

Define three upgrade stages using the existing upgrade JSON structure. Use discrete stat changes rather than percentage modifiers.

Suggested upgrade progression:

| Level | Cost | Damage | Cooldown | Rocket speed |
|---|---:|---:|---:|---:|
| Base | — | 18 | 2.5 s | 5 |
| Mk2 | 50 | 24 | 2.5 s | 5 |
| Mk3 | 75 | 24 | 2.0 s | 6 |
| Mk4 | 100 | 36 | 2.0 s | 7 |

Do not add custom upgrade mechanics unless the existing system requires them.

## 7. Replaceable placeholder model

The procedural model must be temporary.

Document the expected Blender model hierarchy and pivot positions.

The final model should support:
- Base
- Yaw pivot
- Pump housing
- Accordion with independent animation pivot
- Launcher arm
- Muzzle marker
- Rocket visual

Avoid coupling projectile behavior to specific primitive meshes or material names.

When I replace the model later, I should only need to adjust node references or attach a model scene, not rewrite firing logic.

## 8. Testing and documentation

Add or update tests where the existing project supports them.

Verify:
- Tower can be placed and selected.
- Tower rotates toward enemies.
- Accordion compresses before rocket launch.
- Rocket launches from the correct muzzle position.
- Rocket follows moving enemies.
- Rocket deals damage only once.
- Rocket behaves safely when its target is destroyed.
- Particle effects start and stop correctly.
- Upgrades apply their configured stat changes.
- Existing towers continue working.

Document briefly:
- New scenes and scripts
- Where the placeholder geometry lives
- How the accordion animation works
- How homing steering works
- Which parameters control water effects
- How to replace the placeholder with a Blender model

Keep the implementation focused on V1. Prefer simple, readable GDScript and use comments explaining the Godot-specific behavior.

**Acceptance criteria:** I should be able to place a water rocket tower during gameplay, watch it turn toward an enemy, see the accordion compress, and watch a slow toy rocket fly from the nozzle, curve toward a moving target, and leave a visible trail of water droplets.