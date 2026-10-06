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

Open either scene in Godot 4.7 and press **F6** to run it. **F5** runs the placement scene, which is the current main scene.

## Tower demo (`scenes/tower_demo.tscn`)

Use the tower selector to switch between single and double barrels, each backed by its own definition. Change the sliders or number fields to test detection range (yellow filled circle), attack range (green filled circle), turn speed, damage, fire rate in shots per second, and the sphere's distance and health. Both circles fade from transparent at the center to opaque at their edges, keeping the tower visible. **Reset barrel away from pawn** makes the turning behavior easy to see. The tower fires when the living sphere is in range and the barrel is aimed at it; raise the sphere's health after it turns gray to try again. Save writes a full tower definition override; the pawn's Save button keeps its separate `user://pawn.json` setting.

## Tower placement (`scenes/tower_placement.tscn`)

Click a single or double barrel tile, move the translucent preview over the ground, then click to place towers. The preview shows both filled ranges; hover over a placed tower to see its ranges too. A red preview means the position is blocked by the tan path, the ground edge, or another tower. Keep clicking to place more; press **Esc** or right-click to clear the selected tile. Select the `PlacementPath` node in the editor to adjust `path_width` or edit its `Curve3D` route.

One red enemy starts on the path. The enemy panel lets you choose a red or blue sphere, spawn more, reset the enemies, and adjust each type's movement speed and visual scale. The blue sphere starts slightly larger and has 75 health; red has 50. Each enemy's health appears in the panel. Placed towers detect enemies within 9 units, turn at 90 degrees per second, and deal 10 damage once per second within 6 units when aimed. The reset button removes all enemies and creates one fresh enemy of the selected type; placed towers remain in place. The enemy uses `PathFollow3D` under `PlacementPath`, so editing the curve also changes its route.

Run the unit tests from this directory:

```powershell
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_rules.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_demo.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_placement.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_placement_combat.gd
```

`scripts/tower_rules.gd` holds the range, turning, and damage rules. Both scenes share the basic-shape tower visual, which can later be replaced by Blender models.
