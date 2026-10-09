# Level Designer – Procedural Tile Dressing and Manual Fine-Tuning

This document describes the intended level-design workflow for tile-based levels.

The goal is to combine predictable gameplay tiles, procedural visual variation, automatic edge dressing, deterministic generation, and manual designer control for final polish.

---

# Core idea

A gameplay tile should not directly define its final appearance.

Instead, the final visual result is composed from:

```text
logical tile type
+ visual mesh variant
+ rotation
+ dressing configuration
```

Example:

```text
logical tile: grass
mesh variant: grass_02
rotation: 90 degrees
dressing:
- grass_tuft_03 on north-east edge
- pebble_cluster_01 on south edge
- weed_01 near center-left
```

The logical tile remains unchanged. A reroll should therefore affect only the visual presentation unless the designer explicitly edits gameplay data.

---

# Design principles

## Gameplay and visuals are separate

Gameplay data determines things such as:

```text
grass
path
tower buildable
enemy path
blocked
spawn
goal
```

Visual generation determines things such as:

```text
mesh variant
rotation
grass tufts
pebbles
weeds
dirt clumps
edge pieces
decorative props
```

Changing a visual seed must never accidentally change pathing, buildability, tower placement rules, enemy navigation, or level logic.

---

# Deterministic generation

Procedural visuals should use deterministic random generation.

Do not use uncontrolled global randomness.

Each tile should have a seed such as:

```json
{
  "x": 5,
  "y": 3,
  "tile_type": "grass",
  "visual_seed": 18421
}
```

The same seed should always produce the same result.

The visual generator may derive from the seed:

```text
mesh variant
mesh rotation
dressing selection
dressing positions
dressing rotations
dressing scale variation
```

This allows repeatable level loads, easy rerolls, clean Git diffs, and procedural generation without losing designer control.

---

# Tile visual generation

Each logical tile type may define a visual set.

Example:

```text
grass:
- tile_grass_01
- tile_grass_02
- tile_grass_03

sand:
- tile_sand_01
- tile_sand_02
```

When generating a tile:

1. Read the logical tile type.
2. Read the tile's visual seed.
3. Choose a compatible mesh variant.
4. Choose a valid rotation.
5. Inspect neighboring tiles.
6. Determine valid dressing slots.
7. Choose dressing items.
8. Spawn the generated visual result.

---

# Rotation

Tile variants may be rotated in 90-degree increments when the mesh supports it.

```text
0
90
180
270
```

A single asymmetric mesh can therefore provide several visual variations.

Rotation must not change logical tile behavior.

---

# Dressing

Dressing is small decorative geometry placed on or near tiles.

Examples:

```text
grass_tuft_01
grass_tuft_02
grass_tuft_03
weed_01
clover_patch_01
sand_pebbles_01
sand_pebbles_02
grass_edge_clump_01
grass_edge_clump_02
small_rock_01
dry_grass_01
flower_patch_01
```

Dressing should be lightweight and reusable. Sparse decoration is preferred over visual noise.

---

# Dressing categories

Dressing should support categories so the generator knows where items make sense.

Suggested categories:

```text
CENTER
EDGE
CORNER
PATH_EDGE
GRASS_ONLY
SAND_ONLY
ANY_GROUND
LARGE_PROP
```

An asset may belong to more than one category.

Example:

```text
grass_tuft_01:
- GRASS_ONLY
- CENTER
- EDGE
```

Example:

```text
grass_edge_clump_01:
- PATH_EDGE
- EDGE
```

---

# Neighbor-aware generation

The dressing generator should inspect neighboring tiles before placing edge dressing.

Example tile:

```text
north = sand
east  = grass
south = grass
west  = sand
```

For a grass tile:

```text
north edge = grass/sand transition
west edge = grass/sand transition
east edge = grass/grass
south edge = grass/grass
```

Only north and west are eligible for path-edge dressing.

Possible generated props:

```text
grass_edge_clump
small_stones
weed_strip
dirt_overlap
```

This allows path borders to look organic without requiring special grass-with-path-border tiles.

---

# No dedicated transition tiles in V1

Do not create separate gameplay tiles such as:

```text
grass_with_sand_north
grass_with_sand_corner
grass_with_sand_t_junction
```

The logical tile system should remain simple.

Visual transitions are handled by dressing.

This avoids a combinatorial explosion of tile types.

---

# Dressing slots

To avoid completely arbitrary placement, each tile may expose predefined dressing slots.

Example:

```text
CENTER
NORTH
NORTH_EAST
EAST
SOUTH_EAST
SOUTH
SOUTH_WEST
WEST
NORTH_WEST
```

A generated tile may choose from these slots.

Small random offsets may be applied within a safe range.

This keeps dressing visually controlled and prevents props from drifting into inappropriate areas.

---

# Manual level designer workflow

The level designer should allow procedural generation to be manually fine-tuned.

Suggested interaction:

```text
Hover tile
Space = reroll visual configuration
```

Rerolling a tile should generate a new visual seed.

Example:

```text
visual_seed: 18421
```

becomes:

```text
visual_seed: 59302
```

The logical tile stays unchanged.

---

# Suggested controls

Initial controls:

```text
Mouse hover / select
    select tile

Space
    reroll visual seed

Shift + Space
    reroll dressing only

R
    reroll mesh variant / rotation only

L
    lock or unlock tile visuals

Delete
    clear manual visual override

Ctrl + R
    reroll all unlocked tiles
```

Exact bindings may change later. The important part is the workflow.

---

# Hover feedback

When hovering a tile in the level designer, show a clear highlight.

Optionally display a small debug panel:

```text
Tile: (5, 3)
Type: grass
Variant: grass_02
Rotation: 90
Visual seed: 18421
Locked: yes
Dressing:
- grass_tuft_03
- weed_01
```

---

# Generated state vs manual overrides

The system should distinguish between automatically generated state and designer overrides.

Basic tile state:

```json
{
  "x": 5,
  "y": 3,
  "tile_type": "grass",
  "visual_seed": 18421,
  "locked": false
}
```

A manually finalized tile might become:

```json
{
  "x": 5,
  "y": 3,
  "tile_type": "grass",
  "visual_seed": 18421,
  "locked": true
}
```

A full-level reroll should skip locked tiles.

---

# Optional explicit overrides

Later versions may allow partial overrides.

Example:

```json
{
  "visual_seed": 18421,
  "locked": true,
  "override": {
    "mesh_variant": "grass_03",
    "rotation": 180,
    "dressing": [
      {
        "asset": "grass_tuft_02",
        "slot": "NORTH_EAST"
      }
    ]
  }
}
```

Do not require explicit override data in V1. A seed plus lock state is enough initially.

---

# Whole-level generation

The level designer should support:

```text
Generate visuals
```

or:

```text
Reroll unlocked visuals
```

For every unlocked tile:

1. Generate a new seed.
2. Select mesh variant.
3. Select rotation.
4. Inspect neighbors.
5. Generate dressing.
6. Refresh visuals.

Locked tiles remain untouched.

---

# Seed hierarchy

A level may also have a global visual seed.

Example:

```json
{
  "level_seed": 42017
}
```

Tile seeds may initially be derived from:

```text
level_seed
+ tile coordinates
```

Example concept:

```text
tile_seed = hash(level_seed, x, y)
```

A manual reroll stores a tile-specific override seed.

This gives useful behavior:

```text
No tile override:
    derive from level seed

Tile rerolled:
    use stored tile visual seed
```

That makes whole-level generation deterministic while still allowing local edits.

---

# Large props

Large level props should be treated differently from tiny tile dressing.

Examples:

```text
flower pot
toy bucket
garden stone
wooden border
watering can
garden chair leg
sandbox toy
```

These may occupy part of one tile, an entire tile, or multiple tiles.

Large props should generally be designer-controlled rather than fully random. Procedural generation may suggest locations later, but V1 should focus on small dressing.

---

# Collision

Small dressing should generally not affect gameplay collision.

Examples:

```text
grass tufts
small weeds
pebbles
tiny stones
small dirt clumps
```

should be visual-only.

Do not let cosmetic dressing interfere with enemy navigation, tower placement, click selection, or projectiles.

Large props may have collision where appropriate.

---

# Performance

Do not create excessive scene complexity.

Dressing assets should be small and lightweight.

Possible later optimization:

```text
MultiMeshInstance3D
```

for repeated grass, stones, flowers, or similar props.

Do not optimize prematurely. V1 may use regular scene instances if performance is acceptable.

---

# Asset metadata

Dressing assets should eventually describe where they are valid.

Example conceptual metadata:

```json
{
  "id": "grass_edge_clump_01",
  "categories": [
    "GRASS_ONLY",
    "PATH_EDGE"
  ],
  "weight": 1.0,
  "allowed_rotations": [
    0,
    90,
    180,
    270
  ]
}
```

Possible later fields:

```text
spawn weight
minimum spacing
maximum per tile
allowed biome
allowed tile types
edge requirements
scale range
rotation range
```

Keep V1 simpler.

---

# V1 – Tile variant generation

## Goal

Randomly select visual variants without changing gameplay.

Implement:

- tile visual seed
- mesh variant selection
- 90-degree rotation
- deterministic results

Example asset sets:

```text
grass:
- grass_01
- grass_02
- grass_03

sand:
- sand_01
- sand_02
```

## Acceptance criteria

- [ ] Same seed gives same visual result.
- [ ] Different seed can choose a different variant.
- [ ] Rotation can vary.
- [ ] Gameplay tile type does not change.
- [ ] Level reload reproduces visuals.

---

# V2 – Basic dressing

## Goal

Add small procedural props to tiles.

Implement a small initial library:

```text
grass_tuft_01
grass_tuft_02
grass_tuft_03
pebbles_01
pebbles_02
```

Use predefined dressing slots.

## Acceptance criteria

- [ ] Dressing is deterministic.
- [ ] Dressing uses predefined valid positions.
- [ ] Density is configurable.
- [ ] Dressing does not affect gameplay collision.
- [ ] Grass and sand may have different dressing pools.

---

# V3 – Neighbor-aware edge dressing

## Goal

Automatically dress transitions between tile types.

Implement neighbor inspection for:

```text
north
east
south
west
```

Optionally add diagonals later.

Initial transition:

```text
grass <-> sand
```

Example assets:

```text
grass_edge_clump_01
grass_edge_clump_02
small_path_stones_01
```

## Acceptance criteria

- [ ] Edge dressing only appears on valid transitions.
- [ ] Grass/grass edges do not receive path-edge dressing.
- [ ] Sand/sand edges do not receive grass transition dressing.
- [ ] Corners can receive appropriate dressing.
- [ ] Result remains deterministic.

---

# V4 – Level designer reroll interaction

## Goal

Allow visual fine-tuning inside a level-design scene.

Implement:

```text
hover/select tile
Space -> reroll tile
L -> lock tile
```

Optional:

```text
Shift + Space -> dressing only
R -> mesh variant only
```

## Acceptance criteria

- [ ] Hovered tile is clearly highlighted.
- [ ] Reroll changes only visual state.
- [ ] Locked tiles survive whole-level rerolls.
- [ ] Tile state is saved.
- [ ] Reload reproduces the edited result.

---

# V5 – Whole-level workflow

## Goal

Make procedural visuals useful for authoring complete levels.

Implement:

```text
Generate all visuals
Reroll all unlocked
Lock selected
Unlock selected
```

Optional debug view:

```text
show tile coordinates
show visual seeds
show locked state
show tile type
```

## Acceptance criteria

- [ ] A whole level can be visually generated in one action.
- [ ] Individual ugly tiles can be rerolled.
- [ ] Good-looking tiles can be locked.
- [ ] A subsequent whole-level reroll preserves locked tiles.
- [ ] Saved level data remains compact and readable.

---

# V6 – Manual overrides

## Goal

Allow designers to explicitly place or replace dressing.

Possible tools:

```text
add dressing
remove dressing
move dressing
rotate dressing
replace dressing
force mesh variant
```

The level designer should only add this complexity when procedural rerolling is no longer enough.

---

# Recommended first implementation

Start with the existing grass and sand tiles.

For V1:

```text
grass variants:
- current grass tile
- duplicate with different internal top geometry
- optional third variant later

sand variants:
- current sand tile
- one alternate
```

Then implement deterministic variant and rotation selection.

After that, create:

```text
grass_tuft_01
grass_tuft_02
grass_tuft_03
pebbles_01
pebbles_02
grass_edge_clump_01
grass_edge_clump_02
```

These are enough to implement V2 and V3.

Do not build a large dressing library before the generation workflow has been tested in the actual level.

---

# Example authoring workflow

A designer creates the gameplay layout:

```text
GGGGGGGGGG
GSSSSSSSSG
GGGGGGGGSG
GGGGGGGGSG
GGGGGGGGSG
```

Where:

```text
G = grass
S = sand/path
```

The visual generator turns this into:

```text
different grass variants
different sand variants
random rotations
sparse grass tufts
small pebble groups
grass clumps along the grass/sand boundary
```

The designer inspects the result.

One tile looks bad:

```text
hover tile
press Space
```

The tile rerolls.

A tile now looks particularly good:

```text
press L
```

The tile is locked.

The designer can then reroll the rest of the level without losing that result.

---

# Guiding principle

The procedural system should do the repetitive 80% of level dressing.

The designer should spend time on the interesting 20%.

The target workflow is:

```text
Design gameplay layout
        ↓
Generate visuals automatically
        ↓
Inspect
        ↓
Reroll awkward tiles
        ↓
Lock good tiles
        ↓
Add a few intentional large props
        ↓
Finished level
```

The procedural system is not intended to replace level design. It is intended to make manual level design faster and more visually varied.
