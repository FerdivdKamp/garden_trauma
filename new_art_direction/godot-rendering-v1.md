# Garden Defense — V1: Rendering, Lighting & Camera

**Goal:** Make the current garden recognizably closer to the approved sunny toy-diorama reference while preserving current tile meshes, navigation and tower/enemy behavior. **This milestone is about global presentation, not creating detailed new environment assets.**

**Dependencies:** `art-direction.md` and `garden_level_1_visual_reference.png`.

## PR V1.1 — Baseline and evaluation scene

- [ ] Record Godot version, chosen renderer (Forward+, Mobile, Compatibility), resolution and current camera settings.
- [ ] Duplicate or create a small reproducible `art_test_garden` scene using existing assets, path, grass, robot and laser tower; do not disturb shipping/test level.
- [ ] Fix two or three useful camera viewpoints: full gameplay, path detail, tower/robot closeup. Store screenshots in docs or PR.
- [ ] Record baseline screenshots and frame rate (in editor and, if available, exported build).
- [ ] Ensure scene renders correctly in current project renderer, not just Forward+.

**Acceptance:** Any future change can be compared from the same framing and lighting.

## PR V1.2 — WorldEnvironment and sun

### Scene composition

Use a single clearly owned `WorldEnvironment` for the level (or shared environment resource attached to level scenes), plus one `DirectionalLight3D`. Avoid accidental multiple environments/lights when instancing scenes.

Recommended Godot editor starting points (tune against the reference, not arbitrary numeric targets):

1. Create/select **WorldEnvironment** → new **Environment** resource.
2. Set the background appropriate to the camera: **Color**/sky/clear-color based on the level's needs; ensure no distracting horizon.
3. Compare the supported tone mapper modes in the selected renderer (e.g. Filmic/ACES when exposed); choose the one that preserves saturated green without clipping warm dirt highlights.
4. Configure **Ambient Light / Reflected Light** to brighten toy undersides without flattening all contrast. When using sky contribution, ensure an appropriate sky source exists.
5. Add/tune one **DirectionalLight3D** at an angle that visibly casts shadows beneath robots and towers. Keep the sunlight moderately warm rather than orange.
6. Enable shadows; tune shadow softness, distance and bias to avoid acne, detached feet and dark blotches. Shadow control names and features differ by Godot renderer/version.
7. Start with **glow off**, fog off, and expensive global illumination off; selectively test only after baseline is satisfactory. Glow is not a substitute for attractive lighting.
8. Treat SSAO/SSIL/SDFGI as **optional and renderer-dependent** (Forward+ features may be unavailable on Mobile/Compatibility). Do not make them required for this milestone.

### Validation

- [ ] Grass stays vivid but does not turn fluorescent.
- [ ] Sand stays warm beige and retains texture/geometry detail in sunlight.
- [ ] Tower blues/red bands retain differentiation, including in shadow.
- [ ] Contact shadows make towers and robots appear grounded.
- [ ] No obvious jagged or detached shadows at the expected play zoom.
- [ ] Compare intended tablet/mobile rendering configuration where practical.

**Acceptance:** Existing assets show a clear improvement without replacing geometry or requiring GI features that aren't available in the target renderer.

## PR V1.3 — Camera and framing

**Design:** Orthographic Camera3D for gameplay; approximately 55–65° downward from horizontal as an initial exploration range, not a fixed specification. Godot Camera3D's `size` with orthographic projection is the **vertical view span**, so derive final framing from viewport aspect ratio and board extents.

- [ ] Keep a stable orthographic projection for the playable camera (or document why current long-lens perspective is superior).
- [ ] Test a bigger board with the actual HUD safe areas; do not use beauty-shot proportions as gameplay dimensions.
- [ ] Make enemy and tower size visually consistent at near and far board edges.
- [ ] Verify build/select actions work at both top and bottom screen edges.
- [ ] Respect the current screen aspect ratio. Test at 16:9 and a tablet-like aspect ratio (e.g. 4:3).
- [ ] Document current pitch, rotation, orthographic size, position/target and safe margin rules.
- [ ] Keep all interactive gameplay geometry sharp. Do **not** add camera-wide depth of field.

**Acceptance:** The player can identify enemies, towers and path on the whole level; no clipping, excessive empty border or undue field shrinkage.

## PR V1.4 — Global material review (small scope)

Focus on tuning existing imported materials or controlled Godot overrides, without destroying the Blender → glTF pipeline:

- [ ] Grass: slightly varied lush greens, matte finish, enough light response to show terrain depth.
- [ ] Path: warm sandy surface, less saturated than grass, low shine.
- [ ] Tower: toy-plastic body with moderate specular highlight and readable contrasting bands.
- [ ] Robot: wind-up-toy finish, clear face/key silhouette.
- [ ] Check imported normals, smoothing and double-sided foliage choices as needed.
- [ ] Decide whether tweaks should live in the Blender source, imported material, or Godot override; record decision to avoid losing fixes on reimport.

**Acceptance:** One material change cannot silently break future asset reimports.

## PR V1.5 — Finalize the reference baseline

- [ ] Create `rendering-notes.md` with final light, environment, camera, material settings and renderer limitations.
- [ ] Keep side-by-side before/after screenshots at identical camera viewpoints.
- [ ] Check whether UI overlays occlude important level content.
- [ ] Record approximate performance comparison and disabled optional effects.
- [ ] Sign off V1 before implementing height transitions in V2.

## Suggested order for Codex

First implement **V1.1 + V1.2** in one small PR if practical. Review a screenshot. Then do **V1.3**. Treat **V1.4** as a separate asset-pipeline-aware PR. Finish with **V1.5**.

### Ready-to-paste agent prompt

> Implement **Garden Defense V1.1 and V1.2** using `art-direction.md` and `godot-rendering-v1.md`. Inspect the current scene and renderer first. Add a reproducible art test view, configure a WorldEnvironment and single warm directional sun with soft readable shadows, preserve every gameplay mechanic and existing asset pipeline, and provide before/after screenshots. Prefer conservative, compatible settings; do not enable expensive postprocessing by default. Document settings and explain how to adjust them in the Godot editor. Do not proceed to V2 or remodel tiles.
