# Blender asset workflow

Keep editable `.blend` files under `art/blender/`. Run the pipeline from the repository root to export a `.glb` and matching `.materials.json` under `assets/models/`, preserving the source's relative path:

```powershell
python tools/asset_pipeline.py export art/blender/environment/garden/tiles/tile_path.blend
```

Use `validate` in place of `export` to inspect a source without writing output. `python tools/asset_pipeline.py gui` opens the desktop interface. If Blender is not on `PATH`, pass `--blender-exe` with its installed executable path.

For supported procedural materials, the export manifest records shader settings. Set the GLB's Godot **Import Script** to `res://tools/godot_material_post_import.gd`; the script reads the manifest and rebuilds supported materials with `shaders/procedural_noise_color_ramp.gdshader`. Existing path and grass tile imports have this setting. Re-export after changing a `.blend`, then open Godot or reimport the GLB. Unsupported Blender node graphs keep the GLB material and may render differently.

Sand path tile tops use world-space procedural noise. Grass tile tops use a shared color field from `assets/textures/environment/garden/grass_color_noise.png`, sampled in world space so the pattern continues across neighboring tiles, including rotated variants. The grass shader also blends top normals toward vertical to soften the lighting facets from the mesh bumps. `tools/godot_material_post_import.gd` sets the grass color strength and normal blend for all three grass GLBs; reimport those GLBs after changing these settings.

This is a visual tiling change: the three grass meshes still occupy 2 m cells, but the imported `GrassTop` material samples a continuous 64 m color field using world X/Z. Rotating or changing a tile variant therefore does not restart the color pattern at its edge. The post-import script applies this mode to `tile_grass*.glb` and the three border GLBs. It uses continuous world-space procedural noise for `tile_path*.glb`; other supported Blender materials use their mesh-local generated coordinates. The dressing GLBs sit above the grass and use their exported materials, so their placement and colors do not alter the ground shader. See [Level dressing](level-dressing.md) for the six Garden decorations and their density controls.

Regenerate the deterministic grass color field with `Godot --headless --path . --script res://tools/generate_grass_noise.gd`, then open the project to import the PNG. Its 64 m span covers the 40 m Garden without repeating the pattern. The image changes broad color only; the tile mesh and scattered tufts provide small-scale detail. To compare changes from the level camera, run `Godot --path . --script res://tools/render_grass_fix.gd`. It saves `.godot/grass_material_world_noise.png`.

The current path and grass tiles use GLB-backed scenes under `scenes/tiles/`. The blocked rock tile remains a placeholder. The older [pipeline plan](../roadmap/plans/asset-pipeline.md) and [import design](../roadmap/plans/blender-asset-import.md) describe the intended conventions and possible extensions; their proposed phases are not all implemented.

## Garden border prototypes

`art/blender/environment/garden/tiles/garden_borders.blend` keeps the three organic border pieces in one editable file. Its `Border Export` scene has one object at the tile origin in each collection: `border_straight_1`, `corner_outer_1`, and `corner_inner_1`. The other scenes are layout references. Export one piece at a time with `--collection` and a matching `--output-name`:

```powershell
python tools/asset_pipeline.py export art/blender/environment/garden/tiles/garden_borders.blend --blender-exe "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --collection border_straight_1 --output-name border_straight_1
python tools/asset_pipeline.py export art/blender/environment/garden/tiles/garden_borders.blend --blender-exe "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --collection corner_outer_1 --output-name corner_outer_1
python tools/asset_pipeline.py export art/blender/environment/garden/tiles/garden_borders.blend --blender-exe "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --collection corner_inner_1 --output-name corner_inner_1
```

The exported meshes have `UVMap` for ordinary texture use. The current Godot grass material instead samples world position, so the border GLBs also need the normal post-import script to receive the shared grass color field. Each export object has a `FixedJoins` group for selecting every edge vertex that must meet another tile, plus a `VariationMask` group that fades from zero at those joins to full influence inside. Blender's proportional editing does not obey vertex-group locks: hide the full `FixedJoins` selection before editing, or use `VariationMask` with a vertex-group-aware modifier for guaranteed fixed joins. Restore hidden vertices before export.

After changing the post-import script, explicitly reimport the border GLBs in Godot. The editor can keep a cached import made with older shader settings even when the `.glb` and manifest have not changed. `tests/test_asset_material_import.gd` checks the imported border materials for the shared world-space grass field.

The Garden grid now reads surrounding grass cells when it creates each path tile. The lowered `tile_path.blend` is exported as `tile_path.glb`, and `PathTileVisual` always uses that one sand mesh for now. The border pieces are visual children of path tiles; the route and buildable cells still come from the level JSON. One path tile owns each piece, so changing a level's tile symbols and reloading rebuilds the borders.

| Grass relative to a path cell | Border piece | Base direction |
| --- | --- | --- |
| One cardinal side | `border_straight_1` | West |
| Two adjacent cardinal sides | `corner_outer_1` | West + north |
| Diagonal only, with both adjacent sides path | `corner_inner_1` | Southeast |

The script rotates these base directions in quarter turns and puts each piece at the path tile's authored center. On a one-cell-wide path, two opposing straight pieces are mirrored across the sand. Map edges and blocked cells do not count as grass. `PlacementPath` still supplies the enemy route, but its old flat beige `Surface` is hidden in `tower_placement.tscn`; otherwise it sits above the imported geometry and makes the entire path look square. Inspect the result at play zoom after changing mesh heights or making wider variations in Blender.

## Tower pivot template

`art/blender/towers/laser_tower.blend` contains four laser tower collections. Export each collection to its own GLB:

```powershell
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
python tools/asset_pipeline.py export art/blender/towers/laser_tower.blend --blender-exe $blender --collection tower_laser_mk1 --output-name laser_tower
python tools/asset_pipeline.py export art/blender/towers/laser_tower.blend --blender-exe $blender --collection tower_laser_mk2 --output-name laser_tower_mk2
python tools/asset_pipeline.py export art/blender/towers/laser_tower.blend --blender-exe $blender --collection tower_laser_mk3 --output-name laser_tower_mk3
python tools/asset_pipeline.py export art/blender/towers/laser_tower.blend --blender-exe $blender --collection tower_laser_mk4 --output-name laser_tower_mk4
```

`scenes/tower_visual.tscn` contains mk1 so it is visible in the editor. `scripts/tower_visual.gd` swaps to mk2, mk3, then mk4 after each purchase. The explicit `--collection` option includes models hidden in Blender while another version is being edited. Keep the base mesh at the origin, place a yaw empty at the turret's turning center, nest a pitch empty at the gun's hinge, and put a muzzle empty at the barrel tip in each collection. The script uses those imported pivots directly for aiming and shot origins. Future towers can follow this hierarchy, but each should get its own definition and scene wiring when its model is added.

The scales are applied in the current source. Blender still reports one generic material name; renaming it would make later edits easier to inspect.

## Wind-up robot enemy

`art/blender/units/robot.blend` is the editable source for the first enemy. Export it with:

```powershell
python tools/asset_pipeline.py export art/blender/units/robot.blend --blender-exe "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
```

`scenes/placement_enemy.tscn` instances the resulting `assets/models/units/robot.glb`. Its Blender empties import as Godot `Node3D` pivots. `scripts/placement_enemy.gd` rotates the arms, legs, head, antenna, and wind-up key while the robot moves. This is a temporary motion pass; replace it with Blender animations when those are ready. Keep the pivot names if the Godot script still uses them.

The eyes point along the model's local `-X` axis. The enemy scene rotates only the imported Robot node 90 degrees around Y so its eyes align with `PathFollow3D`'s local `-Z` forward direction, and scales that node to four times the imported size. The arms and legs swing around their local `Z` axes, which run sideways through their pivots. Keep the scene rotation when re-exporting the current Blender source; if a future source faces local `-Z`, remove the scene rotation.

The second enemy still uses the blue sphere placeholder. The robot and sphere share the same `Visual` parent so the existing visual scale control works for both.

## Garden grass mesh variants

The Garden uses `tile_grass.blend`, `tile_grass2.blend`, and `tile_grass3.blend`. Exact copies of their original, rougher sources are in `art/blender/environment/garden/tiles/backups/`. The current sources have baked geometry: matching subdivision density, reduced height variation, and flat border normals. This lets the three variants meet without a square lighting seam while preserving small interior differences.

`tools/soften_grass_tile.py` records the one-time Blender conversion. It expects an original source with its Displace modifier, so restore a backup before rerunning it. Export the modified source with the normal pipeline command shown above. The fourth grass variant was removed; the grass scene now chooses from these three.
