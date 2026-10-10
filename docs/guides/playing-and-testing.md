# Playing and testing

## Play a level

From the main menu, choose **Start**, then Garden 1. The normal game starts with 240 coins and 10 garden health. Select a tower in the bottom-left panel, move its preview over a grass tile, and click to place it. Sand, rock, occupied tiles, and unaffordable purchases reject placement. Press **Esc** or right-click to clear the selection.

Press **Start wave 1** when ready. Defeated enemies pay their unit reward; each enemy that reaches the objective removes one health. After a wave and its break, start the next wave. The bottom-right panel shows coins, health, wave, and remaining enemies. Pause, Restart, Retry, and Main menu controls are available during the loop. Winning Garden 1 unlocks Garden 2; both have their own map and wave schedule.

Click a placed tower to inspect and buy its next upgrade. Each tower has three sequential upgrades defined in its JSON file. An upgrade replaces the listed attack values and leaves unspecified values as they were.

The tower demo in `scenes/tower_demo.tscn` lets you compare tower types, change range, turn speed, damage, fire rate, and enemy health, then reset the barrel away from the target to watch aiming. Its save button writes a tower definition override for that demo.

## Saves and debugging

Level completion is stored in `user://progress.cfg`, audio preferences in `user://settings.cfg`, and demo tower overrides in `user://tower_definitions/<id>.json`. `user://` is Godot's per-user data folder; these are separate from the version-controlled defaults in `data/`.

For the older enemy playground, enable `debug_mode` on the `TowerPlacement` scene root in the Inspector. This exposes manual enemy spawn and adjustment controls. In debug mode, **G** toggles grid lines, **C** coordinates, **R** the route, and **I** prints the tile under the cursor. These keys are not active in normal play.

## Run checks

From the repository root, replace `godot` with the path to your Godot 4.7 executable if it is not on `PATH`:

```powershell
godot --headless --path . --script res://tests/test_basic_game_loop.gd
godot --headless --path . --script res://tests/test_level_progress.gd
godot --headless --path . --script res://tests/test_tower_upgrades.gd
godot --headless --path . --script res://tests/test_level_grid.gd
```

Other focused tests live under `tests/`, including definitions, audio, combat, effects, and asset import. Headless checks cover game rules and save/reload paths; a visual playthrough in the editor is still needed to judge feel, readability, and rendering.
