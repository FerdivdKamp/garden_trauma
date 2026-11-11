# Project structure

| Path | Purpose |
| --- | --- |
| `project.godot` | Godot project configuration; `scenes/main_menu.tscn` is the main scene. |
| `scenes/` | Menus, tower demo, playable placement scene, enemies, effects, and tile scenes. |
| `scripts/` | Gameplay rules, loading, waves, UI behavior, progress, and audio. |
| `data/towers/`, `data/units/` | One JSON definition per tower or enemy type. |
| `data/dressing/` | Environment dressing chance, count, and scale settings. |
| `data/grass_material_settings.json` | Saved grass and lighting values from the material lab. |
| `data/schemas/` | JSON schemas for those definitions. |
| `levels/data/`, `levels/waves/` | Tile maps and matching wave schedules for the two gardens. |
| `art/blender/` | Editable Blender source assets. |
| `assets/models/` | Exported models and material manifests used by Godot. |
| `assets/audio/` | Music, effects, and bus layout. See [audio sources](audio-sources.md). |
| `tools/` | Blender export pipeline, Godot material import script, and balance report. |
| `tests/` | Focused Godot and Python checks. |

`scripts/level_progress.gd` lists the playable level IDs and links each to its map and waves. Add a new level there after creating its files. Entries marked `test` are available separately and do not advance the campaign; `TOWER_REWARDS` maps campaign completions to tower unlocks. [Build a tile level](../guides/build-tile-level.md) explains the map format.

`LevelProgress` also owns the local player list and switches the active progress file when a player is selected. Names are display values; generated IDs identify save files. The main menu provides creation, selection, and one-time import of the old shared progress save.

`tools/model_exports.json` inventories tower and unit model sources; `tools/export_models.py` lists them and exports active entries. See the [Blender asset workflow](../guides/blender-workflow.md) for scope, caveats, and commands.
