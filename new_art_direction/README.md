# Garden Defense — Garden Visual Refresh

This documentation set translates the **first approved garden concept** into an incremental agent-friendly implementation plan.

## Files

- [`art-direction.md`](art-direction.md) — visual identity, colors, materials, camera and V1–V4 roadmap.
- [`godot-rendering-v1.md`](godot-rendering-v1.md) — V1 tasks for Godot lighting, environment, camera and material baseline.
- [`tile-height-transitions-v2.md`](tile-height-transitions-v2.md) — V2 tasks for elevated grass, recessed paths, edge mesh kits and neighbor-aware generation.
- [`garden_level_1_visual_reference.png`](garden_level_1_visual_reference.png) — approved image; reference for color, lighting and feel **not** gameplay viewport size.

## Recommended sequence

1. V1.1–V1.2: test scene, WorldEnvironment, warm sunlight and readable soft shadows.
2. V1.3: orthographic camera and larger board framing.
3. V1.4–V1.5: material cleanup and sign-off screenshots.
4. V2.1: hand-built transitions test scene.
5. V2.2: grid-neighbor-driven transitions.
6. V2.3–V2.4: tower/enemy/dressing integration and polish.
7. V3: diorama border and limited soft foreground framing.

**Instruction to agents:** Read the art-direction guide and the relevant milestone file; implement one reviewable PR at a time. Stop for visual review at V1.2 and V2.1.
