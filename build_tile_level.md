# Build a tile level

1. Copy `levels/data/garden_test_01.json` to a new file in `levels/data/` and change its `name`.
2. Set `width` and `height`. The `tiles` array needs exactly `height` strings, each exactly `width` characters long. The first string is row `z = 0`; within a string, the first character is `x = 0`.
3. Draw the terrain with `.` for buildable grass, `=` for walkable sand, and `#` for blocked rock. Use `S` for the spawn sand tile and `O` for the objective sand tile.
4. Set `spawn` and `objective` to the matching `[x, z]` positions. List every cell enemies should cross in `route`, in order. Begin at `spawn`, end at `objective`, and move one tile horizontally or vertically between entries. Every route cell must be sand (`=`, `S`, or `O`).
5. Open `scenes/tower_placement.tscn` **in Godot's scene editor**. In the **Scene** tree, expand **TowerPlacement** and select its **LevelGrid** child node. In the **Inspector**, find **Level File** under the attached `level_grid.gd` script and choose `res://levels/data/garden_test_02.json` (or your new file). Save the scene, then run it with **F6**. To keep the example scene available, duplicate the scene first and change the copy. You can set the same property on `tower_demo.tscn` if you want its floor to match.

The setting is declared as `level_file` in `scripts/level_grid.gd` (there is no `level.gd`). Its default is `garden_test_01.json`, so the `.tscn` text does **not** show a `level_file` line until you override and save it. If you edit the scene file as text, add `level_file = "res://levels/data/garden_test_02.json"` directly below `script = ExtResource("4_grid")` in the `[node name="LevelGrid" ...]` section. The Godot Inspector is the easier way to set it.

Each tile is 2 m square, with its top at world Y = 0. The grid is centered on the world origin. On a 20 by 20 map, `[0, 0]` has its center at world `(-19, 0, -19)`. The placement scene creates the enemy path from `route`, and towers snap to grass tile centers.

While running the placement scene, press **G** for grid lines, **C** for coordinates, **R** for the route, and **I** to print the tile under the cursor. If the level does not load, check Godot's **Output** panel for the data error. Run `tests/test_level_grid.gd` from Godot for a quick check of the example and grid rules.

## Suggested next steps for easier level building

1. Add a small ASCII map converter so a designer can draw rows in plain text and generate the JSON, including `spawn` and `objective` coordinates.
2. Add an editor preview or paint tool for terrain cells and ordered route points, with immediate validation feedback.
3. Add a level picker in the placement scene so new maps can be tried without duplicating a scene or changing the Inspector property.
