# Tower and unit data

Tower definitions are individual JSON files in `data/towers/`; enemies are in `data/units/`. Start by copying a nearby file. Give the new type a unique lowercase `id` containing letters, digits, or underscores, and keep its `$schema` field. The schemas in `data/schemas/` document valid fields and support editor completion.

`scripts/definition_loader.gd` validates definitions at runtime. Invalid files are skipped with an error; a duplicate ID is reported and the first file wins. To make a new type selectable, add its ID to the relevant scene's selection UI and load its typed definition. The level's waves also refer to enemy IDs from these files.

Tower `attack` values include damage, cooldown, range, and projectile speed. The placement scene uses damage, cooldown, range, detection range, turn speed, target tags, armor, and tag bonuses. Laser, tank, and lightning damage resolves immediately; a tank shell's travel is a visual effect. The water rocket deals damage on impact. Its optional `homing_turn_speed` (degrees per second) and `projectile_lifetime` (seconds) control its flight.

Towers normally use `firing_mode: "targeted"` (the default) and require positive range and detection range. The Gumball Machine uses `firing_mode: "lane"`, `targeting.priority: "lane"`, and zero range and detection range because it fires along an adjacent path when an enemy enters it. Its `ball_count` controls the number of balls in a volley and can be replaced by an upgrade; optional `bounce_height` and `bounce_frequency` control their visual motion. See [Gumball Machine tower](gumball-tower.md) for the lane behavior.

The Lava Lamp uses `firing_mode: "tile"` and `targeting.priority: "nearest_tile"`. Its range is measured in world units (one tile is 2 units), and it only fires at uncovered path tiles currently occupied by ground enemies. `attack.damage` is the splash on impact; `lava_damage_per_second` and `puddle_radius` control the persistent puddle. `projectile_speed` sets travel time, clamped to 0.7–1.1 seconds. The level's `LavaField` keeps puddles alive when their tower is removed and cools them when the wave ends; a blob still in flight is cancelled. The visible lamp is a replaceable scene at `scenes/lava_lamp_visual.tscn` with a named `Muzzle` marker.

Each tower currently defines exactly three upgrades. Their order in the `upgrades` array is the purchase order. Each has an ID, name, cost, and an `attack` object containing explicit replacement values. Only fields named in that object change. The current UI lets the player buy the next upgrade of a placed tower when affordable.

The tower demo can save a full definition to `user://tower_definitions/<id>.json`. At startup, that user file overrides the packaged definition with the same ID. To change version-controlled defaults, edit `data/towers/` instead. Existing saved overrides may hide changes to those defaults during local testing.

Run the definition and upgrade checks after changing JSON:

```powershell
godot --headless --path . --script res://tests/test_definitions.gd
godot --headless --path . --script res://tests/test_tower_upgrades.gd
godot --headless --path . --script res://tests/test_lava_lamp.gd
```
