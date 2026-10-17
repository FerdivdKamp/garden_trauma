# Grass material lab

Open `grass_material_lab.tscn` in Godot and press **F6**. The nine-by-nine tile
sample uses the Garden grass shader and a fixed tile arrangement, so visual
changes come from the controls rather than different tile placements.

- The scene opens with **Saved Garden** from `data/grass_material_settings.json`.
  The three earlier palettes remain available as starting points. Selecting a
  palette resets its grass colors and contrast in this scene.
- Move the **Dark**, **Middle**, and **Light** brightness sliders, or click their
  swatches to edit the full RGB colors. The hex values beside the swatches show
  the current colors.
- Adjust **Contrast** to widen or narrow the dark and light areas.
- Try a warm directional light at energy **1.0**. Compare a soft neutral ambient
  color with **Sky**, and switch between **Filmic** and **AgX** tonemapping.
- Keep **Metallic** near **0**, **Roughness** between **0.85** and **1.0**, and
  **Specular** low to moderate for a matte grass surface.

The scene duplicates the imported material and environment before changing
them. Press **Save to Garden config** to write the current colors, contrast,
lighting, and surface values to `data/grass_material_settings.json`. The
playable Garden reads this file when `LevelGrid` uses **Saved Garden**, its
default palette. **Copy summary** is optional and only writes to the clipboard.
The three older palette constants remain in `scripts/grass_palette.gd`.

Saving to `res://` is intended for development in the Godot editor. In an
exported game the project files are read-only, so this lab is a tuning tool
rather than an in-game settings menu.
