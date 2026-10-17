# Task: Stylized Stepping Stone Shader & Texture Baking

Create a Blender 5.2 Python workflow for four existing stepping stone meshes, modeled using Bisect.

starting point = rock_bisect.blend a blend file with 4 rocks in it.

## Goal

Produce a stylized stone material featuring:
- Muted blue-gray stone colors with subtle procedural variation.
- Light highlights along convex edges, emphasizing the low-poly facets.
- Darker crevices and concave areas.
- Subtle surface roughness, without excessive noise.
- A matte, slightly softened appearance suitable for a cartoon-style tower defense game.

## 1. Shader generation

Create `create_stone_shader.py` using Blender's `bpy` API.

- Create a material named `MAT_StylizedStone`.
- Build an organized, readable shader node graph with labeled frames:
  - **Base Color:** Noise Texture → Color Ramp with three gray-blue colors.
  - **Edge Highlights:** Geometry Pointiness → Color Ramp → mix with lighter stone color.
  - **Cavity Shading:** Ambient Occlusion → controlled darkening of recesses.
  - **Surface Detail:** Subtle Noise → Bump (strength ~0.1).
  - **Output:** Principled BSDF with roughness ~0.85.
- Use Cycles-compatible nodes where required.
- Include an Emission-based output path for baking the combined color.
- Make edge intensity, AO strength, and stone colors easy to adjust.
- Assign the material to the four selected stone meshes.
- Preserve the original geometry and existing UVs.

Important: Pointiness is geometry-dependent and may require testing or a fallback curvature-mask technique for low-poly meshes. Do not assume it produces the same appearance as Blender's viewport Cavity option.

## 2. Texture baking

Create a separate `bake_stone_textures.py` script.

For each stone:

1. Verify UVs; generate a Smart UV Project only if necessary.
2. Create a 512×512 image named `<object_name>_albedo`.
3. Switch to Cycles and bake the combined procedural color using **Emit**.
4. Save PNG files to `textures/stepping_stones/`.
5. Restore the original material output connections after baking.
6. Report successful and failed bakes.

Ensure each stone is baked independently, without other selected meshes interfering.

## 3. Blender deliverables

- Both Python scripts, runnable from Blender's Scripting workspace.
- A `.blend` file containing the four stones and their editable shader nodes.
- Saved PNG textures.
- Brief `README.md` explaining:
  - How to run each script.
  - How to adjust colors, edge highlights and cavity intensity.
  - How to preview before baking.
  - How to rebake after material changes.
  - How to export the assets to Godot using GLB.

## 4. Export considerations

The final exported material must use a conventional Principled BSDF with the baked albedo image connected to Base Color.

Keep the procedural source material intact for future editing.

Do not assume Blender-specific Pointiness, AO, or Noise nodes will export to Godot.

## Acceptance criteria

- [ ] Four stones share the same editable procedural shader.
- [ ] Edge highlights and crevices are visible in rendered preview.
- [ ] Shader node graph is clearly organized and labeled.
- [ ] Baking produces four distinct PNG textures.
- [ ] Baked texture closely matches the procedural color appearance.
- [ ] A GLB exported from Blender displays the baked colors in Godot.
- [ ] Scripts can be rerun without duplicating materials or nodes.