# Asset pipeline plan

!!! note "Planning reference"
    This document includes older proposed paths and phases. Use the [Blender asset workflow](../../guides/blender-workflow.md) for current export instructions and [Current status](../index.md) for implemented work.

## Goal

Establish a simple, documented and repeatable workflow for creating 3D assets in Blender and importing them into Godot.

The first version should optimize for simplicity rather than trying to solve every asset-validation problem immediately.

The intended flow is:

```text
Blender source (.blend)
        ↓
     export
        ↓
   glTF Binary (.glb)
        ↓
 Godot asset directory
        ↓
 Godot imported scene
```

## V1 — Basic Blender → Godot workflow

### 1. Standardize the source and export locations

Keep Blender source files separate from game-ready assets.

Suggested structure:

```text
art/
├─ blender/
│  ├─ towers/
│  ├─ units/
│  ├─ props/
│  └─ environment/
│
game/
└─ assets/
   └─ models/
      ├─ towers/
      ├─ units/
      ├─ props/
      └─ environment/
```

Example:

```text
art/blender/towers/toy_tank.blend
```

exports to:

```text
game/assets/models/towers/toy_tank.glb
```

Adjust these paths to match the existing repository structure if needed.

The important principle is:

```text
.blend = editable source asset
.glb   = game-ready interchange asset
```

### 2. Use `.glb` as the standard interchange format

Use **glTF 2.0 Binary (`.glb`)** for assets exported from Blender to Godot.

Reasons:

- supported directly by Blender and Godot
- one exported file instead of `.gltf + .bin + textures`
- supports meshes
- supports PBR materials and textures
- supports armatures and animation when needed later
- keeps the Blender/Godot boundary explicit

Do not make direct `.blend` importing the default pipeline.

### 3. Establish basic asset conventions

For V1, document a small number of rules.

#### Naming

Use lowercase `snake_case`.

Examples:

```text
toy_tank.blend
toy_tank.glb
wind_up_robot.blend
wind_up_robot.glb
```

Objects inside Blender should also have meaningful names rather than defaults such as:

```text
Cube
Cube.001
Material.003
```

Prefer:

```text
toy_tank_body
toy_tank_turret
toy_tank_wheels
```

### 4. Coordinate and transform conventions

Before export, an asset should have sensible transforms.

At minimum:

- intended scale is correct
- object origin is intentionally placed
- unwanted translation/rotation/scale is not accidentally baked into the asset
- the object appears upright and at the expected size after import into Godot

For ordinary placeable units/towers, prefer an origin near the logical placement point, usually:

```text
bottom centre of the object
```

This makes placing the asset on terrain predictable.

Document the project's expected real-world scale.

For example:

```text
1 Blender unit ≈ 1 Godot metre
```

Do not try to automatically fix transforms in V1.

### 5. Basic Blender export instructions

Document a known-working export configuration using:

```text
File
→ Export
→ glTF 2.0
→ Format: glTF Binary (.glb)
```

Avoid exporting unnecessary Blender-only objects such as:

- modelling reference objects
- hidden experiments
- cameras
- lights

unless the particular asset actually requires them.

Prefer exporting the intended object/collection rather than the entire Blender workspace.

### 6. Verify Godot import

Add one simple test asset.

For example:

```text
test_cube.blend
        ↓
test_cube.glb
        ↓
Godot
```

Or use one of the first actual toy assets.

Verify that:

- Godot automatically imports the `.glb`
- the mesh renders
- its orientation is correct
- its scale is sensible
- materials appear roughly as expected
- it can be instantiated inside a Godot scene

### 7. Document the workflow

Add a short developer/artist document, for example:

```text
docs/asset_pipeline.md
```

It should explain:

```text
1. Create/edit asset in Blender
2. Save .blend under art/blender/...
3. Export .glb to game/assets/models/...
4. Open/reimport asset in Godot
5. Instantiate the imported scene
```

The document should be written for someone learning Blender/Godot and should include enough explanation to understand why both `.blend` and `.glb` exist.

## V1 acceptance criteria

- `.glb` is documented as the normal Blender → Godot interchange format.
- Source and exported asset locations are defined.
- Naming conventions are documented.
- Scale/origin expectations are documented.
- At least one Blender asset successfully completes the pipeline.
- The exported `.glb` can be instantiated in Godot.
- Basic export steps are documented.
- The process does not require custom tooling.

### Optional asset helper

`tools/asset_pipeline.py` adds folder setup and export commands, plus a small desktop
window. Python 3 is required; the window uses Tkinter from the standard library.
Blender must be on `PATH`, or its executable must be selected in the window or
passed with `--blender-exe`. Run these commands from the repository root:

```powershell
python tools/asset_pipeline.py init
python tools/asset_pipeline.py init --blender
python tools/asset_pipeline.py init --godot
python tools/asset_pipeline.py export art/blender/towers/toy_tank.blend
python tools/asset_pipeline.py validate art/blender/environment/garden/tiles/tile_grass4.blend
python tools/asset_pipeline.py gui
```

The CLI and window use the same folder and export logic. This repository is itself
the Godot project, so the output is `assets/models/towers/toy_tank.glb`, without
the example's extra `game/` directory. The helper creates the matching output
folder during export. It replaces an existing `.glb` only after Blender finishes
writing a new file successfully.

Save each `.blend` in one of the four `art/blender/` category folders or a
subfolder beneath one, using a lowercase snake_case filename. Subfolders are
mirrored under `assets/models/`; for example,
`art/blender/environment/garden/tiles/tile_grass4.blend` exports to
`assets/models/environment/garden/tiles/tile_grass4.glb`. To limit the exported
objects, put them in a Blender collection named `Export`. If there is no such collection, the
helper exports visible geometry, armatures, and empties from the active scene.
Cameras and lights are excluded. Check the result in Godot after export for
scale, orientation, materials, and animation as needed; the helper does not
correct the source asset.
Validation runs before export and can also run alone using `validate` or the
window's **Validate asset** button. It checks generic object and material names,
mesh geometry, material presence, unapplied scale, and procedural nodes. Tile
dimensions use faces assigned to a material ending in `Sides`, or vertical side
faces when no such material exists. Bumps and dips in the top surface do not
affect the expected `2 x 2 x 0.25` metres. Missing side faces produce a warning
because their dimensions cannot be checked.
Warnings allow export; errors such as a mesh with no usable faces stop it.
Neither command changes the `.blend` file.

V3 also inspects the connected material graph during validation and export.
For each GLB, export writes a matching sidecar such as
`assets/models/environment/garden/tiles/tile_grass4.materials.json`.
The JSON lists materials by name and classifies them as `directly_exportable`,
`translatable`, or `unsupported`. A direct material is a Principled BSDF linked
to Material Output with constant Base Color, Metallic, Roughness, and Alpha.
The supported procedural pattern is Generated coordinates (or an unlinked
Vector input) → Noise Texture Factor → Color Ramp Color → Principled Base Color.
Its noise settings, ramp colors and positions, and Principled values are stored
as raw Blender values for later Godot translation. Other connected graphs are
marked `unsupported` with a reason. They still get the normal GLB export, but
their Blender appearance may not survive. `validate` reports classifications
without writing a sidecar; V3 does not create Godot shaders or materials.

V4 uses `res://tools/godot_material_post_import.gd` as the GLB's Import Script.
The `tile_grass4.glb.import` file already points to it. For another GLB, set
**Import → Import Script → Path** to that script and reimport. The script reads
the matching `.materials.json`, creates a `ShaderMaterial` on each supported
surface, and uses the shared
`res://shaders/procedural_noise_color_ramp.gdshader`. It stores the generated
material inside Godot's imported scene, so reimporting replaces its parameters
without creating separate material files. Materials marked unsupported or
directly exportable keep their GLB material.

The shader approximates Blender's 3D Noise Texture with a two-stop linear RGB
Color Ramp. It transfers Blender's ramp colors and positions, noise scale,
detail, roughness, lacunarity and distortion, plus Principled roughness and
metallic. It currently accepts opaque colors and up to eight noise octaves.
Other ramp shapes and
transparent materials keep their GLB fallback and produce a warning during
import. The noise pattern is intentionally approximate; inspect the tile in
Godot and adjust the Blender source when its artistic intent changes.
Open `res://examples/grass_material_preview.tscn` and run that scene to view
the imported tile under a light.

---

# V2 — Asset validation and consistency

The helper now runs validation before export and supports a validate-only command.
The checks below are possible later additions to that initial validation.

## Candidate V2 checks

### Mesh checks

Check for problems such as:

- unapplied scale
- unexpected rotations
- invalid or degenerate geometry
- non-manifold geometry where relevant
- duplicate/unmerged vertices where relevant
- accidentally extreme polygon counts
- missing or incorrect normals

Do not automatically modify artist source unless explicitly requested.

Report problems clearly instead.

### UV validation

For textured assets, detect:

- missing UV map
- obviously invalid UV setup
- unexpected multiple UV maps

Do not require UVs for assets that only use simple materials and genuinely do not need them.

### Materials

Establish basic material conventions.

Prefer Blender materials that translate cleanly through glTF, primarily using:

```text
Principled BSDF
```

Potential checks:

- material has a meaningful name
- unsupported/procedural Blender-only shaders are not relied upon
- texture references exist
- unexpectedly large textures are reported

Godot's glTF import supports material and UV information, while procedural Blender material setups may not translate directly, so keeping the handoff relatively standard helps avoid surprises.

### Texture conventions

Potential future convention:

```text
asset_name_basecolor.png
asset_name_normal.png
asset_name_roughness.png
asset_name_metallic.png
```

Do not introduce this convention until textured assets actually require it.

### Animation

When animated units are introduced, extend the pipeline with checks for:

- armature exists
- animation names are meaningful
- animation ranges are correct
- required animations exist

Possible convention:

```text
idle
walk
attack
hit
death
```

Blender's glTF exporter supports keyframe, shape-key and skeletal animation, so `.glb` can remain the pipeline format when animation is introduced.

### Suggested animation contract

A unit may eventually be expected to provide:

```text
idle
move
attack
death
```

But do not require this for static assets.

### Collision

Decide later whether collision should originate from:

```text
Blender
```

or be generated/defined in:

```text
Godot
```

For the initial tower-defense assets, prefer keeping gameplay collision separate from detailed rendering geometry.

For example:

```text
ToyTank.glb
    ↓
ToyTank.tscn
├─ imported visual model
├─ simple collision
├─ gameplay scripts
└─ effects
```

This avoids making rendering meshes dictate gameplay behaviour.

### Automated export

Investigate adding an export script or Blender collection exporter so that an artist can perform something similar to:

```text
Export Game Asset
```

rather than manually choosing settings each time.

The script should use the same directory and naming conventions established in V1.

---

# Longer-term architecture

Keep a distinction between source artwork, imported artwork, and gameplay scenes.

Prefer:

```text
Blender
   │
   │  visual asset
   ▼
toy_tank.glb
   │
   ▼
ToyTankVisual
   │
   ▼
ToyTank.tscn
├─ visual model
├─ targeting
├─ collision
├─ shooting logic
└─ effects
```

rather than adding substantial Godot-specific gameplay structure inside Blender.

Blender owns the **visual asset**.

Godot owns the **game object**.
