# Implement Lava Lamp Tower — Garden Defense

Implement a new **Lava Lamp Tower** in our Godot 4 tower-defense game, following the existing tower architecture, configuration conventions, placement system, targeting logic, and visual style.

The tower is inspired by a retro lava lamp. It slowly builds pressure before spitting a blob of hot lava from its top onto a path tile. The lava spreads into a persistent puddle that damages enemies walking through it.

This is a **persistent area-denial tower**, rather than a conventional projectile damage tower.

## 1. Gameplay mechanics

### Attack behavior
- The tower targets a valid path tile within its attack range.
- It launches a large glowing lava blob from the opening at the top of the lamp.
- The projectile follows a visible arcing trajectory, influenced by its destination.
- On impact, the blob splashes and spreads across the target tile, creating a lava puddle.
- The puddle remains active **until the end of the current enemy wave**.
- Enemies walking through the puddle take damage over time.
- The tower has a relatively slow firing rate to balance the persistent effect.
- The tower cannot target tiles outside its attack range.
- It should only target tiles that enemies can traverse, not grass, blocked tiles, or tower placements.

### Initial balancing values

Use the existing JSON configuration structure and conventions, adapting these suggested values:

| Property | Initial value |
|---|---|
| Cost | 180 |
| Attack range | 5 tiles |
| Cooldown | 8 seconds |
| Direct impact damage | 5 |
| Lava damage | 4 per second |
| Puddle duration | Until wave ends |
| Puddle radius | Approximately 0.45 tile widths |
| Projectile travel time | Approximately 0.7–1.1 seconds |
| Targets | Ground enemies |

These are starting values for balancing, not fixed design constraints. Keep them configurable.

## 2. Target selection

Unlike towers that prioritize an individual enemy, this tower should primarily target **path tiles**.

Implement a targeting strategy that:

1. Finds enemies within the tower's valid range.
2. Identifies the path tiles occupied by those enemies or that they are approaching.
3. Prioritizes uncovered tiles where a puddle is likely to affect multiple enemies.
4. Avoids repeatedly attacking tiles that already contain active lava.
5. Selects a tile and launches the projectile toward its center.

If the existing targeting architecture doesn't support tile-based targeting, extend it cleanly rather than implementing an unrelated targeting system.

The initial version can use a simple heuristic: prefer the nearest valid path tile containing an enemy that does not already have lava.

Do not make the tower fire at empty tiles unless there is a good reason within the targeting implementation.

## 3. Persistent lava puddles

Implement a reusable puddle effect.

### Behavior
- Each puddle belongs to a particular path tile.
- It starts dealing damage when the projectile lands.
- It lasts until the wave ends, regardless of when it was created.
- It damages every eligible enemy occupying or crossing its damage area.
- Damage is based on elapsed time, not rendering frame rate.
- Multiple enemies can take damage simultaneously.
- Enemies should not receive duplicate damage merely because they have multiple collision shapes.
- Puddles must not obstruct enemy movement or change pathfinding.
- Clean up all puddles when the wave ends, including any final victory or failure cleanup.
- Handle enemies dying while standing in a puddle safely.

Avoid per-enemy timers when the existing damage system can handle periodic damage centrally.

For now, prevent stacking multiple puddles on the same tile. A future upgrade might allow stronger or larger puddles.

### Wave integration

Use existing wave lifecycle events to identify when to clear puddles.

Avoid building a separate wave manager or relying on arbitrary timers.

Clarify in the implementation how the game handles a projectile still in flight when the wave ends. Prefer safely cancelling it and preventing the creation of a new puddle after cleanup.

## 4. Placeholder 3D model

Create a procedural placeholder model in Godot that resembles a classic retro lava lamp.

Use primitive meshes and materials that can later be replaced with a proper Blender model.

### Shape and components
- Wide, rounded metallic base.
- Tall tapered glass chamber with a recognizable lava lamp silhouette.
- Bright colored liquid visible inside the glass.
- Several large, irregular lava blobs suspended inside the chamber.
- Metallic cap at the top.
- Small nozzle or opening from which lava is launched.

### Visual direction
- Stylized, playful 1980s/1990s toy aesthetic.
- Saturated orange-red lava.
- Warm yellow highlights.
- Purple, red, or teal lamp housing.
- Glossy plastic or painted metal materials.
- Soft emissive glow inside the lamp.
- Low-poly geometry with smooth shading where appropriate.

Keep the silhouette readable from our existing orthographic camera angle.

Do not rely on expensive transparency or volumetric effects. Use a simple combination of transparent materials, opaque geometry and emission where appropriate.

### Model hierarchy

Create a sensible node hierarchy with named attachment points, especially:

- `TowerRoot`
- `VisualRoot`
- `Base`
- `GlassChamber`
- `LavaContents`
- `TopCap`
- `Muzzle`

The muzzle should indicate the projectile's launch position. Keep the model and gameplay logic independent so the placeholder can later be replaced by an imported GLB.

Follow existing conventions for the tower's pivot and visual orientation.

## 5. Firing animation

Give the placeholder tower a short, expressive firing animation:

1. The lava blobs inside the lamp rise and swell.
2. The chamber's emissive glow intensifies.
3. The top cap lifts slightly as pressure builds.
4. A large lava blob shoots upward through the opening.
5. The cap settles with a small bounce.
6. The internal lava returns to its normal slow movement.

The animation should be exaggerated enough to read from a distance but remain consistent with our toy-like art direction.

Use `AnimationPlayer`, procedural animation, tweens or a combination that fits the current architecture.

The chamber should also have subtle ambient blob movement when idle.

The firing animation must not block tower logic or introduce timing inconsistencies.

## 6. Projectile

Create a stylized lava projectile:

- Glowing, slightly irregular spherical blob.
- Arcing trajectory between the muzzle and selected tile.
- Orange/yellow emissive appearance.
- Small trailing droplets or sparks.
- Slight stretching along its flight direction.
- Splash or squash animation upon landing.

The projectile should travel to the selected tile's position, rather than homing toward an individual enemy.

Separate its visual effects from gameplay damage.

## 7. Lava puddle visuals

On impact, create a stylized, molten puddle that spreads across most of a single path tile.

Visual characteristics:
- Irregular rounded outline.
- Dark red outer crust.
- Bright orange molten interior.
- Yellow hot spots.
- Slow animated surface movement.
- Occasional small bubbles.
- Gentle emissive glow.
- Optional tiny heat wisps or rising sparks.

Prefer a lightweight shader or animated mesh over expensive particle systems.

Make sure the puddle:
- Conforms visually to the path tile.
- Does not clip significantly into the tile surface.
- Does not obscure enemies.
- Remains clearly distinguishable from the warm sandy path.
- Is visible from our orthographic camera.

At the end of the wave, play a short cooling animation: lava darkens, loses its emission, and disappears.

The visual puddle and the damage area should correspond reasonably well.

## 8. Placement preview and range visualization

Integrate the tower with the existing placement system.

- Show the existing tower range indicator.
- Use the same placement validity rules as other towers.
- Make it clear that the tower targets path tiles within range.
- Retain the same selection, upgrade, selling and interaction behavior as other towers.

Do not create a separate placement framework.

## 9. Configuration and future upgrades

Keep the following properties configurable:

- Tower cost.
- Attack range.
- Attack cooldown.
- Impact damage.
- Damage per second.
- Puddle coverage radius.
- Projectile speed or travel duration.
- Maximum active puddles, if needed.
- Targeting strategy.

Leave room for three future upgrade levels.

Possible upgrade directions (do not implement these unless required by the existing tower upgrade system):

- **Hotter Lava:** Increased damage per second.
- **Bigger Splash:** Larger puddle coverage, potentially affecting adjacent tiles.
- **Volcanic Eruption:** Occasionally fires multiple blobs onto nearby path tiles.

For now, keep the initial implementation simple and consistent with the game's current upgrade architecture.

## 10. Architecture and quality requirements

Before implementing, inspect the existing tower implementations, particularly the laser, lightning, rocket and gumball towers.

Reuse:
- Tower configuration and factories.
- Target detection.
- Damage application.
- Projectile lifecycle.
- Wave lifecycle signals.
- Range visualization.
- Existing scene organization.
- Upgrade and selection mechanics.

Avoid unnecessary duplication or major refactoring.

Use typed GDScript where practical.

Handle scene deletion, wave transitions, tower selling, and enemy removal safely.

### Tests / verification

Verify that:

1. The tower can be placed and selected normally.
2. It only targets valid path tiles within range.
3. Its projectile travels to the selected tile.
4. Impact creates exactly one puddle.
5. Enemies crossing the puddle receive damage over time.
6. Multiple enemies can be damaged by one puddle.
7. Damage remains independent of frame rate.
8. An already-covered tile is not needlessly targeted again.
9. Puddles remain active throughout the wave.
10. Puddles disappear when the wave ends.
11. Selling the tower does not accidentally break existing puddles.
12. No puddles or projectiles remain after restarting or leaving a level.

**Important:** Once deployed, a puddle should remain active for the wave even if its originating tower is sold, unless existing game architecture explicitly requires otherwise.

## 11. Deliverables

- Functional Lava Lamp Tower integrated into the game.
- Procedural placeholder model.
- Firing and idle animations.
- Lava projectile with arc and splash.
- Persistent tile-based damage puddles.
- Wave-end cleanup and cooling animation.
- JSON tower configuration.
- Integration with existing placement, selection and upgrade systems.
- Tests or appropriate verification steps.
- Brief documentation describing the implementation, configuration and any architectural decisions.

Work within the current project's conventions. Inspect existing code first and adapt the implementation accordingly rather than assuming new systems are required.