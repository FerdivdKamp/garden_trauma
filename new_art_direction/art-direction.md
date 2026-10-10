# Garden Defense — Art Direction

**Status:** Direction approved; implementation iterative  
**Primary visual reference:** `garden_level_1_visual_reference.png` (first approved garden concept)  
**Audience:** Developer, Blender artist, and coding agents  
**Scope:** Garden biome first; future environments should inherit the same toy-world language.

## Vision

> A whimsical tabletop toy world: a miniature garden invaded by quirky wind-up robots and defended by chunky retro plastic ray-gun towers. The scene should feel lush, sunny, tactile, and handcrafted, while remaining as readable as a clean orthographic strategy game.

**The reference is a LOOK target, not a layout or camera framing requirement.** The playable field must be substantially larger than the reference composition. The reference is also denser in plants than gameplay should be.

## Non-negotiable visual principles

1. **Gameplay readability over illustration.** Paths, buildable tiles, enemies, towers, selection states, and projectiles are instantly distinguishable at the normal gameplay zoom.
2. **Joyful miniature garden.** Fresh warm greens, golden sand, small clovers, flowers, pebbles, and occasional large-scale garden props.
3. **Toy material language.** Rounded bevels, prominent color blocking, plastic and painted-metal surfaces, slightly oversized proportions.
4. **Soft, warm afternoon sun.** Gentle ambient fill and grounded shadows. Avoid excessive glow, contrast, or blown-out highlights.
5. **Reusable and procedurally placeable.** Most scene dressing comes from small asset families with deterministic placement and controlled random variation.
6. **Visual depth without gameplay blur.** Larger border props and optional soft foreground foliage frame the image; the playfield stays sharp.

## Palette and materials

The image is the color authority. The hex values below are **initial approximations to tune in-engine**, not exact measurements sampled from the image.

| Category | Working colors | Material character |
|---|---|---|
| Grass base | `#76B940`, `#8BC84D` | Matte, rich green, restrained variation |
| Grass shadow / foliage | `#477D35`, `#5A993C` | Slightly darker for depth |
| Sandy path | `#DAB77E`, `#E4C78B` | Warm and dry; mostly matte |
| Exposed soil at edges | `#93704A`, `#A68055` | Earthy contrast at grass height transitions |
| Garden stones | `#A8A6A1`, `#C3BDB0` | Warm neutral gray, low shine |
| Laser tower | Deep toy blue + red accents | Smooth molded plastic, modest sheen |
| Wind-up enemies | Green bodies + warm red and brass details | Painted metal / toy plastic |
| Flowers | White/yellow dominant, occasional blue | Small accents; avoid blanket coverage |

Material intent: organic terrain mostly rough; manufactured toys less rough, but never mirror-shiny. Prefer strong silhouette/color separation over fine texture detail.

## Shapes and scales

- Ground tiles currently use **2 × 2 world units**; keep footprint fixed.
- Towers: large recognizable silhouettes, chunky bodies, rounded edges and clear turret/barrel components.
- Robots: simple readable boxy bodies with oversized wind-up keys, distinct face/eye area, expressive movement.
- Dressing: cluster by type; leave open grass pockets for clean tower placement and combat.
- Border props: fence slats, flowerpots, bricks, garden tools, larger leaves and rocks. Place mainly **outside** the playable build grid.

## Camera and composition

- Prefer **orthographic projection** for gameplay; consistent object scale at top and bottom of frame is critical.
- Begin with camera pitch roughly **55–65° down from horizontal**; compare with existing camera before changing.
- Keep the complete gameplay playfield sharp; avoid strong depth of field over interactive tiles.
- Decorative border should frame rather than occupy the game view.
- Foreground leaves may overlap the **non-interactive frame** but must not block towers, enemies, paths or UI.
- The first concept image is a close-in beauty shot. Actual gameplay should expose a noticeably larger board.

## Terrain rules

- Grass has a visually higher top surface than the path. Start by testing **grass top Y = +0.15 or +0.20**, path Y = 0 (relative to shared grid reference).
- Never modify logical grid positions, enemy routing or tower placement rules merely to implement the height difference.
- Join neighboring surfaces using explicit reusable visual edge/corner meshes, not cracks or exposed black voids.
- No visible seams or harsh lighting discontinuities between rotated/randomized tiles.
- Sand should clearly read as walkable path; grass as buildable terrain.

## Lighting rules

- One sun-like directional key light, soft shadow appearance, modest warm tint.
- Ambient fill avoids black undersides, especially on robots and towers.
- Shadow contact should clearly ground enemies and towers.
- Avoid heavy saturation/contrast, overblown yellow highlights, strong bloom and aggressive vignette.
- Prioritize consistent appearance in the project's *actual renderer* and at intended tablet resolution.

## UI and effects

- UI should eventually feel like a toy-game control panel, not a debug overlay; rounded panels, restrained accents, touch-friendly targets.
- Gameplay effects should use clear, short-lived shapes: laser flash, energy hit, toy-like impact and upgrade cues.
- Do not cover the board with persistent effects or opaque selection/range circles.

## Do / don't

**Do:** Save before/after screenshots from the *same* camera; iterate in small steps; use reusable assets; test all three tower types against grass and sand; check bright and shadowed areas.

**Don't:** Replicate the concept's dense vegetation everywhere; hide gameplay under blur; alter tile dimensions; add expensive GI indiscriminately; introduce one-off level-specific art hacks into the grid logic; replace functioning tower/enemy materials without validation.

## Versioned art-direction milestones

### V1 — Rendering and camera baseline

- [ ] Make the existing garden look closer to the approved reference **without rebuilding tiles**.
- [ ] Establish a shared WorldEnvironment/sun setup and optional quality presets.
- [ ] Produce repeatable camera screenshots and log working light/environment values.

Implementation tasks: see `godot-rendering-v1.md`.

### V2 — Raised grass and recessed path

- [ ] Keep existing logical 2 × 2 tiles but expose a small height change in visuals.
- [ ] Auto-select edge/corner transitions from tile neighbors.
- [ ] Prevent visible seams, z-fighting, tower floating, and dressing clipping.

Implementation tasks: see `tile-height-transitions-v2.md`.

### V3 — Diorama frame and authored dressing

- [ ] Add a border decoration layer independent from the gameplay grid.
- [ ] Model/assemble a small reusable garden-frame kit (fence, flowerpot, bricks, rocks, leaves).
- [ ] Keep frame objects outside playable/selectable areas and out of HUD sightlines.
- [ ] Add deterministic placement variation and an explicit manual override for level designers.
- [ ] Prototype optional foreground foliage; test with and without blur.

### V4 — Presentation polish and reuse

- [ ] Common toy-plastic, painted-metal, soil and foliage materials/presets.
- [ ] Themed UI and VFX consistent with reference.
- [ ] Performance/quality presets, including tablet testing.
- [ ] Extend biome system to sandbox/shed while preserving recognizable art language.

## Agent working agreement

- Read this file plus the version-specific implementation file before starting.
- Keep changes focused: **one milestone or reviewable subtask per PR**.
- Explain key Godot nodes, resources, shaders and reasoning in comments/docs so the developer can learn from the changes.
- Favor editor-inspectable scene/resources over opaque script-generated settings.
- Do not replace currently working level generation, tile reroll, tower placement or enemy navigation.
- Attach before/after gameplay screenshots, note performance impact, and document manual editor steps.
