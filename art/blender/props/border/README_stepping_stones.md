# Stepping stone material

`rock_bisect.blend` is the untouched modeling source. `rock_stylized.blend` holds
four original stone meshes with one shared, editable `MAT_StylizedStone` material.
Its **Baked Export** collection contains four mesh copies with conventional image
materials for Godot.

## Build and preview

1. Open `rock_bisect.blend` in Blender 5.2. In the Scripting workspace, open
   `tools/create_stone_shader.py` from the project root and run it. This saves
   `rock_stylized.blend` beside the source. Running it again refreshes the same
   material without adding duplicate nodes.
2. In `rock_stylized.blend`, switch the viewport to **Rendered** and set the
   render engine to **Cycles**. Pointiness and Ambient Occlusion are Cycles
   effects; Material Preview is not a reliable comparison. Add a light if the
   scene is too dark to inspect.
3. Change the three `Three stone colors` ramp stops for the palette. Change
   the `Edge intensity` math node's second value to adjust the edge highlight.
   Change `Cavity intensity` → **To Min** to adjust recess darkening: lower
   values make crevices darker. The `Subtle bump` Strength controls fine grain.
   Pointiness depends on mesh topology, so inspect the rendered result after
   changing stone geometry. It does not copy Blender's viewport Cavity effect.
4. Open `tools/bake_stone_textures.py` in the Scripting workspace and run it.
   It reports `BAKED` or `FAILED` for each stone and saves 512 px PNGs under
   `textures/stepping_stones/`. Rerun this script after material changes. It
   preserves the source shader and refreshes the **Baked Export** collection.

The bake temporarily connects the color graph to an Emission node and uses
Cycles **Emit** baking. This records the procedural albedo, including the edge
and cavity masks, without adding scene lighting to the texture. Fine bump is
left for Blender preview only; the Godot material uses the baked color and
roughness 0.85. The existing UVs are retained; Smart UV Project runs only if a
stone has no usable UV layer.

## Godot export

The bake script also exports `assets/models/props/border/rock_stylized.glb`
from the **Baked Export** collection. Each export material has an Image Texture
connected to a Principled BSDF Base Color socket. The GLB embeds the PNG data,
so Godot can import it without interpreting Pointiness, AO, or Noise nodes.
Open the GLB as a scene in Godot to inspect all four stones. To export manually,
unhide the **Baked Export** collection, select its four stones, and use
**File → Export → glTF 2.0**, format **glTF Binary (.glb)** with **Selected
Objects** enabled.
