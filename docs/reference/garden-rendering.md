# Garden camera and lighting baseline

The playable Garden 1 and Garden 2 maps are 20 × 20 cells. Each cell is 2 world units, so the board is 40 × 40 units. The first visual reference is a close view of a much smaller part of a garden; it is a color and lighting target, not the full gameplay framing.

## Camera

`scenes/tower_placement.tscn` owns the gameplay `Camera3D`. It uses **perspective projection**, a **55° downward pitch**, no yaw, and a **35° vertical field of view**. Its position is `(0, 57.34, 40.15)`, about 70 units from the board center `(0, 0, 0)`. This distant, narrow-field view keeps the full board readable while giving the side fences and toys visible depth. Near tiles appear somewhat larger than far tiles.

With a perspective camera, `Camera3D.fov` and distance both affect framing. Move the camera along its viewing direction to adjust size while keeping its aim on the board center; changing FOV also changes how strongly near and far objects differ in size. Placement uses `project_ray_origin()` and `project_ray_normal()`, so its ground-plane ray works with either projection.

At 1600 × 900 and 1200 × 900, the whole fence remains visible. The left palette still overlaps some lower-left grass cells, especially at 4:3. This is a HUD layout limit; zooming out enough to clear it would make enemies and towers too small. The screenshots record the current tradeoff for a later responsive HUD pass.

## Lighting

`scenes/tower_placement.tscn` owns one `WorldEnvironment` and one `DirectionalLight3D`. The Environment resource is `scenes/garden_environment.tres` so the editor exposes the settings in one place. It uses a muted garden-green background, a cool-tinted ambient fill at energy `0.65`, and Filmic tone mapping. The sun points from `(-55°, -35°)`, has a mild warm tint and energy `1.3`, and casts softly blurred shadows. Glow, fog and GI are off. These settings target the project's **Mobile renderer** in Godot **4.7.2**.

The background color replaces the default gray outside the board. Ambient fill makes shaded toy surfaces legible, while the sun's shadows help ground the towers and robots. The current grass and path materials still dominate the final color and texture; further convergence with the concept image belongs to the material and environment art passes.

## Grass material pass

Garden grass tops and border pieces share a world-space color field and a small
two-scale color/roughness grain in `shaders/procedural_noise_color_ramp.gdshader`.
World coordinates keep both layers continuous when a tile variant rotates. The
import script gives all six grass/border GLBs the same matte base material.
`LevelGrid` then applies the chosen colors to its own material copies, including
grass along the sand path. This leaves another grid's materials untouched.
The material changes surface color; it does not add physical blades or change
the separate dressing objects.

For live experiments, open `examples/grass_material_lab.tscn` and run it with
**F6**. It exposes all three grass colors, contrast, sun color and energy,
ambient lighting, Filmic/AgX tonemapping, and the grass surface response.
**Save to Garden config** writes these values to
`data/grass_material_settings.json`; the playable Garden uses that file with
the **Saved Garden** palette.

The [Current backup](grass_material_task11_gameplay.png),
[Summer late afternoon](grass_material_summer_gameplay.png),
[Preview green](grass_material_preview_green_gameplay.png),
[Saved Garden](grass_material_saved_garden_gameplay.png), and
[close view of the base texture](grass_material_task11_close.png) images were captured
under the Mobile renderer. To switch, select `LevelGrid` in
`scenes/tower_placement.tscn`, change **Grass Palette** in the Inspector, and
run the scene with **F6**. **Saved Garden** is the default; **Current**,
**Summer late afternoon**, and **Preview green** remain selectable. Each of
the three earlier presets has **Dark**, **Middle**, and **Light** colors in
`scripts/grass_palette.gd`. The shader blends dark to middle across the lower
half of the shared color field, then middle to light across the upper half.
The initial middle colors were chosen to preserve the earlier two-color looks
as closely as possible. Change the three colors independently to tune the
shadows, main lawn color, and highlights; **Contrast** still controls the
spread of the color field. A palette
change needs no GLB reimport. Only changes
to the shared grain, normals, or matte finish in
`tools/godot_material_post_import.gd` require reimporting the six GLBs.

## Repeatable check

Run `tools/capture_garden_frame.gd` with a graphical Godot process to save two fixed gameplay frames. It places two laser towers and one robot so the camera and lighting can be reviewed against actual game pieces. Headless Godot uses a dummy renderer and cannot capture these images.

- [16:9 gameplay frame](garden_camera_16_9.png)
- [4:3 gameplay frame](garden_camera_4_3.png)

In the editor, open `scenes/tower_placement.tscn` and press **F6** to test placement and tower selection. Check both the near and far sides of the board after any camera change.
