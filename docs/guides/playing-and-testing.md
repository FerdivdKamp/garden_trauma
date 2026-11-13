# Playing and testing

## Play a level

From the main menu, choose **Start**, then select an existing player or enter a new name and choose **Start new game**. Each player has separate completed levels and tower unlocks. Select Garden 1 to play. The normal game starts with 240 coins and 10 garden health. Select a tower in the bottom-left panel, move its preview over a grass tile, and click to place it. Sand, rock, occupied tiles, and unaffordable purchases reject placement. Press **Esc** or right-click to clear the selection.

Press **Start wave 1** when ready. Defeated enemies pay their unit reward; each enemy that reaches the objective removes one health. After a wave and its break, start the next wave. The compact top-right panel shows credits, life, wave, Start wave, and Pause. The optional hint panel in the top-left includes placement messages and can be turned on or off in Options, available from the main menu or Pause. Restart and Main menu are also in Pause. Winning Garden 1 unlocks Garden 2; both have their own map and wave schedule.

The level selection also has **Tower Test** at the top. It copies Garden 1's map and waves, makes every tower available, and charges one credit per tower and upgrade. Completing it does not advance the campaign. In the campaign, only the Laser Tower is initially available; winning Garden 1 unlocks the Lightning Tower for later levels and replays. Other towers have no campaign unlock yet. Existing Garden 1 completions also grant the Lightning Tower.

Campaign victories earn one star, or two if the garden loses no health during the level. The best result is saved per player and shown on level selection; replaying cannot lower it. The third star is reserved for a future achievement. Earlier completed levels count as one star because their remaining health was not recorded. Tower Test shows the result for the current run but does not save campaign stars.

The bottom-left tiles show small views of the actual tower models. Hover a tile to see its name and price. Click a placed tower to inspect and buy its next upgrade. Hover Upgrade to see its cost and the current-to-new stat values, even if you lack credits. Each tower has three sequential upgrades defined in its JSON file. An upgrade replaces the listed attack values and leaves unspecified values as they were.

The Gumball Machine uses a straight adjacent path lane. Its placement preview highlights the covered tiles and shows a direction arrow. Press **R** while placing it to cycle valid lanes; see [Gumball Machine tower](gumball-tower.md) for its controls and testing checklist. In debug mode, **R** still toggles the route overlay when no Gumball Machine is selected.

The Lava Lamp fires at an uncovered path tile occupied by a ground enemy. Its puddle damages enemies crossing that tile until the wave ends. Its range ring uses the same world-unit scale as other towers; five tiles equal 10 world units.

The tower demo in `scenes/tower_demo.tscn` lets you compare tower types, change range, turn speed, damage, fire rate, and enemy health, then reset the barrel away from the target to watch aiming. Its save button writes a tower definition override for that demo.

## Saves and debugging

The player list is stored in `user://players.cfg`, and each player's level completion is stored in a separate file under `user://players/`. To keep a save from before player selection existed, enter a name and select **Import previous game**; this copies `user://progress.cfg` without deleting it. Import is offered once. Audio and hint preferences in `user://settings.cfg` and developer demo tower overrides in `user://tower_definitions/<id>.json` are shared on this device. `user://` is Godot's per-user data folder; these are separate from the version-controlled defaults in `data/`.

For the older enemy playground, enable `debug_mode` on the `TowerPlacement` scene root in the Inspector. This exposes manual enemy spawn and adjustment controls. In debug mode, **G** toggles grid lines, **C** coordinates, **R** the route, and **I** prints the tile under the cursor. These keys are not active in normal play.

## Run checks

From the repository root, replace `godot` with the path to your Godot 4.7 executable if it is not on `PATH`:

```powershell
godot --headless --path . --script res://tests/test_basic_game_loop.gd
godot --headless --path . --script res://tests/test_level_progress.gd
godot --headless --path . --script res://tests/test_tower_progression.gd
godot --headless --path . --script res://tests/test_players.gd
godot --headless --path . --script res://tests/test_tower_upgrades.gd
godot --headless --path . --script res://tests/test_level_grid.gd
```

Other focused tests live under `tests/`, including definitions, audio, combat, effects, and asset import. Headless checks cover game rules and save/reload paths; a visual playthrough in the editor is still needed to judge feel, readability, and rendering.
