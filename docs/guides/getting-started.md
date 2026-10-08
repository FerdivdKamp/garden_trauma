# Getting started

## Open the project

1. Open the repository root, the folder containing `project.godot`, in Godot 4.7.
2. Press **F5** to run the game. The main menu opens first.
3. Choose **Start**, select Garden 1, place towers, and start a wave. Garden 2 unlocks when Garden 1 is completed.

You can also open `scenes/tower_demo.tscn` or `scenes/tower_placement.tscn` and press **F6** to run a scene directly. The demo is a focused place to adjust tower behavior; the placement scene is the playable battle.

## Read and edit the project

- [Playing and testing](playing-and-testing.md) covers controls, saves, and test commands.
- [Tower and unit data](game-data.md) explains how definitions and upgrades work.
- [Build a tile level](build-tile-level.md) walks through a map file.
- [Blender asset workflow](blender-workflow.md) explains exporting and reimporting models.
- [Project structure](../reference/project-structure.md) points to the main scenes, scripts, and data folders.

Run `python -m mkdocs serve` from the repository root to preview these docs, or `python -m mkdocs build --strict` to check the site. Both commands use `mkdocs.yml`; they require `mkdocs-material` in the active Python environment.
