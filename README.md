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

Run the definition test with:

```powershell
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_definitions.gd
```

Open either prototype scene in Godot 4.7 and press **F6** to run it. **F5** starts at the main menu; Start opens the placement garden.

## Sound V1

The main menu's Options panel changes the `Music` and `SFX` buses and saves the choices in `user://settings.cfg`. `AudioSettings` owns those preferences. `AudioManager` owns one looping music player, so the track continues when Start changes scenes. The three placed towers have positional fire players; enemies have positional cues for defeat and reaching the objective. Audio assets and their known provenance are listed in [audio sources](assets/audio/audio-sources.md). The two enemy sounds are temporary copies to replace later.

## Tower demo (`scenes/tower_demo.tscn`)

Use the tower selector to switch between single and double barrels, each backed by its own definition. Change the sliders or number fields to test detection range (yellow filled circle), attack range (green filled circle), turn speed, damage, fire rate in shots per second, and the sphere's distance and health. Both circles fade from transparent at the center to opaque at their edges, keeping the tower visible. **Reset barrel away from pawn** makes the turning behavior easy to see. The tower fires when the living sphere is in range and the barrel is aimed at it; raise the sphere's health after it turns gray to try again. Save writes a full tower definition override; the pawn's Save button keeps its separate `user://pawn.json` setting.

## Tower placement (`scenes/tower_placement.tscn`)

Click a tower button, move the translucent preview over a grass tile, then click to place it at that tile's center. The preview shows both filled ranges; hover over a placed tower to see its ranges too. Sand, rocks, and occupied tiles reject placement. Keep clicking to place more; press **Esc** or right-click to clear the selection.

One red enemy starts on the path. The enemy panel lets you choose a red or blue sphere, spawn more, reset the enemies, and adjust each type's movement speed and visual scale. The blue sphere starts slightly larger and has 75 health; red has 50. Each enemy's health appears in the panel. Placed towers detect enemies within 9 units, turn at 90 degrees per second, and deal 10 damage once per second within 6 units when aimed. The reset button removes all enemies and creates one fresh enemy of the selected type; placed towers remain in place. Enemies use `PathFollow3D` under `PlacementPath`; the route in the level JSON builds its curve.

## Tile levels

See [Build a tile level](build_tile_level.md) for a short step-by-step guide and suggested tooling improvements.

`levels/data/garden_test_01.json` is the 20 by 20 example level used by both scenes. `tiles` has one string per row, from low Z to high Z: `.` is buildable grass, `=` is walkable sand, `#` is blocked rock, `S` is the spawn sand tile, and `O` is the objective sand tile. The `spawn`, `objective`, and ordered `route` use integer `[x, z]` tile coordinates. Consecutive route cells must share an edge; the first and last cells must match spawn and objective. Invalid data reports a specific error when the scene loads.

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
```

`scripts/tower_rules.gd` holds the range, turning, and damage rules. Both scenes share the basic-shape tower visual, which can later be replaced by Blender models.
