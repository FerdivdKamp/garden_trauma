# Garden camera and lighting baseline

The playable Garden 1 and Garden 2 maps are 20 × 20 cells. Each cell is 2 world units, so the board is 40 × 40 units. The first visual reference is a close view of a much smaller part of a garden; it is a color and lighting target, not the full gameplay framing.

## Camera

`scenes/tower_placement.tscn` owns the gameplay `Camera3D`. It uses **orthographic projection**, a **55° downward pitch**, no yaw, and a **43 unit vertical view span**. Its position is `(0, 28.56, 20)`, aimed at the board center `(0, 0, 0)`. With this pitch, the 40 unit board projects to roughly 32.8 vertical units. The remaining view space leaves room for the tile border and modest top and bottom margins. Orthographic projection keeps a tower's apparent size constant wherever it is placed on the board.

Godot calls the orthographic vertical span `Camera3D.size`. Increase `size` to zoom out; decrease it to zoom in. If the board dimensions change, recalculate this value from the board's projected height and the desired margin. Do not use camera distance to zoom an orthographic camera.

At 1600 × 900, the board fits with room for the right HUD, but the left palette overlaps some lower-left grass cells. At 1200 × 900, both HUD panels cover playable cells. This is a HUD layout limit; zooming the camera out enough to fit the board between the panels would make enemies and towers too small. The screenshots record the current tradeoff for a later responsive HUD pass.

## Lighting

`scenes/tower_placement.tscn` owns one `WorldEnvironment` and one `DirectionalLight3D`. The Environment resource is `scenes/garden_environment.tres` so the editor exposes the settings in one place. It uses a muted garden-green background, a cool-tinted ambient fill at energy `0.65`, and Filmic tone mapping. The sun points from `(-55°, -35°)`, has a mild warm tint and energy `1.3`, and casts softly blurred shadows. Glow, fog and GI are off. These settings target the project's **Mobile renderer** in Godot **4.7.2**.

The background color replaces the default gray outside the board. Ambient fill makes shaded toy surfaces legible, while the sun's shadows help ground the towers and robots. The current grass and path materials still dominate the final color and texture; further convergence with the concept image belongs to the material and environment art passes.

## Repeatable check

Run `tools/capture_garden_frame.gd` with a graphical Godot process to save two fixed gameplay frames. It places two laser towers and one robot so the camera and lighting can be reviewed against actual game pieces. Headless Godot uses a dummy renderer and cannot capture these images.

- [16:9 gameplay frame](garden_camera_16_9.png)
- [4:3 gameplay frame](garden_camera_4_3.png)

In the editor, open `scenes/tower_placement.tscn` and press **F6** to test placement and tower selection. Check both the near and far sides of the board after any camera change.
