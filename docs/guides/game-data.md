# Tower and unit data

Tower definitions are individual JSON files in `data/towers/`; enemies are in `data/units/`. Start by copying a nearby file. Give the new type a unique lowercase `id` containing letters, digits, or underscores, and keep its `$schema` field. The schemas in `data/schemas/` document valid fields and support editor completion.

`scripts/definition_loader.gd` validates definitions at runtime. Invalid files are skipped with an error; a duplicate ID is reported and the first file wins. To make a new type selectable, add its ID to the relevant scene's selection UI and load its typed definition. The level's waves also refer to enemy IDs from these files.

Tower `attack` values include damage, cooldown, range, and projectile speed. The placement scene uses damage, cooldown, range, detection range, turn speed, target tags, armor, and tag bonuses. Combat currently resolves hits immediately; a shell's travel is a visual effect. `projectile_speed` controls that visual shell tween, not delayed damage.

Each tower currently defines exactly three upgrades. Their order in the `upgrades` array is the purchase order. Each has an ID, name, cost, and an `attack` object containing explicit replacement values. Only fields named in that object change. The current UI lets the player buy the next upgrade of a placed tower when affordable.

The tower demo can save a full definition to `user://tower_definitions/<id>.json`. At startup, that user file overrides the packaged definition with the same ID. To change version-controlled defaults, edit `data/towers/` instead. Existing saved overrides may hide changes to those defaults during local testing.

Run the definition and upgrade checks after changing JSON:

```powershell
godot --headless --path . --script res://tests/test_definitions.gd
godot --headless --path . --script res://tests/test_tower_upgrades.gd
```
