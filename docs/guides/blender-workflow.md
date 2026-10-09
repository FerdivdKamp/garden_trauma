# Blender asset workflow

Keep editable `.blend` files under `art/blender/`. Run the pipeline from the repository root to export a `.glb` and matching `.materials.json` under `assets/models/`, preserving the source's relative path:

```powershell
python tools/asset_pipeline.py export art/blender/environment/garden/tiles/tile_path.blend
```

Use `validate` in place of `export` to inspect a source without writing output. `python tools/asset_pipeline.py gui` opens the desktop interface. If Blender is not on `PATH`, pass `--blender-exe` with its installed executable path.

For supported procedural materials, the export manifest records shader settings. Set the GLB's Godot **Import Script** to `res://tools/godot_material_post_import.gd`; the script reads the manifest and rebuilds supported materials with `shaders/procedural_noise_color_ramp.gdshader`. Existing path and grass tile imports have this setting. Re-export after changing a `.blend`, then open Godot or reimport the GLB. Unsupported Blender node graphs keep the GLB material and may render differently.

Sand path tile tops use world-space procedural noise. Grass tile tops use a shared color field from `assets/textures/environment/garden/grass_color_noise.png`, sampled in world space so the pattern continues across neighboring tiles, including rotated variants. The grass shader also blends top normals toward vertical to soften the lighting facets from the mesh bumps. `tools/godot_material_post_import.gd` sets the grass color strength and normal blend for all three grass GLBs; reimport those GLBs after changing these settings.

This is a visual tiling change: the three grass meshes still occupy 2 m cells, but the imported `GrassTop` material samples a continuous 64 m color field using world X/Z. Rotating or changing a tile variant therefore does not restart the color pattern at its edge. The post-import script applies this mode only to `tile_grass*.glb`. It uses continuous world-space procedural noise for `tile_path*.glb`; other supported Blender materials use their mesh-local generated coordinates. The dressing GLBs sit above the grass and use their exported materials, so their placement and colors do not alter the ground shader. See [Level dressing](level-dressing.md) for the six Garden decorations and their density controls.

Regenerate the deterministic grass color field with `Godot --headless --path . --script res://tools/generate_grass_noise.gd`, then open the project to import the PNG. Its 64 m span covers the 40 m Garden without repeating the pattern. The image changes broad color only; the tile mesh and scattered tufts provide small-scale detail. To compare changes from the level camera, run `Godot --path . --script res://tools/render_grass_fix.gd`. It saves `.godot/grass_material_world_noise.png`.

The current path and grass tiles use GLB-backed scenes under `scenes/tiles/`. The blocked rock tile remains a placeholder. The older [pipeline plan](../roadmap/plans/asset-pipeline.md) and [import design](../roadmap/plans/blender-asset-import.md) describe the intended conventions and possible extensions; their proposed phases are not all implemented.

## Garden grass mesh variants

The Garden uses `tile_grass.blend`, `tile_grass2.blend`, and `tile_grass3.blend`. Exact copies of their original, rougher sources are in `art/blender/environment/garden/tiles/backups/`. The current sources have baked geometry: matching subdivision density, reduced height variation, and flat border normals. This lets the three variants meet without a square lighting seam while preserving small interior differences.

`tools/soften_grass_tile.py` records the one-time Blender conversion. It expects an original source with its Displace modifier, so restore a backup before rerunning it. Export the modified source with the normal pipeline command shown above. The fourth grass variant was removed; the grass scene now chooses from these three.
