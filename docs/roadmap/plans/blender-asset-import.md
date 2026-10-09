# Blender Asset Import Pipeline

This document describes the staged pipeline for moving Blender assets into Godot.

The goal is to keep the workflow simple at first, then add validation and material translation in later versions. Each version should be implementable as a separate PR.

The pipeline should favor predictable, boring imports over clever automation.

---

# Goals

- Keep `.blend` files as the editable source assets.
- Export game-ready assets to `.glb`.
- Keep scale, transforms, pivots, materials, and naming predictable.
- Make exported assets easy to use from Godot.
- Add validation before adding complex automation.
- Support a small, explicit subset of Blender materials rather than attempting to translate arbitrary Blender shader graphs.
- Produce useful warnings instead of silently exporting broken assets.

---

# General conventions

## Scale

Use:

```text
1 Blender unit = 1 Godot unit = 1 meter
```

For the current tile system:

```text
Tile side dimensions:
X = 2.0 m
Y = 2.0 m
Z = 0.25 m
```

Measure these dimensions from the tile's side and bottom faces. The top surface
may have bumps and dips outside the side height.

## Transforms

Before export:

```text
Location: asset-dependent
Rotation: 0, 0, 0 where practical
Scale:    1, 1, 1
```

Apply object scale before export:

```text
Ctrl+A -> Scale
```

Do not fix incorrect scale by compensating for it in Godot.

## Coordinate systems

The exporter must account for Blender/Godot coordinate differences through glTF rather than custom manual rotations where possible.

Avoid adding unexplained 90-degree rotations to source objects merely to make imports appear correct.

## Source and generated files

Recommended structure:

```text
assets/
├── blender/
│   ├── environment/
│   ├── towers/
│   └── enemies/
│
└── game/
    ├── environment/
    ├── towers/
    └── enemies/
```

Example:

```text
assets/blender/environment/garden/tile_grass.blend
assets/game/environment/garden/tile_grass.glb
```

Generated `.glb` files should not replace the `.blend` source.

---

# V1 - Basic Blender to GLB export

## Objective

Create the smallest reliable Blender-to-Godot pipeline.

No shader translation yet.

## Requirements

Create a Python export script that:

- Opens or runs from a Blender file.
- Exports selected/exportable objects to `.glb`.
- Uses glTF 2.0 / GLB.
- Preserves:
  - mesh geometry
  - object hierarchy
  - object names
  - material slots
  - basic Principled BSDF values
- Uses meters consistently.
- Does not export cameras or lights unless explicitly requested.
- Produces a clear output path.
- Logs what was exported.

Example output:

```text
Exporting: tile_grass.blend
Objects: 1
Materials: GrassTop, GrassSides
Output: assets/game/environment/garden/tile_grass.glb
Export complete.
```

## V1 material behavior

Only rely on material properties that glTF handles naturally.

For example:

```text
Principled BSDF
- Base Color
- Metallic
- Roughness
- Alpha
```

Procedural nodes may remain in the `.blend`, but V1 does not attempt to reproduce them in Godot.

If the Blender material uses:

```text
Noise Texture -> Color Ramp -> Principled BSDF Base Color
```

the procedural effect is allowed to be lost during V1 export.

The exported material should still have a sensible fallback base color.

## V1 acceptance criteria

- [x] A Blender cube exports as a valid `.glb`.
- [ ] The asset imports into Godot without manual rotation or rescaling.
- [ ] A tile's `2 x 2 x 0.25` side dimensions are preserved in Godot.
- [x] Object names remain recognizable.
- [x] Material slots remain recognizable.
- [ ] Basic base color, metallic, and roughness survive export.
- [x] Export can be repeated without manual cleanup.
- [x] Errors result in a non-zero exit code when run from the command line.

---

# V2 - Asset validation

## Objective

Catch common asset mistakes before export.

The exporter should fail early for errors and warn for suspicious but valid assets.

## Validation checks

### Object transforms

Warn or fail when:

```text
Scale != 1,1,1
```

Optional warning:

```text
Rotation != 0,0,0
```

Do not automatically apply transforms without an explicit option.

### Naming

Validate predictable naming.

Examples:

```text
tile_grass
tile_path
tower_double_tank
enemy_windup_robot
```

Avoid names such as:

```text
Cube
Cube.001
Cylinder.003
Material.001
```

Internal helper objects may use a documented prefix such as:

```text
_HELPER_
```

or:

```text
COL_
```

### Dimensions

Allow optional asset-specific checks.

For example, tile sides must be:

```text
2.0 x 2.0 x 0.25
```

within a small tolerance. Prefer faces assigned to a material whose name ends
in `Sides`; when there is no such material, use vertical side faces. Do not use
the entire mesh's bounding box for the height check.

### Mesh sanity

Check for:

- missing meshes
- zero-area geometry where detectable
- unapplied non-uniform scale
- missing material slots
- obviously invalid dimensions
- duplicate object names

Possible later checks:

- non-manifold geometry
- flipped normals
- degenerate faces

## Output

Validation output should be readable both by humans and agents.

Example:

```text
[OK] tile_grass dimensions: 2.0 x 2.0 x 0.25
[OK] scale applied
[OK] 2 materials found
[WARN] Material GrassTop contains unsupported procedural nodes
[OK] export allowed
```

## V2 acceptance criteria

- [x] Invalid tile dimensions are detected.
- [x] Unapplied scale is detected.
- [x] Generic Blender names can be flagged.
- [x] Unsupported shader nodes produce warnings.
- [x] Validation runs before export.
- [x] The exporter clearly distinguishes warnings from errors.
- [x] Validation can run without exporting.

Suggested CLI:

```bash
python tools/asset_pipeline.py validate art/blender/environment/garden/tiles/tile_grass3.blend
python tools/asset_pipeline.py export art/blender/environment/garden/tiles/tile_grass3.blend
```

Pass `--blender-exe` after the source path when Blender is not on `PATH`.

---

# V3 - Material inspection

## Objective

Inspect Blender shader graphs and classify materials as either:

1. directly exportable
2. translatable
3. unsupported

Do not generate Godot shaders yet.

## Supported material vocabulary

Start deliberately small.

### Direct/basic material

```text
Principled BSDF -> Material Output
```

Supported inputs:

```text
Base Color
Metallic
Roughness
Alpha
```

### First procedural material pattern

Support recognition of:

```text
Texture Coordinate
    ↓
Noise Texture
    ↓
Color Ramp
    ↓
Principled BSDF Base Color
```

`Texture Coordinate` may initially be optional.

The important data to extract is:

```text
Noise Texture:
- dimensions/type if relevant
- scale
- detail
- roughness
- lacunarity
- distortion

Color Ramp:
- interpolation mode
- ramp element positions
- colors

Principled BSDF:
- roughness
- metallic
- alpha
```

## Example

For the grass tile:

```text
Material: GrassTop

Pattern:
Generated Coordinates
    -> Noise Texture
    -> Color Ramp
    -> Principled BSDF Base Color

Classification:
SUPPORTED_PROCEDURAL_NOISE_COLOR_RAMP
```

## Material manifest

Generate a machine-readable sidecar file.

Example:

```json
{
  "schema_version": 1,
  "asset": "tile_grass3",
  "materials": [
    {
      "name": "GrassTop",
      "classification": "translatable",
      "type": "procedural_noise_color_ramp",
      "noise": {
        "scale": 3.0,
        "detail": 2.0,
        "roughness": 0.5
      },
      "color_ramp": {
        "elements": [
          {
            "position": 0.0,
            "color": [0.25, 0.45, 0.12, 1.0]
          },
          {
            "position": 1.0,
            "color": [0.45, 0.68, 0.20, 1.0]
          }
        ]
      },
      "principled": {
        "roughness": 0.7,
        "metallic": 0.0
      }
    }
  ]
}
```

Exact schema may evolve.

## Unsupported nodes

Do not guess.

Example:

```text
[WARN] GrassTop contains unsupported node:
Voronoi Texture

Material will use fallback GLB material.
```

## V3 acceptance criteria

- [x] Material graphs can be inspected programmatically.
- [x] The simple Noise -> Color Ramp pattern is recognized.
- [x] Relevant values are extracted.
- [x] A material manifest is generated.
- [x] Unknown graphs are reported rather than silently misinterpreted.
- [x] Basic GLB export still works if translation is unsupported.

---

# V4 - Godot material translation

## Objective

Translate the supported Blender procedural material subset into Godot materials.

This is not intended to reproduce Blender rendering pixel-for-pixel.

The goal is to preserve artistic intent.

Example:

```text
Blender intent:
"Large soft variation between two grass greens."

Godot result:
"Large soft variation between the same two grass greens."
```

Exact noise output does not need to match Blender.

## Grass shader example

A generated Godot shader may conceptually look like:

```glsl
shader_type spatial;

uniform vec4 color_a : source_color;
uniform vec4 color_b : source_color;
uniform float noise_scale = 3.0;
uniform float roughness_value = 0.7;

void fragment() {
    float n = procedural_noise(VERTEX.xz * noise_scale);
    ALBEDO = mix(color_a.rgb, color_b.rgb, n);
    ROUGHNESS = roughness_value;
}
```

The actual noise implementation should be shared rather than copied into every asset if practical.

## Prefer shared shader templates

Do not generate a unique shader program for every grass tile.

Prefer:

```text
res://shaders/procedural_noise_color_ramp.gdshader
```

with generated or configured `ShaderMaterial` parameters.

Example material instance:

```text
GrassTop.material
    shader = procedural_noise_color_ramp.gdshader
    color_a = ...
    color_b = ...
    noise_scale = 3.0
    roughness = 0.7
```

This allows multiple assets to reuse one shader.

## Import result

The importer may create something like:

```text
tile_grass.glb
tile_grass.materials.json
```

Then a Godot-side import/setup script reads the metadata and creates or updates:

```text
res://assets/generated/materials/grass_top.tres
```

Exact layout can be decided during implementation.

## V4 acceptance criteria

- [x] `GrassTop` is detected as a supported procedural material.
- [x] Blender colors are transferred to Godot.
- [x] Noise scale is transferred.
- [x] Roughness is transferred.
- [x] The generated Godot asset uses a shared shader template.
- [x] Reimporting updates parameters rather than creating duplicates.
- [x] Unsupported materials continue using their GLB fallback.
- [x] No pixel-perfect Blender/Godot match is required.

---

# V5 - Expanded material support

Only add new node patterns when an actual asset needs them.

Possible additions:

```text
Mapping
Texture Coordinate
Image Texture
Multiply/Mix
Normal Map
Bump
Emission
Alpha Clip
```

Do not implement nodes merely because Blender supports them.

Each supported pattern should have:

- a clear Blender-side convention
- validation
- extraction code
- a corresponding Godot implementation
- a test asset
- documentation

Avoid attempting a generic Blender-to-Godot shader compiler.

---

# V6 - Production asset pipeline

Possible later improvements:

- batch export multiple `.blend` files
- incremental export based on modified files
- CI validation
- generated import report
- collision mesh conventions
- LOD support
- animation validation
- skeleton validation
- socket / marker export
- tower pivot validation
- enemy forward-direction validation
- automatic preview thumbnails
- asset metadata
- export profiles per asset type

Possible command:

```bash
python tools/assets.py validate-all
python tools/assets.py export-all
```

The Python wrapper may launch Blender in background mode internally.

---

# Recommended implementation order

Implement this in separate PR-sized steps.

## PR 1 - Basic export

- [x] Export `.blend` -> `.glb`.
- [x] Define output paths.
- [ ] Verify scale in Godot.
- [x] Ignore cameras/lights.
- [x] Log export summary.

## PR 2 - Validation

- [x] Check dimensions.
- [x] Check applied scale.
- [x] Check names.
- [x] Check material presence.
- [x] Add warnings/errors.
- [x] Add validate-only command.

## PR 3 - Material inspection

- [x] Inspect Blender material nodes.
- [x] Recognize basic Principled materials.
- [x] Recognize Noise -> Color Ramp -> Principled.
- [x] Export a material manifest.
- [x] Warn for unsupported graphs.

## PR 4 - Godot shader translation

- [x] Create shared Godot procedural shader.
- [x] Read exported material metadata.
- [x] Create/update Godot material resources.
- [x] Apply translated materials to imported assets.
- [x] Test with `tile_grass`.

## PR 5 - Pipeline hardening

- [ ] Re-import is deterministic.
- [ ] No duplicate generated resources.
- [ ] Good error messages.
- [x] Automated test assets.
- [ ] Document supported material graph patterns.

---

# First reference asset

Use the grass tile as the reference asset for the pipeline.

Expected Blender source:

```text
tile_grass
Side dimensions: 2 x 2 x 0.25 (top surface may vary)
```

Materials:

```text
GrassTop
GrassSides
```

`GrassTop` may contain:

```text
Texture Coordinate
    ↓
Noise Texture
    ↓
Color Ramp
    ↓
Principled BSDF
    ↓
Material Output
```

`GrassSides` should initially be a simple Principled material.

This gives the pipeline both:

- one simple material
- one procedural material

without making the first test asset unnecessarily complicated.

---

# Design principle

The exporter should not attempt to understand arbitrary Blender art.

Instead, the project defines a small set of asset conventions that both Blender and Godot understand.

In other words:

```text
Blender is the authoring tool.
GLB carries geometry.
The export metadata carries intent.
Godot owns the runtime material.
```

That separation should keep the asset pipeline understandable, testable, and maintainable as the project grows.
