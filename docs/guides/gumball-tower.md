# Gumball Machine tower

Select the fifth tower tile in the playable garden. The preview highlights every path tile in the selected straight lane; the yellow arrow shows the shot direction. The longest adjacent lane is selected first. Press **R** to cycle through other valid lanes, then click to place. A grass tile without an adjacent path cannot accept this tower. The label below the tower tiles shows the selected direction and lane length.

`scripts/gumball_lane.gd` reads `LevelGrid.is_walkable()`, which includes the spawn and objective path symbols. It scans north, east, south, west and retains that order to break equal-length ties. Placement stores the chosen direction and final cell on `GumballLaneAttack`; the placed machine never aims at enemies. The attack script inherits the existing upgrade methods but fires only when a living ground enemy is inside the selected lane. It fires three balls initially, four after Mk3, and five after Mk4. Each volley assigns distinct colors and small speed, bounce, and angle differences. The angled trajectories still end inside the final path tile. Each projectile checks its horizontal movement segment against ground enemies, remembers whom it hit, and moves its visible sphere up and down independently of the damage check.

The level path is static today. If a future mechanic edits path tiles during a battle, recalculate each placed gumball tower's lane and endpoint after the edit, and decide what happens to shots already in flight. Do that as part of the path-editing feature, not every frame.

## Replacing the placeholder

The procedural meshes are built by `scripts/gumball_visual.gd` inside `scenes/gumball_visual.tscn`. Replace the mesh children under `DirectionPivot` with an imported GLB, keeping the scene root, pivot, and `Muzzle` marker. The root origin is the center of the tower's ground tile. The pedestal occupies about 1.1 by 1.1 meters; the lid reaches about 1.95 meters high. The model faces local **-Z** at zero yaw, like the laser tower's Blender yaw pivot. The pivot rotates only when the player chooses a lane. Keep the muzzle near local `(0, 0.35, -0.88)`, at the front of the exit chute. The globe, candy, knob, lid, and body are decorative; firing and collision never refer to their mesh names.

## Check in the editor

1. Run `scenes/tower_placement.tscn`. Place the tower at grid cell `(6, 4)`; it should face east and highlight seven sand tiles. Check that the arrow and shots point the same way.
2. Try grass away from any path. Placement should reject it with a clear lane message. Try an intersection or corner with several adjacent path directions and press **R**; only valid directions should appear.
3. Start a wave. The machine should wait while its lane is empty, then fire three differently colored balls when an enemy enters. Watch their slightly different paths and bounces stay within the lane and stop before grass. The tower should keep its direction as enemies move.
4. Let several enemies enter one lane. A ball should damage each enemy once and continue to the next. Buy all three upgrades; Mk3 should fire four balls and Mk4 five, alongside their damage, cooldown, and speed changes.
5. Place a laser, tank, lightning, and water rocket tower to check their targeting and previews still work.

Run `Godot --headless --path . --script res://tests/test_gumball_tower.gd` for the focused lane, placement, shot, and upgrade checks.
