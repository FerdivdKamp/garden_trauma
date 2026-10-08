# Project structure

| Path | Purpose |
| --- | --- |
| `project.godot` | Godot project configuration; `scenes/main_menu.tscn` is the main scene. |
| `scenes/` | Menus, tower demo, playable placement scene, enemies, effects, and tile scenes. |
| `scripts/` | Gameplay rules, loading, waves, UI behavior, progress, and audio. |
| `data/towers/`, `data/units/` | One JSON definition per tower or enemy type. |
| `data/schemas/` | JSON schemas for those definitions. |
| `levels/data/`, `levels/waves/` | Tile maps and matching wave schedules for the two gardens. |
| `art/blender/` | Editable Blender source assets. |
| `assets/models/` | Exported models and material manifests used by Godot. |
| `assets/audio/` | Music, effects, and bus layout. See [audio sources](audio-sources.md). |
| `tools/` | Blender export pipeline, Godot material import script, and balance report. |
| `tests/` | Focused Godot and Python checks. |

`scripts/level_progress.gd` lists the playable level IDs and links each to its map and waves. Add a new level there after creating its files. [Build a tile level](../guides/build-tile-level.md) explains the map format.
