# Garden Defense — V2: Raised Grass, Recessed Paths & Transitions

**Goal:** Make grass visually sit above the sandy path while keeping every logical **2 × 2 tile** at full size. Soften the grass/path boundary with a narrow visual treatment that slightly covers or cuts into the path, rather than inserting transition tiles. Keep gameplay logic independent of the new visual height.

**Dependencies:** Approved V1 scene/camera/lighting, `art-direction.md`, existing tile-based level generator/designer.

## Design decisions to preserve

- Logical tiles, grid spacing and cell coordinates remain unchanged.
- Choose a single common grid reference plane: e.g. path top at `Y = 0`, grass top at `Y = +0.2`. This is **visual**, not a new gameplay layer.
- The 0.2-unit height is a starting point: test 0.15 and 0.2 in the actual gameplay camera.
- Use grid adjacency to determine which borders need treatment. No extra logical tile types or replacement grass/path transition tiles.
- Keep the grass **surface** flat enough for reliable tower placement, even if nearby dressing adds local depth.
- Path height changes must not alter the existing enemy route positions unexpectedly.

## Target geometry (cross-section)

```text
             GRASS TOP                  GRASS TOP
              y=+0.2                     y=+0.2
    ____________                              ____________
                \                            /
                 \________ PATH ____________/
                            y=0

  Shared logical grid Y reference remains unchanged.
  A narrow irregular verge hides the hard join; the path remains a full logical cell.
```

## Edge approaches to prototype

These approaches can share the same neighbor check later. They differ in where the irregular silhouette comes from. Keep the visible intrusion into sand small (start around 0.05–0.15 m on a 2 m cell), and inspect it at the normal gameplay camera distance before committing to a width. The path must remain easy to read, especially when it is only one cell wide.

| Approach | How to make it | Main tradeoff |
|---|---|---|
| **A. Grass lip over the path** | Keep the current grass and path meshes. Add a thin, irregular top strip attached to the grass edge, projecting a little across the border and stepping down toward sand. Give it an underside/soil face where the raised grass would otherwise reveal a gap. Use a straight strip plus a small corner join, rotated as needed. | Fastest reversible geometry prototype. The strip can look pasted on if its color, normals, or thickness differ from the grass. |
| **B. Nibble the path edge** | Keep the full logical path cell but alter its *visible* top surface along grass-facing sides: model a shallow scalloped/eroded cut in a path-top mesh, or mask the path material near those sides. Reveal soil beneath, then let a few grass tufts cross the cut. | Gives real negative space and a worn edge, but a mesh cut needs enough vertices and side/corner combinations. A material mask needs a deliberate depth/soil treatment; transparency alone can reveal an empty gap. |
| **C. Blades across the verge, or all over** | Keep both base tiles. Scatter small grass clumps or crossed blade cards across grass cells, increasing density near the boundary and allowing a low-density spill into the path. A cheaper first pass puts blades only along grass-facing borders. Use a seeded placement rule and an authored blade/clump mesh; batch repeated instances with `MultiMeshInstance3D` if counts justify it. | Best natural breakup and easy variation. Individual blades alone do not hide a hard geometric seam or exposed vertical face; start with a simple soil/lip base. Full coverage needs many instances, distance-based density or LOD, and checks for unit visibility and path readability. |

The likely first test is **A with sparse C**: a narrow grass/soil lip establishes the height join, while a few blades break its silhouette. Compare a small B sample if the lip looks too artificial. These are visual edge pieces or surface edits, not cells occupying grid space.

The runnable [A with sparse C visual study](../examples/grass_path_lip.md) shows matched before/after renders from a fixed 5 × 5 layout. It is isolated from the playable level while the edge shape is being reviewed.

### Where dual-grid tiles fit

[TileMapDual](https://github.com/pablogila/TileMapDual) is a **2D `TileMapLayer` plugin**. Its useful idea here is to derive display pieces from neighboring logical terrain cells, especially at corners, while keeping gameplay cells separate. Our current tiles are 3D `Node3D` scenes with GLB meshes, so that plugin cannot place or shade these meshes directly. For this prototype, a grass/path adjacency check creates narrow edge strips. If the corners need more rounded shapes later, a second visual grid shifted by half a cell could select corner caps from the four surrounding terrain cells, in the same spirit as dual-grid autotiling. This would still be visual data generated from the existing level map; path routing and tower placement would continue to use the original 2 m cells.

### Matching the current grass material

The imported grass top currently uses `shaders/procedural_noise_color_ramp.gdshader`: its color comes from `assets/textures/environment/garden/grass_color_noise.png` at `world_position.xz / 64.0 + 0.5`. `tools/godot_material_post_import.gd` enables this only for files named `tile_grass*.glb`; dressing imports do **not** inherit it automatically. For a new lip mesh, explicitly assign or create a material with the same shader, grass colors, `grass_world_variation`, noise texture, span, and strength. If it is exported as a separate GLB, extend the import setup deliberately instead of assuming its filename will trigger grass settings. World X/Z sampling makes the broad color continue over rotated tiles and the lip. Match roughness and lighting too; the shared color field alone will not remove a silhouette or shading seam. A blade clump may use the same world field for its base tint, with small blade-to-blade variation added on top.

### Height and overlap rules

- First inspect the current meshes and their `-0.25` visual offsets in `scenes/tiles/tile_grass.tscn` and `scenes/tiles/tile_path.tscn`. The top of the imported meshes is not implied by the scene root's Y position. Measure the actual rendered tops before choosing offsets.
- An overlay should meet the grass top, project only slightly over the path, and descend to the sand/soil edge. Avoid coplanar overlap with either top, which causes z-fighting. Keep it visual only unless collision proves necessary.
- If nibbling geometry, retain the path's logical footprint and route centers. Make the cut depend on adjacent grass sides, with a consistent join at corners; avoid manually editing every path tile variant.
- Do not let random blade placement determine whether a gap is covered. The base edge must look acceptable with blades disabled.

## PR V2.1 — Small edge prototype

Create a hand-assembled 3 × 3 test scene containing a straight edge and a bend. Simple Godot geometry is fine before modeling in Blender:

- [ ] Keep the existing grass and path cells; prototype the intended grass top and path top heights without changing grid coordinates.
- [ ] Build one narrow irregular lip/soil edge and one corner join as separate visual geometry. Include a few optional grass blades that cross onto the sand.
- [ ] Make one small path-edge nibble sample for side-by-side comparison if the lip needs evaluation against real cut geometry.
- [ ] Verify a lip material against the existing grass tiles in world coordinates, including rotated tile variants.
- [ ] Capture the normal gameplay camera, a low close view, and a blades-disabled view. Choose an approach after seeing all three.

**Important:** Inspect existing side walls and origins before modeling. Avoid double walls, visible empty cuts, and coplanar surfaces. Do not replace an entire 2 × 2 tile with a special transition tile.

Blender guidance:

- Model in meters/world units compatible with the existing glTF pipeline; apply transforms before export.
- Align origin and axes with current exported tiles.
- Give exposed earth its own warm-brown material or compatible material slot; apply the shared grass shader only to grass surfaces.
- Avoid microscopic bevels or overlapping coplanar surfaces; inspect normal directions.
- Use clean readable names, e.g. `GrassLip_Straight_2m`, `GrassLip_Corner_2m`, `GrassVergeClump`.

**Acceptance:** A hand-assembled 3 × 3 arrangement (grass, path, bend) has no black cracks or z-fighting, still reads as a full-width path, and has no obvious color break between the grass top and lip at normal play zoom.

## PR V2.2 — Neighbor-aware edge generation

- [ ] Use existing map grid/cell type information to determine cardinal neighbors (N/E/S/W) of each grass cell, or path cell if approach B is chosen.
- [ ] Build a **4-bit mask** for grass sides touching path (N=1, E=2, S=4, W=8; document your chosen mapping). If path cells own the nibble, use path sides touching grass with the same bit order.
- [ ] Map masks/rotation to the smallest edge treatments and corner joins. Include diagonal information only when required to resolve a corner correctly.
- [ ] Instantiate visual edges on the correct cell borders, rotated/translated to the existing tile basis.
- [ ] Place each shared edge **once**. Let the grass cell own lip and blades, or the path cell own nibble geometry, and document that choice.
- [ ] Handle map perimeter/void tiles explicitly (border geometry is not necessarily a path transition).
- [ ] Seed optional appearance variations deterministically; geometry correctness must not depend on random seed.

**Acceptance:** Straight paths, 90° bends, narrow corridors, isolated grass patches and path intersections render correctly regardless of tile reroll.

## PR V2.3 — Gameplay integration and dressing placement

- [ ] Tower placement/selection uses existing logical tile data; compensate visual tower foundation Y or surface attachment so no floating/sunken bases.
- [ ] Enemy feet match the path surface Y without altering route semantics or collision unexpectedly.
- [ ] Grass tufts and pebbles spawn against the correct visual surface height for their cell.
- [ ] Prevent dressing on transitions where it would intersect the exposed soil edge or obscure path readability.
- [ ] Ensure tower placement highlight/range visualization appears above grass, not inside the raised surface.
- [ ] Rebuild/redraw affected edges when a level-designer tile change actually modifies neighbors; do not require full map reload if unnecessary.
- [ ] If any physics meshes exist, decide whether visible transition geometry needs collision. Avoid collidable decorative edges interfering with gameplay picking.

**Acceptance:** Existing game mechanics still pass; gameplay and editor views agree about surface height.

## PR V2.4 — Edge polish / variants

- [ ] Tune soil edge to look gently worn, not like a deep ditch or artificial retaining wall.
- [ ] Add two or three low-cost edge variants (subtle grass overhangs, occasional pebbles, fine soil shapes).
- [ ] Make variants connect without noticeable seams.
- [ ] Add optional small edge dressing with safe density limits and reroll support.
- [ ] Test normals, shadows, color and smoothing from multiple camera positions.
- [ ] Verify performance does not regress badly; consider MultiMesh for repeated dressing if counts warrant it.

## Explicit test matrix

| Shape / situation | Expected |
|---|---|
| Long straight | Continuous edge, no seams |
| L bend | Corners join smoothly |
| T or crossroads | All adjoining edge conditions resolve |
| One-tile grass island | No overlapping corner geometry |
| Narrow one-cell path | Both sides remain readable |
| Grid boundary | No missing caps or accidental path edges |
| Different tile variants | No height/material discontinuity |
| Tile reroll | Visual variation changes, joins still correct |
| Tower near edge | Base planted, no clipping |
| Enemies at bend | Feet align to sand, movement unaffected |
| Tablet/gameplay zoom | Edge remains subtle and clear |

## Delivery and learning requirements

For each PR:

- Include code comments describing **logical grid vs visual surface** separation.
- Include a small diagram or table of neighbor mask → rotation/piece.
- Provide screenshots of straight, bend and intersection cases.
- Note exactly what must be edited in Blender versus Godot when adding new mesh variants.
- Avoid modifying original generated tiles in place if that will invalidate existing project assets.

### Ready-to-paste agent prompt

> Implement **Garden Defense V2.1**, following `tile-height-transitions-v2.md` and `art-direction.md`. Inspect the current 2 × 2 tile meshes, actual rendered top heights, origins, scene offsets, and glTF import convention. Keep full-size grass and path cells. Build a minimal hand-assembled prototype with a narrow grass/soil lip that slightly overlaps the path, a corner join, and optional sparse blades; make a small path-nibble comparison if useful. Match the lip grass color with the existing world-space shader. Demonstrate a 3 × 3 straight/bend test scene without changing logical grid, navigation, placement or level serialization. Stop after V2.1 and provide normal-camera, close, and blades-disabled screenshots so the edge approach can be reviewed before neighbor automation.
