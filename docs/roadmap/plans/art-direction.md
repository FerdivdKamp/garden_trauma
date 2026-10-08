# Art Direction

## Goal

Create a **stylized, cartoony 3D tower defense game** with a playful toy-diorama feel.

The game should feel colorful, readable, and deliberately exaggerated without depending on a heavy comic-book or anime look. The visual identity should come primarily from:

- Strong silhouettes
- Exaggerated proportions
- Simple, readable materials
- Clear color separation
- Soft, appealing lighting
- Toy-like scale and forms
- Strong gameplay readability

Cel shading is **optional**, not a requirement.

---

## Core Direction

The preferred baseline is:

> **Stylized 3D with simple materials and soft lighting, optionally enhanced later with light toon shading.**

Avoid committing early to:

- Heavy black outlines
- Extreme two-tone cel shading
- Highly realistic PBR materials
- Detailed hand-painted textures
- Photorealistic environments

The art style should remain easy to produce for a small project where assets are created by one developer with help from agents and procedural tooling.

---

## Visual Theme

The world should resemble a child's imaginative version of familiar places.

Example environments:

- Garden
- Shed
- Sandpit
- Patio
- Bedroom
- Garage

Towers and enemies are inspired by toys, household objects, and exaggerated imaginary machines.

Examples:

- Plastic robot
- Toy tank
- Wind-up dog
- Laser cannon
- Lightning tower
- Wooden fort
- Plastic soldiers
- Toy vehicles

The physical environment should feel believable enough to recognize, but exaggerated enough to support the fantasy.

---

# Style Principles

## 1. Silhouette First

Assets should be recognizable from a distance.

Prefer:

- Large shapes
- Oversized weapons
- Chunky wheels
- Thick limbs
- Large heads
- Strong profiles
- Simplified details

Avoid relying on small surface detail for identity.

A unit should ideally remain recognizable when shown as a solid black silhouette.

---

## 2. Exaggerated Proportions

Real-world proportions are not the target.

Examples:

- Tank barrel larger than realistic
- Robot hands oversized
- Wheels slightly too large
- Towers wider at the base
- Antennas thicker than realistic
- Buttons and switches oversized

Exaggeration should improve readability and personality.

---

## 3. Simple Materials

Materials should communicate what an object is made from without aiming for realism.

Useful material families:

- Plastic
- Painted metal
- Rubber
- Wood
- Fabric
- Grass
- Sand
- Stone

Keep material graphs simple.

Prefer differences in:

- Base color
- Roughness
- Metallic value
- Normal intensity

rather than complex texture sets.

---

## 4. Color

Use clear, readable colors.

Gameplay objects should contrast with the environment.

Example approach:

### Environment

Slightly softer and more natural:

- Grass green
- Soil brown
- Sand beige
- Wooden shed tones
- Muted stone

### Towers and units

More saturated and toy-like:

- Bright red
- Toy blue
- Yellow
- Green
- Orange
- Purple

Avoid making every object equally saturated.

Important gameplay objects should receive the strongest color contrast.

---

## 5. Lighting

The baseline should use stylized but conventional 3D lighting.

Initial target:

- One strong directional light
- Soft shadows
- Ambient/world lighting
- Moderate contrast
- Slightly warm, inviting appearance

Lighting should help identify:

- Shape
- Height
- Direction
- Unit separation

Avoid very dark shadows that hide gameplay information.

---

# Cel Shading

## Decision

**Do not require full cel shading for V1.**

Cartoony visuals do not require cel shading.

The visual identity should first come from:

- Modeling
- Proportions
- Color
- Materials
- Lighting

A shader should enhance a good art direction rather than compensate for an unclear one.

---

## Possible Toon Treatment

Later versions may experiment with **soft toon shading**.

Preferred approach:

- 3–4 broad lighting bands
- No heavy black outline by default
- Preserve material differences
- Keep some smoothness in specular highlights
- Maintain readable shadows

The intended feel is closer to:

> Stylized animated-film / Nintendo-like 3D

rather than:

> Heavy comic-book / Borderlands-style rendering

---

## Outlines

Outlines are optional.

If used, first test them only on:

- Towers
- Enemies
- Player-controlled units
- Important interactable objects

Do not automatically outline:

- Grass
- Terrain
- Background scenery
- Every environmental prop

Selective outlines may improve gameplay readability without making the whole scene visually noisy.

---

# Development Phases

## V1 — Stylized PBR Baseline

Goal:

Establish whether the game already looks appealing without custom toon rendering.

Implement:

- Simple geometry
- Flat or minimally textured materials
- Basic plastic/wood/metal material presets
- Directional lighting
- Soft shadows
- Simple environment lighting
- No outlines
- No custom toon shader

### Acceptance criteria

- [ ] Garden environment reads clearly
- [ ] Towers are recognizable from gameplay camera distance
- [ ] Enemies are recognizable from gameplay camera distance
- [ ] Materials distinguish plastic, wood, metal, grass, and sand
- [ ] Gameplay objects clearly stand out from terrain
- [ ] Scene looks intentionally stylized without relying on shaders

---

## V2 — Toon Lighting Experiment

Goal:

Test whether toon lighting improves the visual identity.

Create an optional Godot shader or material setup using approximately:

- 3 lighting bands initially
- Optional 4-band comparison
- Controlled specular highlights
- Existing base colors and material properties

### Acceptance criteria

- [ ] Same assets work without modification
- [ ] Shader can be enabled or disabled easily
- [ ] Gameplay remains readable
- [ ] Materials still feel different from one another
- [ ] Lighting does not produce distracting hard transitions
- [ ] Screenshots can be compared directly with V1

---

## V3 — Selective Outline Experiment

Goal:

Determine whether outlines improve gameplay readability.

Test outlines on:

- Tower
- Enemy
- Major interactable

Compare:

1. No outlines
2. Thin outlines on gameplay objects
3. Toon shading + thin outlines

### Acceptance criteria

- [ ] Outlines remain readable at gameplay camera distance
- [ ] Outlines do not dominate the image
- [ ] Environment remains mostly outline-free
- [ ] Performance impact is acceptable
- [ ] Objects are easier to identify, not merely more visually busy

---

## V4 — Final Art Direction Decision

Create one representative test scene containing:

- Grass tile
- Sand/path tile
- Small environmental prop
- One tower
- One enemy
- One larger decorative object

Capture matching screenshots using:

1. Stylized PBR
2. Soft toon shading
3. Soft toon shading + selective outlines

Select the final approach based on the actual game assets rather than theoretical preference.

Document the final decision in this file.

---

# Asset Creation Rules

## Blender

Assets should:

- Use clean, simple geometry
- Use sensible object names
- Apply transforms before export
- Use consistent scale
- Keep pivots useful for Godot
- Use simple material slots
- Avoid unnecessary topology
- Avoid excessive subdivision
- Prefer geometry that reads well at gameplay distance

Placeholder assets are acceptable.

A placeholder should still make its intended purpose obvious through:

- Shape
- Name
- Scale
- Color

Example:

`tower_lightning_placeholder.blend`

should visibly resemble a crude lightning-related tower rather than an unrelated cube.

---

# Texture Direction

Initially prefer:

- Solid colors
- Simple gradients
- Low-detail procedural textures
- Minimal decals

Avoid requiring unique high-resolution textures for every asset.

Textures should support shape rather than replace it.

Later texture additions may include:

- Toy scratches
- Sticker decals
- Mold seams
- Painted edges
- Dirt
- Small labels

These should remain secondary details.

---

# Environment Direction

The world should feel slightly oversized from the toys' perspective.

This allows normal objects to become landmarks.

Examples:

- Flower pot becomes a large obstacle
- Garden hose becomes terrain
- Wooden plank becomes a bridge
- Sandbox edge becomes a wall
- Watering can becomes scenery
- Pebbles become boulders

This scale contrast should reinforce the toy fantasy.

---

# Gameplay Readability

Gameplay readability takes priority over visual realism.

At normal gameplay zoom, the player should quickly distinguish:

- Friendly towers
- Enemies
- Enemy type
- Paths
- Buildable areas
- Attack effects
- Range indicators
- Interactable objects

Do not add visual effects merely because they look impressive.

Every effect should preserve or improve readability.

---

# Effects

Effects may use stronger stylization than the environment.

Examples:

### Lightning

- Bright segmented bolt
- Short-lived branches
- Strong flash
- Small impact particles

### Laser

- Clean beam
- Bright core
- Soft glow
- Minimal noise

### Projectile

- Slightly oversized
- Strong color
- Readable trail

Effects should match the toy-fantasy theme rather than realistic physics.

---

# Agent Guidance

When an agent creates or modifies art assets:

1. Preserve the stylized proportions.
2. Prefer readability over realism.
3. Do not introduce heavy texture complexity unless requested.
4. Do not introduce custom shaders unless the task specifically requires them.
5. Keep asset scale and naming consistent.
6. Make placeholders visually understandable.
7. Avoid changing the established art direction as part of unrelated tasks.
8. Keep toon shading optional until the V4 comparison is complete.

When uncertain, prefer:

> simple geometry + strong silhouette + clear color

over:

> additional detail + complex materials + realism

---

# Current Art Direction Decision

For now:

**Use stylized 3D with simple materials and conventional soft lighting.**

Cel shading is an experiment for a later phase rather than a foundation of the asset pipeline.

The likely long-term target is:

**Stylized toy-diorama visuals with optional soft toon lighting and selective outlines on gameplay objects.**
