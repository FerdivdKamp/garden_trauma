# Blender asset workflow

Keep editable `.blend` files under `art/blender/`. Run the pipeline from the repository root to export a `.glb` and matching `.materials.json` under `assets/models/`, preserving the source's relative path:

```powershell
python tools/asset_pipeline.py export art/blender/environment/garden/tiles/tile_path.blend
```

Use `validate` in place of `export` to inspect a source without writing output. `python tools/asset_pipeline.py gui` opens the desktop interface. If Blender is not on `PATH`, pass `--blender-exe` with its installed executable path.

For supported procedural materials, the export manifest records shader settings. Set the GLB's Godot **Import Script** to `res://tools/godot_material_post_import.gd`; the script reads the manifest and rebuilds supported materials with `shaders/procedural_noise_color_ramp.gdshader`. Existing path and grass tile imports have this setting. Re-export after changing a `.blend`, then open Godot or reimport the GLB. Unsupported Blender node graphs keep the GLB material and may render differently.

The current path and grass tiles use GLB-backed scenes under `scenes/tiles/`. The blocked rock tile remains a placeholder. The older [pipeline plan](../roadmap/plans/asset-pipeline.md) and [import design](../roadmap/plans/blender-asset-import.md) describe the intended conventions and possible extensions; their proposed phases are not all implemented.
