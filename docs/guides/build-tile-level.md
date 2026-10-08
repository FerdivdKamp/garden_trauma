# Build a tile level

1. Copy `levels/data/garden_test_01.json` to a new file in `levels/data/`. Give it a new `name`.
2. Set `width`, `height`, and an integer `level_seed` between 0 and 2147483647. The `tiles` array needs exactly `height` strings, each exactly `width` characters long. The first string is row `z = 0`; the first character is `x = 0`.
3. Draw the terrain with `.` for buildable grass, `=` for walkable sand, and `#` for blocked rock. Use `S` for the spawn sand tile and `O` for the objective sand tile.
4. Set `spawn` and `objective` to their `[x, z]` positions. List every cell enemies cross in `route`, in order. Start at spawn, end at objective, and move one cell horizontally or vertically at a time. Every route cell must be sand (`=`, `S`, or `O`).
5. Create a matching wave file under `levels/waves/`, using the same level ID as the map filename. Copy an existing wave file to see its format; enemy IDs must exist in `data/units/`.
6. Add an entry to `LEVELS` in `scripts/level_progress.gd` with a stable ID, display title, map path, and wave path. The order controls unlocks: completing one entry unlocks the next.
7. Run the game with **F5** and select the new level. If the data does not load, read Godot's **Output** panel for the validation error. Run `tests/test_level_grid.gd` to check the grid rules.

Each tile is 2 m square, with its top at world Y = 0. The grid is centered on the world origin. On a 20 by 20 map, `[0, 0]` has its center at world `(-19, 0, -19)`. The placement scene builds the enemy path from `route`, and towers snap to grass tile centers.

Grass and sand path visuals each use four GLB variants. Each tile derives a stable visual seed from `level_seed` and its grid coordinates; that seed chooses a mesh and a rotation in 90-degree steps. Changing `level_seed` rerolls the visuals without changing terrain or pathing. To pin a tile's visual seed for later level editing, add an optional map entry such as `"visual_seeds": {"5,5": 18421}`. The key is `x,z`, and the override takes precedence over the level seed.

The playable placement scene reads the selected level from `LevelProgress` at startup and sets its `LevelGrid` and wave file automatically. Changing the `LevelGrid.level_file` property in `scenes/tower_placement.tscn` alone will not select a different playable level. In `scenes/tower_demo.tscn`, the grid file is independent and can be changed in the Inspector to preview another map.

Enable `debug_mode` on the `TowerPlacement` root to inspect the map while running it. **G** toggles grid lines, **C** tile coordinates, **R** the route, and **I** prints the tile under the cursor.

Ideas for authoring tools, such as a text map converter or editor preview, are tracked in [Next steps](../roadmap/next.md).
