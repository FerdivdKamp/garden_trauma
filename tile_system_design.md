# Tile System Design & Implementation Plan

## Purpose

This document defines the first implementation of the tile-based level system for the tower defense game.

The main goals are:

- Keep level creation fast and repeatable for a solo developer working with coding agents.
- Separate **gameplay logic** from **visual dressing**.
- Make placeholder assets acceptable and useful.
- Keep dimensions and conventions simple and based on round numbers.
- Make it easy to replace placeholder assets later without changing gameplay logic.
- Make the system suitable for multiple themed areas such as:
  - Garden
  - Sandpit
  - Shed
  - Bedroom
  - Attic
- Allow agents to implement the work in small, reviewable pull requests.

The core design principle is:

> **Gameplay uses a grid. Visuals are allowed to break the grid.**

A tile has a logical location and known dimensions, but decorative meshes, grass tufts, stones, toys, flowers, path-edge details, and similar visual elements do not need to align rigidly to the grid.

---

# High-Level Design

## Coordinate system

Use simple round dimensions wherever possible.

Initial recommendation:

- **Tile width:** 2.0 m
- **Tile depth:** 2.0 m
- **Base tile thickness:** 0.2 m
- **Default grid:** 20 × 20 tiles
- **Default level footprint:** 40 m × 40 m
- **Ground top surface:** Y = 0
- **Tile origin:** centered on the tile footprint
- **Gameplay position:** tile coordinate `(x, z)`

These values should be constants/configuration values rather than scattered magic numbers.

Example:

```gdscript
const TILE_SIZE := 2.0
const TILE_HEIGHT := 0.2
```

A 20 × 20 grid is intentionally modest. It is large enough for early tower-defense layouts while still being easy to visualize and debug.

The design should allow larger maps later without requiring a rewrite.

---

# Tile Responsibilities

A logical tile describes gameplay state.

Example fields:

```text
grid_position
terrain_type
buildable
walkable
movement_cost
height_level
route_id
spawn_id
objective_id
special_rule
```

Not every field needs to exist in V1.

The tile should **not** own decorative details such as:

- individual grass blades
- flowers
- stones
- leaves
- toys
- decals
- small terrain imperfections

Those belong to visual dressing.

---

# Suggested Terrain Types

V1 should begin with a very small vocabulary.

```text
grass
path_sand
blocked
```

Later versions may add:

```text
dirt
stone
mud
water
flowerbed
wood
indoor_floor
carpet
```

Each terrain type should have a human-readable name and machine-readable ID.

Example:

```json
{
  "id": "grass",
  "display_name": "Grass",
  "buildable": true,
  "walkable": false
}
```

---

# Placeholder Asset Philosophy

Placeholder assets are explicitly allowed.

They should be:

- obvious
- correctly scaled
- consistently named
- visually distinct
- easy to replace
- simple enough that an agent can create them safely

A placeholder does **not** need to look polished.

However, it should communicate what the final asset is supposed to represent.

Examples:

```text
tile_grass_placeholder.glb
tile_path_sand_placeholder.glb
tile_blocked_placeholder.glb
scatter_grass_tuft_placeholder.glb
prop_garden_rock_placeholder.glb
```

The placeholder should ideally use:

- a simple material
- a recognisable shape
- no unnecessary topology
- correct origin
- correct dimensions
- applied transforms before export

Avoid placeholder names such as:

```text
cube1.glb
mesh2.glb
test.glb
new_tile.glb
```

The file and scene name should clearly reveal what will eventually replace it.

---

# Folder Structure

Suggested structure:

```text
game/
  levels/
    data/
    scenes/
    themes/

  tiles/
    core/
    terrain/
      grass/
      path_sand/
      blocked/
    transitions/
    scatter/
    props/

  tools/
    tile_system/
```

Blender source assets:

```text
art/
  blender/
    tile_templates/
    terrain/
    scatter/
    props/
```

Exported assets:

```text
game/
  assets/
    environment/
      garden/
      sandpit/
      shed/
```

The exact project root names may be adapted to the existing repository.

---

# V1 — Functional Grid

## Goal

Create the smallest useful version of the tile system.

V1 is successful when a developer can define a level as data, load it in Godot, see a visible tile grid, identify buildable/non-buildable terrain, and have a path for enemies.

The visual result may be crude.

## Scope

### Grid

- [ ] Add one central `TILE_SIZE` constant.
- [ ] Default tile size is `2.0`.
- [ ] Add grid coordinate ↔ world coordinate conversion.
- [ ] Grid positions use integer coordinates.
- [ ] Add a basic grid container/node.
- [ ] Allow configurable grid width and height.
- [ ] Test with a 20 × 20 map.

Expected conversion:

```text
grid (0, 0) -> world (0, 0)
grid (1, 0) -> world (2, 0)
grid (0, 1) -> world (0, 2)
```

Exact centering policy may differ, but it must be consistent and documented.

### Level data

- [ ] Define a simple level-data format.
- [ ] Support width and height.
- [ ] Support terrain type per tile.
- [ ] Support one enemy spawn.
- [ ] Support one objective.
- [ ] Support one route.
- [ ] Keep the format readable in Git diffs.
- [ ] Add one example level.

Example conceptual structure:

```json
{
  "name": "garden_test_01",
  "width": 20,
  "height": 20,
  "tiles": [],
  "routes": [],
  "spawns": [],
  "objectives": []
}
```

Do not prematurely optimize the format.

### Terrain

V1 terrain types:

- [ ] `grass`
- [ ] `path_sand`
- [ ] `blocked`

Rules:

- `grass`: buildable
- `path_sand`: enemy path / not buildable
- `blocked`: neither buildable nor walkable

### Placeholder visual assets

Create obvious placeholder assets:

- [ ] `tile_grass_placeholder`
- [ ] `tile_path_sand_placeholder`
- [ ] `tile_blocked_placeholder`

Recommended placeholder appearance:

- grass: flat green-ish ground tile plus 2–4 simple grass cards
- sand path: flat tile with visibly different material and slightly uneven top
- blocked: raised simple shape, rock, hedge, or neutral obstacle

Do not spend time making these polished.

### Path

- [ ] Route can be defined using tile coordinates.
- [ ] Route can be visualized in debug mode.
- [ ] Enemy can traverse the route.
- [ ] Route ordering is explicit.
- [ ] Validate that consecutive route points are adjacent or otherwise supported.
- [ ] Invalid route data should produce a clear error.

### Debugging

- [ ] Add optional visible grid overlay.
- [ ] Add optional coordinate labels.
- [ ] Add debug colors/indicators for buildable/path/blocked.
- [ ] Add a simple way to print tile information under the cursor.
- [ ] Debug visuals can be disabled for normal gameplay.

### V1 completion criteria

- [ ] Level loads from data.
- [ ] 20 × 20 example level renders.
- [ ] Tile scale is correct.
- [ ] Grass, path, and blocked cells are visually distinguishable.
- [ ] Spawn and goal are visible.
- [ ] Enemy can travel from spawn to goal.
- [ ] Tower placement can query whether a tile is buildable.
- [ ] No level-specific hardcoding is required.

---

# V1.1 — Blender Tile Bootstrap Script

## Goal

Provide a Blender Python script that generates correctly sized starting meshes.

The script is not intended to create finished assets.

It should create clean, named, dimensionally correct source objects that can be modified manually and exported to Godot.

## Script location

Suggested:

```text
art/blender/tile_templates/create_tile_templates.py
```

## Script requirements

- [ ] Use Blender's `bpy`.
- [ ] Define dimensions at the top of the file.
- [ ] Use round default values.
- [ ] Create a 2.0 m × 2.0 m tile.
- [ ] Tile thickness is 0.2 m.
- [ ] Top surface should sit at Y/Z convention appropriate to Blender/Godot export.
- [ ] Apply transforms.
- [ ] Set predictable origins.
- [ ] Use clear object names.
- [ ] Create separate starter objects for grass, sand path, and blocked terrain.
- [ ] Create a collection called `TileTemplates`.
- [ ] Save no external dependencies.
- [ ] Do not automatically overwrite existing `.blend` files.

Recommended script constants:

```python
TILE_SIZE = 2.0
TILE_THICKNESS = 0.2
GRASS_CARD_HEIGHT = 0.5
GRASS_CARD_WIDTH = 0.25
```

## Suggested generated objects

```text
Tile_Grass_Base
Tile_Path_Sand_Base
Tile_Blocked_Base
Grass_Tuft_Placeholder
```

## Grass placeholder

The grass placeholder may use simple crossed planes/cards.

Suggested:

- 2 crossed planes
- about 0.5 m high
- about 0.25 m wide
- positioned on the grass tile
- no complex geometry

The ground should still provide the primary visual surface.

Grass cards are decorative, not the terrain itself.

## Sand placeholder

The sand path starter should:

- use the same 2.0 m footprint
- begin as a simple cube or plane with thickness
- optionally include very small geometric variation
- remain tileable at its edges
- avoid edge deformation that prevents clean alignment

## Blocked placeholder

The blocked tile may simply include:

- the standard ground base
- one large raised cube/rock-like placeholder

The purpose is to communicate:

> Something occupies this tile and towers cannot be placed here.

## Expected export workflow

```text
1. Run script in Blender.
2. Select the desired generated object.
3. Modify the placeholder if desired.
4. Apply transforms.
5. Ensure origin/pivot remains correct.
6. Export selected asset as glTF/GLB.
7. Place `.glb` in the agreed Godot asset folder.
8. Wrap imported GLB in a Godot scene if gameplay-specific nodes are required.
```

## Blender script starter

```python
import bpy

TILE_SIZE = 2.0
TILE_THICKNESS = 0.2

GRASS_CARD_WIDTH = 0.25
GRASS_CARD_HEIGHT = 0.5


def clear_selection():
    bpy.ops.object.select_all(action="DESELECT")


def get_or_create_collection(name: str):
    collection = bpy.data.collections.get(name)

    if collection is None:
        collection = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(collection)

    return collection


def move_to_collection(obj, collection):
    for existing_collection in list(obj.users_collection):
        existing_collection.objects.unlink(obj)

    collection.objects.link(obj)


def create_tile_base(name: str, collection):
    bpy.ops.mesh.primitive_cube_add(
        size=1.0,
        location=(0.0, 0.0, -TILE_THICKNESS / 2.0),
    )

    obj = bpy.context.object
    obj.name = name

    obj.dimensions = (
        TILE_SIZE,
        TILE_SIZE,
        TILE_THICKNESS,
    )

    bpy.ops.object.transform_apply(
        location=False,
        rotation=False,
        scale=True,
    )

    move_to_collection(obj, collection)

    return obj


def create_grass_card(name: str, rotation_z: float, collection):
    bpy.ops.mesh.primitive_plane_add(
        size=1.0,
        location=(0.0, 0.0, GRASS_CARD_HEIGHT / 2.0),
        rotation=(1.5708, 0.0, rotation_z),
    )

    obj = bpy.context.object
    obj.name = name

    obj.dimensions = (
        GRASS_CARD_WIDTH,
        GRASS_CARD_HEIGHT,
        1.0,
    )

    bpy.ops.object.transform_apply(
        location=False,
        rotation=False,
        scale=True,
    )

    move_to_collection(obj, collection)

    return obj


def main():
    collection = get_or_create_collection("TileTemplates")

    create_tile_base(
        "Tile_Grass_Base",
        collection,
    )

    create_tile_base(
        "Tile_Path_Sand_Base",
        collection,
    )

    create_tile_base(
        "Tile_Blocked_Base",
        collection,
    )

    create_grass_card(
        "Grass_Tuft_Placeholder_A",
        0.0,
        collection,
    )

    create_grass_card(
        "Grass_Tuft_Placeholder_B",
        0.785398,
        collection,
    )

    clear_selection()


if __name__ == "__main__":
    main()
```

The agent implementing this must test the Blender script rather than assuming it works.

If Blender-axis conventions or plane orientation need adjustment, fix them and document the final convention.

---

# V2 — Visual Quality & Tile Variation

## Goal

Keep the logical grid from V1 but make levels look less obviously tiled.

The tile system must remain data-driven.

## Terrain variants

Add visual variants without changing gameplay type.

Example:

```text
grass_a
grass_b
grass_c

path_sand_a
path_sand_b
path_sand_c
```

All grass variants still resolve logically to:

```text
terrain_type = grass
```

Tasks:

- [ ] Allow multiple visual variants per terrain type.
- [ ] Pick variants deterministically from map seed + tile coordinate.
- [ ] Avoid random appearance changing every run.
- [ ] Allow manual override per tile.
- [ ] Add at least 3 grass variants.
- [ ] Add at least 3 sand variants.

---

# V2.1 — Scatter System

Decorative assets should hide repetition.

Examples:

```text
grass tufts
flowers
small stones
leaves
twigs
toy debris
```

Tasks:

- [ ] Add scatter points independent of logical tile state.
- [ ] Allow theme-specific scatter sets.
- [ ] Support deterministic random placement.
- [ ] Support density control.
- [ ] Prevent scatter on enemy path where readability would suffer.
- [ ] Prevent scatter inside tower footprint.
- [ ] Allow manual exclusion zones.
- [ ] Keep scatter decorative by default.

Recommended visual rule:

> Terrain communicates gameplay. Scatter communicates atmosphere.

---

# V2.2 — Path Edge Improvement

Goal:

Reduce the appearance of square path tiles.

Possible implementation options:

1. edge/corner transition meshes
2. decals
3. shader blending
4. spline/strip mesh

Do not implement all approaches immediately.

First create a small technical spike.

Tasks:

- [ ] Compare edge meshes vs shader blending vs spline path.
- [ ] Build one small test scene.
- [ ] Document performance and complexity.
- [ ] Pick one approach.
- [ ] Keep logical path coordinates unchanged.
- [ ] Ensure gameplay path remains debuggable.

Preferred direction:

> Logical route stays tile-based while rendering may be smoothed independently.

---

# V2.3 — Theme System

Introduce the concept of environment themes.

Example:

```text
garden
sandpit
shed
```

A theme maps logical terrain to visuals.

Example:

```text
grass -> garden grass tile
blocked -> hedge / flower bed / garden toy

sandpit:
grass -> surrounding lawn or compact sand
blocked -> bucket / castle / toy obstacle

shed:
grass equivalent -> wooden floor
blocked -> toolbox / crate / shelf
```

Tasks:

- [ ] Add `theme_id` to level data.
- [ ] Theme selects terrain meshes/materials.
- [ ] Theme selects scatter assets.
- [ ] Theme selects optional background dressing.
- [ ] Gameplay rules remain independent from visual theme.
- [ ] Create placeholder Garden theme.
- [ ] Create placeholder Sandpit theme.
- [ ] Create placeholder Shed theme.

---

# V3 — Level Authoring Tools

## Goal

Make level creation fast enough that creating five variations of a biome is cheap.

The level designer should not have to hand-edit large JSON arrays.

Possible implementations:

- Godot editor plugin
- in-game developer editor
- simple external editor
- generated level file from an ASCII layout

Begin with the simplest option.

## V3.1 — ASCII level format

Example:

```text
####################
#..................#
#..GGGGGG..........#
#..G....G..........#
S==G....G=========>O
#..G....G..........#
#..GGGGGG..........#
#..................#
####################
```

Potential symbols:

```text
. = grass
= = path
# = blocked
S = spawn
O = objective
```

Tasks:

- [ ] Prototype ASCII-to-level-data converter.
- [ ] Validate equal row widths.
- [ ] Give useful errors for unknown symbols.
- [ ] Generate normal level-data output.
- [ ] Preserve source ASCII file for readability.
- [ ] Add unit tests.

This is likely particularly useful for coding agents because layouts are easy to inspect and modify in text.

---

# V3.2 — Level Validation

Automated level checks:

- [ ] Spawn exists.
- [ ] Objective exists.
- [ ] Route exists.
- [ ] Spawn can reach objective.
- [ ] Route stays within grid bounds.
- [ ] No route crosses blocked cells unless explicitly allowed.
- [ ] Enough buildable tiles exist.
- [ ] No tower-starting positions overlap path.
- [ ] No unknown terrain types exist.
- [ ] No missing visual asset produces a hard crash.

Useful optional statistics:

```text
grid size
route length
buildable tile count
blocked tile count
path coverage
number of chokepoints
```

Later:

- [ ] Estimate tower coverage.
- [ ] Warn when one build tile sees too much of the route.
- [ ] Warn when the map has excessive dead space.

---

# V4 — Advanced Terrain

Do not start V4 until the previous systems are useful in actual gameplay.

Possible features:

- multiple height levels
- ramps
- bridges
- tunnels
- route crossing
- movement-cost terrain
- destructible terrain
- movable obstacles
- dynamic route changes
- large multi-tile towers
- multi-cell props
- water / mud modifiers

Tasks should be created individually when needed.

Do not build these preemptively.

---

# PR Strategy

Agents should work in small, reviewable pull requests.

A PR should usually complete one coherent group of checkboxes.

Good PR examples:

```text
PR: Add grid coordinate system
PR: Add basic terrain data format
PR: Add placeholder terrain scenes
PR: Add Blender tile-template generator
PR: Add basic route visualization
PR: Add garden scatter placeholders
PR: Add ASCII level importer
```

Bad PR:

```text
PR: Implement whole tile system
```

Each PR should include:

- [ ] Short description.
- [ ] Relevant checked-off items from this document.
- [ ] Tests where appropriate.
- [ ] Screenshots for visible changes.
- [ ] No unrelated refactors.
- [ ] Documentation update if conventions changed.
- [ ] Follow-up TODOs explicitly listed rather than silently left unfinished.

---

# Agent Instructions

When working from this document:

1. Do not implement later phases unless the current task explicitly requires them.
2. Prefer simple implementations over generalized frameworks.
3. Use existing project conventions when available.
4. Do not replace working project architecture unnecessarily.
5. Create obvious placeholders when an art asset is missing.
6. Placeholder assets must be recognisable by both:
   - appearance
   - filename / node name
7. Keep gameplay logic separate from visual dressing.
8. Avoid hardcoded level-specific behavior.
9. Use round dimensions and values unless there is a concrete reason not to.
10. Add comments where they help explain Godot-specific concepts to a developer learning Godot.
11. Prefer example scenes when introducing a new reusable system.
12. Keep debug tooling easy to enable.
13. Do not remove debug tooling merely because final art is added.
14. Validate imported assets for scale, origin, and orientation.
15. When uncertain, create the simplest usable version and document the assumption.

---

# Initial Recommended PR Sequence

## PR 1 — Grid foundation

- [ ] Tile constants.
- [ ] Coordinate conversion.
- [ ] Grid container.
- [ ] 20 × 20 example grid.
- [ ] Debug visualization.
- [ ] Tests for coordinate conversion.

## PR 2 — Level data

- [ ] Level schema/data class.
- [ ] Grass/path/blocked terrain.
- [ ] Spawn.
- [ ] Objective.
- [ ] Route.
- [ ] Example garden level.

## PR 3 — Placeholder terrain

- [ ] Grass tile placeholder.
- [ ] Sand path tile placeholder.
- [ ] Blocked tile placeholder.
- [ ] Correct GLB import.
- [ ] Correct naming.
- [ ] Screenshot of example level.

## PR 4 — Blender bootstrap

- [ ] `create_tile_templates.py`.
- [ ] 2.0 m tile generation.
- [ ] 0.2 m thickness.
- [ ] grass-card placeholder.
- [ ] naming conventions.
- [ ] README instructions for running the script.
- [ ] verified GLB export into Godot.

## PR 5 — Path gameplay

- [ ] Enemy route traversal.
- [ ] Path debug visualization.
- [ ] Route validation.
- [ ] Error messages for invalid route definitions.

## PR 6 — Tower placement integration

- [ ] Query whether tile is buildable.
- [ ] Prevent placement on path.
- [ ] Prevent placement on blocked tile.
- [ ] Visual hover/debug state.

At this point V1 is considered complete enough to build actual test levels.

---

# First Content Target

Once V1 works, create:

```text
Garden 1-1
Garden 1-2
Garden 1-3
Garden 1-4
Garden 1-5
```

These may initially reuse the same placeholder assets.

The purpose is to test whether the tile system genuinely makes level creation fast.

Do not create polished Garden assets before proving that creating and modifying these five layouts is comfortable.

A useful success metric:

> A new simple level layout should take minutes, not hours, to create and test.

---

# Design Decisions Summary

Current recommended defaults:

| Setting | Value |
|---|---:|
| Tile width | 2.0 m |
| Tile depth | 2.0 m |
| Tile thickness | 0.2 m |
| Default grid | 20 × 20 |
| Default footprint | 40 × 40 m |
| Grass tuft height | 0.5 m |
| Grass card width | 0.25 m |
| Initial terrain types | 3 |
| Initial themes | Garden first |

Core architectural rule:

> **The grid determines gameplay; assets determine appearance.**

Core art rule:

> **Placeholder assets are valid deliverables when their purpose is obvious by both appearance and name.**

Core scope rule:

> **Build only enough system to make the next levels faster to create.**
