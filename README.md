# Tower playground

## Tower and unit data

Gameplay definitions live in one JSON file per type under `data/towers/` and `data/units/`. To add a type, copy a nearby file, give it a unique lowercase `id` (letters, digits, underscores), and edit its values. Keep the `$schema` line: VS Code uses it to validate fields and offer completion. The corresponding schemas are in `data/schemas/`.

`DefinitionLoader` reads each directory and checks values at runtime before making `TowerDefinition` or `UnitDefinition` resources. A bad file reports an error and is skipped; duplicate IDs are reported and the first file wins. The placement scene currently selects `toy_tank`, `red_sphere`, and `blue_sphere` by ID. To use a newly added type in that prototype, add it to the scene's selection UI and look up its typed definition in the loaded collection. The tower demo's save buttons still store temporary playground settings in `user://`; those saves are separate from gameplay definitions.

The placement prototype applies damage, cooldown, range, target tags, armor, and tag bonuses from these definitions. It still uses instant hits and its existing detection radius, so `projectile_speed`, cost, and reward are available for future projectile and economy features but have no effect yet. Its enemy speed and visual scale controls are runtime experiment controls; initial speed comes from the unit JSON.

Run the definition test with:

```powershell
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_definitions.gd
```

Open either scene in Godot 4.7 and press **F6** to run it. **F5** runs the placement scene, which is the current main scene.

## Tower demo (`scenes/tower_demo.tscn`)

Use the tower selector to switch between single and double barrels. Change the sliders or number fields to test detection range (blue ring), attack range (yellow ring), turn speed, damage, and the sphere's distance and health. **Reset barrel away from pawn** makes the turning behavior easy to see. The tower fires when the living sphere is in range and the barrel is aimed at it; raise the sphere's health after it turns gray to try again. The save buttons keep tower and pawn settings in Godot's `user://` folder for later runs.

## Tower placement (`scenes/tower_placement.tscn`)

Click a single or double barrel tile, move the translucent preview over the ground, then click to place towers. A red preview means the position is blocked by the tan path, the ground edge, or another tower. Keep clicking to place more; press **Esc** to cancel. Select the `PlacementPath` node in the editor to adjust `path_width` or edit its `Curve3D` route.

One red enemy starts on the path. The enemy panel lets you choose a red or blue sphere, spawn more, reset the enemies, and adjust each type's movement speed and visual scale. The blue sphere starts slightly larger and has 75 health; red has 50. Each enemy's health appears in the panel. Placed towers detect enemies within 9 units, turn at 90 degrees per second, and deal 10 damage once per second within 6 units when aimed. The reset button removes all enemies and creates one fresh enemy of the selected type; placed towers remain in place. The enemy uses `PathFollow3D` under `PlacementPath`, so editing the curve also changes its route.

Run the unit tests from this directory:

```powershell
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_rules.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_demo.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_placement.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_placement_combat.gd
```

`scripts/tower_rules.gd` holds the range, turning, and damage rules. Both scenes share the basic-shape tower visual, which can later be replaced by Blender models.
