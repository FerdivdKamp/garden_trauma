# Tower playground

Open either scene in Godot 4.7 and press **F6** to run it. **F5** runs the placement scene, which is the current main scene.

## Tower demo (`scenes/tower_demo.tscn`)

Use the tower selector to switch between single and double barrels. Change the sliders or number fields to test detection range (blue ring), attack range (yellow ring), turn speed, damage, and the sphere's distance and health. **Reset barrel away from pawn** makes the turning behavior easy to see. The tower fires when the living sphere is in range and the barrel is aimed at it; raise the sphere's health after it turns gray to try again. The save buttons keep tower and pawn settings in Godot's `user://` folder for later runs.

## Tower placement (`scenes/tower_placement.tscn`)

Click a single or double barrel tile, move the translucent preview over the ground, then click to place towers. A red preview means the position is blocked by the tan path, the ground edge, or another tower. Keep clicking to place more; press **Esc** to cancel. Select the `PlacementPath` node in the editor to adjust `path_width` or edit its `Curve3D` route.

Run the unit tests from this directory:

```powershell
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_rules.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_demo.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_placement.gd
```

`scripts/tower_rules.gd` holds the range, turning, and damage rules. Both scenes share the basic-shape tower visual, which can later be replaced by Blender models.
