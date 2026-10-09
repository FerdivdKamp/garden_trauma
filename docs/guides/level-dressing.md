# Level dressing

The Garden uses decorative meshes to break up repetition in the grass tiles. These meshes have no collision and do not change whether a tile is buildable or walkable. The tile system's [scatter plan](../roadmap/plans/tile-system.md) describes the longer term idea.

## Change how much appears

Edit [`data/dressing/garden.json`](../../data/dressing/garden.json). Each object in `types` describes one decoration:

| Field | Meaning |
| --- | --- |
| `id` | Stable name for this decoration. Give each type a different ID. |
| `scene` | Godot scene or imported GLB to instantiate. |
| `chance` | Probability from `0.0` to `1.0` that a grass tile gets this type. |
| `min_per_tile`, `max_per_tile` | Inclusive number of copies when the chance succeeds. |
| `scale_min`, `scale_max` | Random uniform scale range. Use `1.0` for the authored size. |
| `height_offset` | Y position relative to the grid's ground plane. |
| `edge_margin` | Optional distance from the cell edge to the decoration's pivot. Set it large enough for the rotated mesh and its maximum scale; the default is `0.2` m. |

For example, `chance: 0.6`, `min_per_tile: 1`, and `max_per_tile: 3` means about 60% of grass cells get one to three tufts. Set `chance` to `0` to hide a type. `LevelGrid.dressing_file` selects the config in the Inspector, so a later environment can use its own file. The current Garden levels share the Garden config.

The grid gives each grass cell a stable seed based on `level_seed` and its coordinates. Each dressing type uses its `id` for a separate random stream. Reopening a level reproduces the same positions, rotations, counts, and scales. Changing `level_seed` rerolls them. Individual `visual_seeds` entries in a level map also affect dressing in that cell.

Dressing is grouped under `LevelGrid/Dressing/Cell_x_z` in the scene tree. It is generated only on grass. The per-type `edge_margin` keeps the larger meshes within their grass cells beside the sand route. When a tower is placed, the dressing in its cell is removed so it cannot poke through the tower base. There is no collision or gameplay effect.

## Garden assets and adding more

The Garden config includes `grass_tuft`, `grass_tuft1`, `grass_tuft2`, `pebble`, `pebble1`, and `pebble2`. Each corresponds to a `.blend` source under `art/blender/environment/garden/dressing/` and a matching `.glb` under `assets/models/environment/garden/dressing/`. `pebble1` is a small three-stone group, so it has a larger edge margin and appears less often than a single tuft. Each type has its own chance and independent random stream.

1. Save a new `.blend` under `art/blender/environment/garden/dressing/`.
2. Export it with `python tools/asset_pipeline.py export art/blender/environment/garden/dressing/<name>.blend`. See the [Blender workflow](blender-workflow.md) if Blender is not on `PATH`.
3. Add a unique `id` and matching `scene` path to `types` in `data/dressing/garden.json`. Choose chance, count, scale, height, and edge margin for the mesh.
4. Open the level in Godot and inspect the placement. Adjust `height_offset` if the mesh origin is above or below its visible bottom. Check a grass cell beside sand to confirm the mesh stays within the grass cell after rotation.

The grass tuft GLB exports with a double sided material because its Blender material has backface culling off. Keep that setting for other thin card meshes. The tuft's small `height_offset` brings its lowest vertices near the grass surface.
