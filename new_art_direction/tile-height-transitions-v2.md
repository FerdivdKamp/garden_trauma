# Garden Defense — V2: Raised Grass, Recessed Paths & Transitions

**Goal:** Make grass visually sit above the sandy path, using reusable geometry selected from grid neighbors. Preserve the **2 × 2 tile grid** and keep gameplay logic independent of the new visual height.

**Dependencies:** Approved V1 scene/camera/lighting, `art-direction.md`, existing tile-based level generator/designer.

## Design decisions to preserve

- Logical tiles, grid spacing and cell coordinates remain unchanged.
- Choose a single common grid reference plane: e.g. path top at `Y = 0`, grass top at `Y = +0.2`. This is **visual**, not a new gameplay layer.
- The 0.2-unit height is a starting point: test 0.15 and 0.2 in the actual gameplay camera.
- Use grid adjacency to determine visual borders. No sculpted one-off joins or hand-edited path-specific meshes.
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
  Visible transition edges provide earth/soil instead of gaps.
```

## PR V2.1 — Mesh kit / Blender prototype

Create test assets (or generate simple Godot primitives first, then replace with Blender meshes):

- [ ] `grass_center` tile with consistent 2 × 2 footprint, grass surface at target top height.
- [ ] `path_center` tile with consistent 2 × 2 footprint, sand surface at baseline height.
- [ ] `grass_to_path_edge_straight` on a 2-unit grid edge: grass top, sloped or slightly stepped exposed earth, join to path height.
- [ ] `grass_to_path_corner_inner` for a concave grass-side transition.
- [ ] `grass_to_path_corner_outer` for a convex grass-side transition.
- [ ] Optional caps/junction pieces for special neighbor combinations; decide after test cases.

**Important:** Before modeling transition mesh shapes, inspect current tiles' side walls and origin coordinates; avoid double walls and surfaces overlapping at equal height. Pick either (A) tile variants whose edges include the transition, or (B) a separate overlay/edge kit anchored to tile boundaries. **Prefer B for an initial prototype if it avoids replacing current tiles**, but switch if seams/overlap become hard to control.

Blender guidance:

- Model in meters/world units compatible with the existing glTF pipeline; apply transforms before export.
- Align origin and axes with current exported tiles.
- Give earth edges their own warm-brown material or compatible material slot.
- Avoid microscopic bevels or overlapping coplanar surfaces; inspect normal directions.
- Use clean readable names, e.g. `GrassEdge_Straight_2m`, `GrassEdge_InnerCorner_2m`.

**Acceptance:** A hand-assembled 3 × 3 arrangement (grass, path, bend) has no black cracks or z-fighting when viewed at normal play zoom.

## PR V2.2 — Neighbor-aware transition generation

- [ ] Use existing map grid/cell type information to determine cardinal neighbors (N/E/S/W) of each grass cell.
- [ ] Build a **4-bit mask** for sides touching a path (N=1, E=2, S=4, W=8; document your chosen mapping).
- [ ] Map masks/rotation to the smallest transition mesh set. Include diagonal information only when required to resolve a corner correctly.
- [ ] Instantiate visual transitions on the correct cell borders, rotated/translated to the existing tile basis.
- [ ] Place each shared edge **once**. Make ownership clear to avoid duplicate pieces.
- [ ] Handle map perimeter/void tiles explicitly (border geometry is not necessarily a path transition).
- [ ] Seed optional appearance variations deterministically; geometry correctness must not depend on random seed.

**Acceptance:** Straight paths, 90° bends, narrow corridors, isolated grass patches and path intersections render correctly regardless of tile reroll.

## PR V2.3 — Gameplay integration and dressing placement

- [ ] Tower placement/selection uses existing logical tile data; compensate visual tower foundation Y or surface attachment so no floating/sunken bases.
- [ ] Enemy feet match the path surface Y without altering route semantics or collision unexpectedly.
- [ ] Grass tufts and pebbles spawn against the correct visual surface height for their cell.
- [ ] Prevent dressing on transitions where it would intersect the exposed soil edge or obscure path readability.
- [ ] Ensure tower placement highlight/range visualization appears above grass, not inside the raised surface.
- [ ] Rebuild/redraw transitions when a level-designer tile change actually modifies neighbors; do not require full map reload if unnecessary.
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

> Implement **Garden Defense V2.1**, following `tile-height-transitions-v2.md` and `art-direction.md`. Inspect the current 2 × 2 tile meshes, origins, scene instancing and glTF import convention. Build a minimal, reusable prototype for grass top Y≈+0.2, path Y=0, and straight/corner exposed-soil joins. Demonstrate a 3 × 3 grass/path/bend test scene without changing logical grid, navigation, placement or level serialization. Prefer small incremental assets, readable names and detailed implementation notes. Stop after V2.1 and provide screenshots so we can review before automating the neighbor logic.
