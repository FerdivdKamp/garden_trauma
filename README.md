# Tower playground

## Blender asset helper

The optional [asset pipeline](asset_pipeline.md) tool creates the Blender source and
Godot model folders and exports `.blend` files to `.glb`. Run
`python tools/asset_pipeline.py gui` for its small desktop window, or use
`python tools/asset_pipeline.py init` and `python tools/asset_pipeline.py export <file.blend>`
from a terminal. See the pipeline document for folder and export conventions.

## Tower and unit data

Gameplay definitions live in one JSON file per type under `data/towers/` and `data/units/`. To add a type, copy a nearby file, give it a unique lowercase `id` (letters, digits, underscores), and edit its values. Keep the `$schema` line: VS Code uses it to validate fields and offer completion. The corresponding schemas are in `data/schemas/`.

`DefinitionLoader` reads each directory and checks values at runtime before making `TowerDefinition` or `UnitDefinition` resources. A bad file reports an error and is skipped; duplicate IDs are reported and the first file wins. Both tower scenes use `toy_tank` for the single barrel and `double_tank` for the double barrel. The placement scene uses `red_sphere` and `blue_sphere` for enemies. To use a newly added type in a prototype, add it to that scene's selection UI and look up its typed definition in the loaded collection.

The tower demo's **Save tower definition** button writes a complete JSON definition to `user://tower_definitions/<id>.json`. On the next run, both scenes use that file in place of the matching packaged definition. This keeps saving available in exported games, where `res://data/towers/` is normally read-only. The packaged JSON remains the version-controlled default. Older `user://tower_single.json` and `user://tower_double.json` settings appear in the demo if no new override exists; press Save to convert them. The pawn save remains a separate playground setting.

The placement prototype applies damage, cooldown, attack and detection range, turn speed, target tags, armor, and tag bonuses from these definitions. It still uses instant hits, so `projectile_speed`, cost, and reward are available for future projectile and economy features but have no effect yet. Its enemy speed and visual scale controls are runtime experiment controls; initial speed comes from the unit JSON.

## Balance report

Run `python tools/balance_report.py` from the project root to estimate every map with a matching wave file, or add `--level garden_test_01` for one level. The report reads the map, waves, tower and unit JSON, plus starting resources, available tower IDs, and tile size from the Godot scripts. It prints route length, each wave's defeated and leaked enemies, tower placements, coins, remaining garden health, and the outcome under one automatic placement policy.

This is a **comparison tool**, not a verdict on whether players will find a level easy or hard. Before each wave it buys the affordable towers with the most route coverage per coin, then approximates the current automatic targeting, rotation, cooldown, instant hits, armor, and kill rewards in 0.1 second steps. It does not search all possible placements, react during a wave, use saved `user://` tower overrides, or reproduce Godot's exact 3D distances and frame order. A reported defeat means this particular policy lost; a player may find a better placement. Use changes in its wave results to flag levels for playtesting, then calibrate any difficulty labels against actual playtest results.

Run the definition test with:

```powershell
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_definitions.gd
```

Open either prototype scene in Godot 4.7 and press **F6** to run it. **F5** starts at the main menu; Start opens level selection.

## Sound V1

The main menu's Options panel changes the `Music` and `SFX` buses and saves the choices in `user://settings.cfg`. `AudioSettings` owns those preferences. `AudioManager` owns one looping music player, so the track continues when Start changes scenes. The three placed towers have positional fire players; enemies have positional cues for defeat and reaching the objective. Audio assets and their known provenance are listed in [audio sources](assets/audio/audio-sources.md). The two enemy sounds are temporary copies to replace later.

## Tower demo (`scenes/tower_demo.tscn`)

Use the tower selector to switch between single and double barrels, each backed by its own definition. Change the sliders or number fields to test detection range (yellow filled circle), attack range (green filled circle), turn speed, damage, fire rate in shots per second, and the sphere's distance and health. Both circles fade from transparent at the center to opaque at their edges, keeping the tower visible. **Reset barrel away from pawn** makes the turning behavior easy to see. The tower fires when the living sphere is in range and the barrel is aimed at it; raise the sphere's health after it turns gray to try again. Save writes a full tower definition override; the pawn's Save button keeps its separate `user://pawn.json` setting.

## Tower placement (`scenes/tower_placement.tscn`)

Click a tower button, move the translucent preview over a grass tile, then click to place it at that tile's center. The preview shows both filled ranges; hover over a placed tower to see its ranges too. Sand, rocks, and occupied tiles reject placement. Keep clicking to place more; press **Esc** or right-click to clear the selection.

The normal game begins with 240 coins and 10 garden health. Buy and place towers before pressing **Start wave 1**. Each garden has its own wave schedule under `levels/waves/`; after clearing a wave, a short break ends before the next wave can be started. Defeated enemies pay their unit's reward once. Each enemy that reaches the objective removes one garden health. Clear the last wave to win, or lose all garden health to be defeated. The sidebar shows coins, health, wave, and remaining enemies; Pause, Restart, Retry, and Main menu controls complete the loop.

**Start** opens level selection. Garden 1 is available immediately; winning it unlocks Garden 2. The second garden uses a longer route and its own three waves. The result panel offers **Next level** after winning Garden 1 and **Level selection** after the final victory or a defeat. Winning records the stable level ID in `user://progress.cfg`; `LevelProgress` loads it on startup and keeps it separate from audio's `user://settings.cfg`. The catalog in `scripts/level_progress.gd` connects each ID to its map and waves. Run `tests/test_level_progress.gd` headlessly to check selection, unlocks, save loading, and both level files.

For the original enemy playground, enable `debug_mode` on the `TowerPlacement` scene root in the Inspector. This restores the manual spawn/reset panel, type selector, and speed/scale controls, and starts one red enemy. These manually spawned enemies remain visible after defeat for testing. Placed towers detect enemies within 9 units, turn at 90 degrees per second, and deal 10 damage once per second within 6 units when aimed. Enemies use `PathFollow3D` under `PlacementPath`; the route in the level JSON builds its curve.

## Tile levels

See [Build a tile level](build_tile_level.md) for a short step-by-step guide and suggested tooling improvements.

`levels/data/garden_test_01.json` is the 20 by 20 example level used by the tower demo and Garden 1; `garden_test_02.json` is Garden 2. `tiles` has one string per row, from low Z to high Z: `.` is buildable grass, `=` is walkable sand, `#` is blocked rock, `S` is the spawn sand tile, and `O` is the objective sand tile. The `spawn`, `objective`, and ordered `route` use integer `[x, z]` tile coordinates. Consecutive route cells must share an edge; the first and last cells must match spawn and objective. Invalid data reports a specific error when the scene loads.

`LevelGrid` owns the shared `TILE_SIZE = 2.0` and `TILE_HEIGHT = 0.2` values. It centers the map on the world origin: on a 20 by 20 map, tile `[0, 0]` is at world `(-19, 0, -19)`, tile `[1, 0]` is at `(-17, 0, -19)`, and the tile top is at Y = 0. Each terrain uses a named placeholder scene under `scenes/tiles/`. Set a scene's `LevelGrid.level_file` property to use another level; the placement scene generates its enemy curve from that level's route on startup.

In the placement scene, press **G** for the grid lines, **C** for tile coordinates, **R** for the ordered route, and **I** to print the tile under the cursor. The `LevelGrid` node also has Inspector toggles for these overlays. Press **F6** on either scene to run it directly. The tower demo uses the same tile grid as its floor while keeping its standalone tower and pawn controls.

Run the unit tests from this directory:

```powershell
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_rules.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_level_grid.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_demo.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_placement.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_placement_combat.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_audio_pipeline.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_basic_game_loop.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_level_progress.gd
```

`scripts/tower_rules.gd` holds the range, turning, and damage rules. Both scenes share the basic-shape tower visual, which can later be replaced by Blender models.
