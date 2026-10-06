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
python tools/asset_pipeline.py gui
```

The CLI and window use the same folder and export logic. This repository is itself
the Godot project, so the output is `assets/models/towers/toy_tank.glb`, without
the example's extra `game/` directory. The helper creates the matching output
folder during export. It replaces an existing `.glb` only after Blender finishes
writing a new file successfully.

Save each `.blend` directly in one of the four `art/blender/` category folders,
using a lowercase snake_case filename. To limit the exported objects, put them
in a Blender collection named `Export`. If there is no such collection, the
helper exports visible geometry, armatures, and empties from the active scene.
Cameras and lights are excluded. Check the result in Godot after export for
scale, orientation, materials, and animation as needed; the helper does not
correct the source asset.

---

# V2 — Asset validation and consistency

Once the basic workflow is being used, add checks that prevent common modelling/export problems.

This may be implemented as a Blender script, export helper, CI check, or combination thereof.

Do not implement V2 until the V1 conventions have been used enough to know which checks are actually useful.

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
