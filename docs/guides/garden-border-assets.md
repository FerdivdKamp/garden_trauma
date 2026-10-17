# Garden Border Assets — Blender Modeling Guide

**Project:** Garden Defense  
**Status:** In progress; straight fence sections are assembled around the current grid.  
**Goal:** Replace the flat dark-green area outside the playable level with a reusable, attractive garden border, without reducing gameplay readability.

The current prototype places the four baked stepping stones from
`assets/models/props/border/rock_stylized.glb` just outside the left and right
fence sides. `scripts/level_border_rocks.gd` reads the grid dimensions, leaves a
clear gap from the fence, and adds four plain ground strips beneath the stones.
This is a fixed layout for checking scale and color from the gameplay camera;
the seeded border variation described below is still a future step.
[View the current gameplay preview](../reference/garden_border_rocks_preview.png).

## Visual target

The camera uses a distant **35° perspective field of view** at a **55° downward pitch**. The playable tile grid stays clearly readable, while the area outside it becomes a toy-diorama garden. Use vivid fresh greens, warm wooden and terracotta materials, soft sunlight, rounded edges, and small playful details.

**Composition, from the center outward:**

1. **Playable grid:** Grass and sandy paths, relatively uncluttered.
2. **Boundary:** A low wooden fence or other obvious border identifying the edge of playable space.
3. **Non-playable garden strip:** Rocks, bushes, flowerbeds, pots and occasional tools.
4. **Outer framing:** More foliage, ground and props beyond the fence so the camera never exposes an empty dark-green void. Softly blurred foreground foliage is optional later.

> **Important:** Build individual reusable assets, **not** a single border model. Godot should be able to assemble them for different level dimensions and seeds.

## Blender conventions

- **Units:** Follow the existing project's scale. The current gameplay tiles are **2 × 2 world units**; test assets next to a reference tile.
- **Origin:** Put scatterable props' origins at ground level near their center. Use consistent snap points and dimensions for fences.
- **Ground intersection:** Let rock and plant bases sink slightly into the ground to avoid visible gaps.
- **Materials:** Reuse a small palette (wood, stone, leafy greens, terracotta, flower colors); subtle variation is preferable to noisy textures.
- **Mesh style:** Low-poly geometry with modest bevels and intentional silhouettes. Check shading/normals from the actual game camera.
- **Transforms:** Apply scale/rotation as appropriate before export; check axes, dimensions and pivots.
- **Files:** Keep source `.blend` files and export to `.glb` through the existing asset pipeline.
- **Naming:** Use stable, lower-case snake_case names such as `fence_straight_01` and `bush_02`.
- **Variations:** Rotate, scale and recolor assets programmatically where possible; model new variants only when the silhouette benefits.

## Asset checklist

### A. Structural assets

#### [ ] 1. Wooden fence kit — `fence_straight_01`, `fence_corner_01`, `fence_end_01`, `fence_post_01`
1. Start with beveled cubes for pointed vertical pickets; duplicate them at consistent spacing.
2. Add two horizontal rails behind the pickets, with a shared warm-wood material and subtle tone variation.
3. Make straight, corner, end and optional standalone-post modules; test snapping on the 2-unit tile grid.

#### [ ] 2. Large rocks — `rock_large_01` to `rock_large_03`
1. Add a low-subdivision Icosphere, scale into a squat irregular boulder.
2. Move a few vertices using proportional editing to break symmetry and flatten its base.
3. Try flat or subtly smoothed shading; use two or three muted stone tones.

#### [ ] 3. Small border stones — `rock_border_01` to `rock_border_03`
1. Start from a low-subdivision Icosphere and flatten it slightly.
2. Make round, elongated and angular silhouettes, with irregular but simple facets.
3. Place its origin at ground level and test partially burying the bottom in the lawn.

#### [ ] 4. Wooden raised planter — `planter_wood_01`
1. Build a rectangular frame from four beveled wooden boards.
2. Add a dark soil mesh just below the top lip; keep the interior unobstructed.
3. Keep flowers and leaves as separate reusable assets so Godot can vary the contents.

### B. Plants and foliage

#### [ ] 5. Bushes — `bush_01` to `bush_03`
1. Cluster three to six low-poly Icospheres into one rounded bush silhouette.
2. Vary sphere sizes and rotations to avoid an overly regular shape.
3. Use multiple fresh-green shades; create compact, broad and tall variants.

#### [ ] 6. Leafy plants — `plant_leafy_01` to `plant_leafy_03`
1. Build one elongated leaf from a plane with a few subdivisions; give it a subtle bend.
2. Duplicate leaves around a shared center, rotating and scaling each slightly.
3. Add a simple stem if visible; inspect leaf normals and backface rendering in Godot.

#### [ ] 7. Small daisies — `flower_daisy_01` to `flower_daisy_03`
1. Make a small yellow center from a sphere or disc.
2. Model one rounded petal and duplicate it radially around the center.
3. Add a thin stem and one or two leaves; make white, pink and yellow variations.

#### [ ] 8. Flower clusters — `flower_cluster_01` to `flower_cluster_03`
1. Reuse the small flower meshes rather than rebuilding them.
2. Arrange roughly five to twelve flowers at varied heights and rotations.
3. Create sparse, dense and mixed-color clusters for use around fence posts and planters.

### C. Garden props

#### [ ] 9. Terracotta pots — `pot_terracotta_01` to `pot_terracotta_03`
1. Begin with a 12–16-sided cylinder and taper its lower section.
2. Extrude/inset the top to form a visible rim and hollow opening.
3. Add a dark soil insert; create small, medium and large variants in warm terracotta.

#### [ ] 10. Watering can — `prop_watering_can_01`
1. Create a slightly tapered cylinder for the main metal body.
2. Add a handle and spout using curves with bevel depth or simple low-poly meshes.
3. Finish with a flared sprinkler head and a softly colored painted-metal material.

#### [ ] 11. Garden trowel — `prop_trowel_01`
1. Shape a flattened cube into a broad blade with a pointed tip.
2. Add a small neck and cylindrical wooden handle with bevels.
3. Lay the model at a natural resting angle; verify it reads clearly at game scale.

#### [ ] 12. Garden lantern — `prop_lantern_01`
1. Make a small square frame of beveled cubes with a pyramid-shaped roof.
2. Add simple glass panels and a warm emissive bulb material.
3. Treat the actual light source as a separate, optional Godot scene component.

## Implementation phases

### V1 — Make the boundary work

- [ ] Model one straight fence, corner, end and post module.
- [ ] Export and verify their dimensions, orientation, scale and materials in Godot.
- [ ] Generate the fence around a 20 × 20 grid; ensure it does not block entry/exit paths.
- [ ] Extend the non-playable ground beyond the fence so the camera no longer sees a flat empty background.
- [x] Test the perspective camera at 16:9 and 4:3 aspect ratios.

**Definition of done:** The garden has a coherent visible boundary, the route remains readable, and no dark-green void is exposed within normal gameplay framing.

### V2 — Add natural border variation

- [ ] Model three large rocks, three smaller stones and three bushes.
- [ ] Add procedural placement in the non-playable strip, controlled by the level seed.
- [ ] Prevent collisions or excessive overlap with the fence and with path entrances/exits.
- [ ] Use randomized rotation and modest scaling variation.
- [ ] Keep the central playfield less visually busy than the decorative border.

**Definition of done:** Two level seeds produce visibly different but consistently attractive garden borders.

### V3 — Color and garden personality

- [ ] Model flowers, flower clusters, leafy plants and terracotta pots.
- [ ] Add a raised planter whose flower contents can vary.
- [ ] Place small accents in clusters rather than distributing everything uniformly.
- [ ] Reuse the same material palette throughout the level.

**Definition of done:** The outside of the garden feels designed and alive, without becoming distracting.

### V4 — Hero props and final polish

- [ ] Model a watering can, trowel and lantern.
- [ ] Allow sparse, deliberate placement of distinctive props.
- [ ] Experiment with subtle foliage shadows and optional blurred foreground leaves.
- [ ] Profile scene draw calls and geometry before adding much more detail.
- [ ] Review HUD overlap with borders and props across supported resolutions.

**Definition of done:** The garden reads as a complete toy-diorama scene from the normal camera position.

## Suggested Godot assembly approach

- Treat the **playable tile grid** and the **decorative surroundings** as separate concerns.
- Generate straight/corner fence modules from the map outline; leave appropriate gaps at route entry and exit points.
- Generate a non-playable ground band outside the fence, with sufficient size for the camera framing.
- Place props in border zones using seeded randomness, sensible spacing and optional weighted groups (e.g. a planter surrounded by flowers).
- Keep models independent of level-specific JSON. Later, add optional per-level border themes or manually overridden prop placements.
- For quick iteration, provide a debug option to regenerate only border dressing without changing the route or towers.

## First modeling session (recommended)

Start small rather than attempting all 12 asset groups:

1. **Fence kit:** Straight, corner, end, post.
2. **Rocks:** Three noticeably different large shapes.
3. **Bushes:** Three distinctive silhouettes.
4. **Pot:** One terracotta pot with soil.

Import these, let Godot assemble a sample border, and check the composition from the normal camera. Only then build the finer flowers and garden props.
