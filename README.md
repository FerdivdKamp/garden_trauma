# Tower playground

Open the project in Godot 4.7 and press **F6** on `scenes/tower_demo.tscn`, or press **F5** to run it as the main scene.

The blue outer circle is the detection radius. The yellow inner circle is the attack radius. The turret turns toward the sphere when it is detected, and fires once per second when the sphere is inside both circles and the barrel has lined up. The sphere turns gray at zero health. Raise its health to try another run.

Every numeric value has a slider and a number field. The reset button points the barrel away from the sphere, making turn speed easy to compare. The tower selector changes between one and two barrels; both currently use the same attack rules.

**Save tower parameters** stores a separate JSON file for each tower type. **Save pawn parameters** stores the pawn's current distance and health. Saved values load on the next run or when returning to a tower type. These files live in Godot's `user://` data directory; they are local experiment settings, not project assets.

Run the unit tests from this directory:

```powershell
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_rules.gd
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_tower_demo.gd
```

`scripts/tower_rules.gd` holds the small range, turning, and damage rules so they can be tested without opening the scene. The demo scene owns the visuals and interface. Its tower meshes are basic Godot shapes for now, so later Blender models can replace them without changing the rules.
