# Grass lip and sparse blades: V2.1 visual study

Open `grass_path_lip.tscn` and run it with **F6**. The scene builds a fixed 5 × 5 grass/path layout at runtime, including a straight section and an L bend. Set `show_lip` and `show_blades` on the root node before running to compare the two additions. The example does not change level data, routing, placement, or the production tile scenes.

| Same camera | Raised tiles only | Grass lip and sparse blades |
| --- | --- | --- |
| Whole sample | ![Raised tiles only](renders/01_raised_tiles_only.png) | ![Grass lip and sparse blades](renders/02_grass_lip_sparse_blades.png) |
| Closer view | ![Raised tiles only close](renders/03_raised_tiles_only_close.png) | ![Grass lip and sparse blades close](renders/04_grass_lip_sparse_blades_close.png) |

The grass cells are lifted 0.18 m relative to path cells. Each grass-facing path edge gets a roughly 0.1 m overhang, an exposed soil face, and a few small blade cards. The lip top reuses the imported `GrassTop` material, so its broad color samples the same world X/Z field as the grass tiles. Repeated strips and corner joins are still prototype geometry; this scene tests the visual direction, not a production mesh kit. In the close render the soil face is still rather straight, and the blade cards are deliberately sparse. A later art pass could sculpt the soil outline and tune blade scale/density.

To regenerate all four images with identical tiles and cameras, run:

```powershell
& 'C:\GameDesign\Godot\Godot_v4.7.2-stable_win64.exe' --path . --script res://tools/capture_grass_path_lip.gd
```

The capture requires a graphical renderer. The first two images show the whole sample; the second two zoom in on the bend. The baseline pair hides both lip and blades, preserving the same raised tile heights and tile variants.
