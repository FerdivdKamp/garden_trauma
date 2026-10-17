# Implement Gumball Machine Tower — Garden Defense

Implement a new **Gumball Machine Tower** for the Godot 4 tower-defense game, including a procedural placeholder model, directional placement preview, automatic path alignment, and bouncing gumball projectiles.

Inspect the existing towers, placement logic, path/grid data structures, projectile implementation, and upgrade configuration first.

Reuse the current architecture wherever practical. Do not introduce an independent tower framework.

## 1. Core gameplay concept

Unlike the existing towers, the Gumball Machine does not target individual enemies.

Instead, it is a **directional lane-defense tower**.

It fires colorful gumballs in a straight line down an adjacent path. The gumballs bounce along the ground as they travel forward and damage enemies they encounter.

Key characteristics:

- Stationary tower with no animated mechanical parts.
- Fixed firing direction determined during placement.
- Automatically prefers the longest straight, adjacent path.
- Fires periodically, regardless of whether an enemy is currently in range.
- Gumballs bounce as they travel forward.
- Each gumball can hit multiple enemies along its path.
- Projectiles disappear when they reach the end of their valid lane.
- Placement preview makes the affected path and firing direction obvious.

This should be a simple, satisfying, visually playful tower that rewards clever placement.

## 2. Procedural placeholder model

Create a recognizable, cartoonish gumball vending machine.

The model should resemble a classic tabletop candy dispenser rather than a realistic industrial vending machine.

### Silhouette

**Base**
- Chunky square pedestal.
- Approximately 1.0–1.2 m wide.
- Rounded-looking corners where practical.
- Bright red plastic body.
- Slightly darker red lower base.

**Transparent globe**
- Large spherical or slightly flattened glass globe.
- Positioned above the red housing.
- Approximately 0.9 m diameter.
- Lightly tinted transparent material.
- Filled with visible, brightly colored gumballs.

**Top lid**
- Flat or gently domed red cap.
- Slightly wider than the neck of the globe.

**Dispensing mechanism**
- A round silver knob on the front housing.
- Decorative only: no rotation or moving parts required.

**Exit chute**
- A short rectangular outlet projecting from the front near the bottom.
- Dark opening surrounded by a metallic or red plastic frame.
- A small angled ramp or lip underneath.
- Clearly indicates the firing direction.

The exit chute should be large enough to read from the game's orthographic camera.

Use colorful gumballs inside the globe: yellow, cyan, lime, orange, pink, and purple.

Use Godot primitive meshes for the placeholder. No external assets required.

Keep the geometry isolated so it can be replaced with a Blender GLB later.

### Visual style

Match Garden Defense's existing visual direction:
- Bright plastic toy materials.
- Smooth, chunky silhouettes.
- Friendly and readable from above.
- Subtle plastic sheen.
- Warm lighting compatibility.
- Slightly exaggerated dimensions.

Avoid overly realistic glass rendering or expensive transparency effects.

If transparency causes sorting or readability issues, use a simple lightly tinted material or partial opacity.

## 3. Scene hierarchy and rotation

Conceptual hierarchy:

```text
GumballTower
├── Base
├── DirectionPivot
│   ├── MachineBody
│   ├── Globe
│   │   └── DecorativeGumballs
│   ├── Lid
│   ├── DispensingKnob
│   ├── ExitChute
│   └── Muzzle (Marker3D)
├── LanePreview
└── Other existing tower components
```

Adapt this to the existing project conventions.

The tower has **no moving parts during firing**.

`DirectionPivot` exists solely to orient the entire model toward the selected lane during placement.

Once placed, its direction remains fixed.

The muzzle marker should be positioned at the exit chute.

Keep the direction pivot compatible with the existing laser tower's Blender import conventions.

## 4. Directional path selection

This is the most important gameplay difference from existing towers.

The Gumball Machine may only fire along a straight contiguous segment of path tiles.

It must not shoot diagonally or follow path bends.

### Determine valid lanes

During placement, inspect the four cardinal directions:

- North
- East
- South
- West

For each direction:

1. Check whether the immediately adjacent tile is a valid traversable path tile.
2. If valid, continue examining tiles in that direction.
3. Stop at the first non-path tile or map boundary.
4. Record the resulting straight path length.
5. Reject lanes with no adjacent path tiles.

Automatically select the direction with the longest valid straight path.

If multiple directions have equal lengths, use a deterministic tie-breaker.

Path starts and objectives should count as traversable path tiles if their existing level representation permits enemies to walk there.

Use the actual level grid and path data; do not infer the path from mesh colors or collision geometry.

Do not accidentally include grass or decorative border tiles.

### Manual direction selection

While placing the tower, allow the player to cycle through valid directions.

Suggested control: `R` to rotate through valid directions.

The current direction should initially be the longest available lane.

Only offer directions that have at least one valid adjacent path tile.

Do not allow placement when no valid lane exists. Clearly show why placement is invalid.

Follow existing placement input conventions where possible.

### After placement

Store the selected direction and lane length.

Do not automatically rotate toward enemies.

The direction should remain fixed for the lifetime of the placed tower.

If the game currently supports changes to path layout, document how lane information would need to be recalculated. Dynamic recalculation is not necessary for V1.

## 5. Placement preview

The player must understand exactly which path the tower will shoot along before placement.

Extend the existing tower placement preview.

Show both **lane coverage** and **firing direction**.

### Lane coverage

Highlight all path tiles covered by the current firing direction.

Suggested appearance:
- Bright translucent yellow/cyan overlay.
- Thin borders on affected tiles.
- Coverage visible above the path surface.
- Should not obscure enemies or existing tiles excessively.

The highlighting should follow the straight lane only.

For example:

```text
      G > > > > >
      . = = = = =
```

Here `G` represents the gumball tower, and the arrows show its firing direction along the adjacent row of path tiles.

### Direction arrow

Show an additional clear arrow indicating projectile movement.

The arrow should:
- Start near the muzzle.
- Point along the selected lane.
- Extend toward the final valid tile.
- Be readable from the current orthographic camera.
- Update immediately when the direction changes.

Use simple Godot geometry or an existing line visualization system.

### Invalid placement

If no adjacent path lane is available:
- Show the existing invalid-placement feedback.
- Do not show a misleading valid lane.
- Prevent placement.

### UI feedback

If easy to integrate, display the selected lane length in tiles, for example:

`Gumball lane: East — 8 tiles`

Keep this optional if the existing placement UI cannot support it cleanly.

Remove the lane preview after confirming or cancelling placement.

## 6. Gumball projectile behavior

Implement a dedicated bouncing gumball projectile.

The projectile should move horizontally along its predefined straight lane.

It must **not**:
- Home toward enemies.
- Follow corners.
- Change direction based on enemy movement.
- Target the nearest enemy.

Instead, it travels from the muzzle toward the end of the selected lane.

### Movement

Use a fixed horizontal direction and configurable projectile speed.

Example:
- Projectile speed: 7 m/s
- Gumball diameter: approximately 0.25–0.35 m
- Projectile lifetime determined by lane distance, with a safety timeout

Projectiles should remain centered over the path lane.

### Bouncing animation

The gumball should visually bounce along the path like a rubber ball.

Implement the bounce using a sine wave or a simple deterministic animation.

Example:

```gdscript
visual_height = abs(sin(travel_time * bounce_frequency)) * bounce_height
```

Suggested:
- Bounce height: 0.4–0.7 m
- Bounce frequency: approximately 2–3 cycles per second
- Slight visual squash at ground contact, optional
- Slight rotation during travel, optional

Keep the projectile's logical horizontal position separate from its visual bounce offset.

This ensures bouncing does not interfere with collision detection.

The collision system should account for enemies on the ground rather than requiring the visual sphere to physically intersect their mesh at the top of every bounce.

### Despawn

Despawn the gumball when:
- It reaches the end of its selected straight lane.
- Its safety lifetime expires.
- The game or level is unloaded.

Do not continue into grass or around corners.

## 7. Enemy collision and damage

A gumball should be able to damage multiple enemies along the lane.

Suggested V1 behavior:

- Each gumball deals damage on enemy contact.
- It continues moving after a successful hit.
- It may hit additional enemies farther down the lane.
- The same gumball should damage any individual enemy at most once.

Maintain a per-projectile collection of enemies already hit.

Use the project's existing damage system.

Avoid frame-by-frame repeated damage when a gumball overlaps an enemy for multiple frames.

If possible, use physics queries or swept collision detection to prevent projectiles from passing through enemies between frames.

A simple collision shape is sufficient, provided movement remains reliable.

No area damage or splash damage for V1.

## 8. Firing mechanics

The machine fires automatically at a fixed interval.

It does not need to detect enemies before firing.

Suggested base configuration:

```json
{
  "id": "gumball",
  "name": "Gumball Machine",
  "cost": 130,
  "detection_range": 0.0,
  "turn_speed": 0.0,
  "attack": {
    "damage": 7,
    "cooldown": 1.5,
    "projectile_speed": 7.0,
    "bounce_height": 0.5,
    "bounce_frequency": 2.5,
    "piercing": true
  },
  "targeting": {
    "targets": ["ground"],
    "priority": "lane"
  },
  "damage_type": "physical",
  "tags": ["projectile", "lane", "bouncing", "piercing"]
}
```

Adapt this to the existing tower schema rather than assuming all properties are supported.

Do not introduce fake targeting or range values that cause existing generic tower behavior to malfunction.

Where necessary, add a small reusable directional firing behavior or an explicit alternative to enemy-targeted firing.

Avoid hardcoded special cases in generic tower scripts.

## 9. Upgrades

Add three upgrades using the existing upgrade configuration mechanism.

Suggested progression:

| Level | Upgrade cost | Damage | Cooldown | Speed |
|---|---:|---:|---:|---:|
| Base | — | 7 | 1.5 s | 7 |
| Mk2 | 40 | 10 | 1.5 s | 7 |
| Mk3 | 65 | 10 | 1.0 s | 8 |
| Mk4 | 90 | 15 | 1.0 s | 9 |

The upgrade system should modify the configured stats without changing the basic lane mechanic.

For V1, do not add multi-shot, splitting gumballs, ricochets, or explosive variants.

## 10. Integration

Integrate the tower into the existing:
- Tower selection menu.
- Placement system.
- Tower cost handling.
- Grid/path inspection.
- Projectile and damage systems.
- Upgrade UI and configuration.
- Existing audio system, if present.

The tower should coexist with the laser, lightning, tank, and water rocket towers.

Existing tower placement and targeting must continue functioning.

Prefer composing specialized lane-selection and projectile behaviors rather than introducing a large number of conditions into generic tower code.

## 11. Blender replacement compatibility

The placeholder will eventually be replaced with a Blender model.

Document:
- Expected model size and orientation.
- Position of the root origin.
- Direction pivot orientation.
- Forward axis used for firing.
- Muzzle marker position.
- Which parts are purely decorative.
- Which script or resource owns the procedural placeholder.

No firing animation should depend on individual placeholder meshes.

Replacing the model should not require rewriting projectile movement or path selection.

## 12. Testing

Add appropriate automated tests where supported, plus a practical manual testing checklist.

Verify:

- Tower can be placed next to a path.
- The longest adjacent straight path is selected.
- The preview highlights exactly the tiles along the lane.
- The arrow points in the same direction as the projectile.
- `R` cycles through available directions.
- The tower cannot be placed without an adjacent path.
- The tower does not rotate after placement.
- Gumballs travel straight regardless of enemy movement.
- Gumballs visibly bounce.
- A gumball can damage multiple enemies.
- A gumball damages the same enemy only once.
- Gumballs disappear at the lane endpoint.
- Gumballs do not follow path corners.
- Upgrades work correctly.
- Existing towers remain unaffected.

Include tests covering lanes at map boundaries, equal-length lanes, and blocked lanes.

## 13. Deliverables

Provide:

1. Gumball tower scene and GDScript.
2. Procedural placeholder model.
3. Gumball projectile scene and script.
4. Directional lane-selection logic.
5. Placement preview with highlighted tiles and arrow.
6. Tower JSON configuration and upgrades.
7. Relevant tests.
8. Short documentation explaining the design and Blender replacement process.

**Acceptance criteria:** I can select a Gumball Machine, preview the longest adjacent straight path, rotate through valid firing directions, place the tower, and watch colorful gumballs bounce along the highlighted lane, damaging multiple enemies before disappearing at the lane's end.

Keep the implementation focused on V1. Use readable, well-commented GDScript and reuse existing Godot scenes and systems wherever possible.