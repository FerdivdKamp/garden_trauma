# Garden Trauma — Menu & UI Theme Plan

This document defines a small, incremental visual pass for the game UI. It is intentionally split into bite-sized tasks so an agent can implement one step at a time without redesigning the whole interface at once.

The goal is to move the UI from functional prototype styling toward a coherent toy-box / garden aesthetic while keeping the underlying screens and game flow simple.

---

## 1. Visual Direction

The UI should feel like it belongs to a stylized toy-based tower defense game.

Target feeling:

- playful rather than sleek
- chunky rather than minimal
- toy-like rather than futuristic
- warm and readable rather than dark and technical
- suitable for a garden / toys / 80s–90s inspired world

Avoid:

- pure black developer-style panels
- excessive gradients
- glassmorphism
- overly polished sci-fi UI
- lots of tiny text
- styling individual controls one by one when a shared Godot Theme can do it

Suggested visual language:

- dark blue/charcoal panels
- warm off-white text
- garden green as a secondary accent
- toy yellow/orange as the primary accent
- toy red for danger/destructive actions
- rounded corners
- chunky buttons
- strong hover/pressed states
- larger headings than the current prototype

---

## 2. Technical Direction

Create a reusable Godot UI theme instead of styling each button directly in scene files.

Suggested structure:

```text
res://ui/
    game_theme.tres
    fonts/
    icons/
    styles/
```

The theme should initially cover:

- Button
- Label
- PanelContainer
- CheckBox
- HSlider

Use `StyleBoxFlat` resources where practical.

Create theme variations for special buttons:

- `PrimaryButton`
- `SecondaryButton`
- `DangerButton`
- `TextButton`

Scenes should use `theme_type_variation` instead of large sets of local overrides.

Example:

```ini
[node name="Start" type="Button" parent="Center/Menu"]
custom_minimum_size = Vector2(320, 56)
theme_type_variation = &"PrimaryButton"
text = "Start Game"
```

---

# V1 — Shared Theme Foundation

## Task 1.1 — Create `game_theme.tres`

Create a shared Theme resource and apply it to the root Control of:

- main menu
- level select
- in-game HUD where practical

Do not redesign layouts yet.

Definition of done:

- [x] `res://ui/game_theme.tres` exists
- [x] main menu references it
- [x] level select references it
- [x] existing functionality is unchanged
- [x] no control becomes unreadable

Suggested baseline sizing:

```text
Body text:       18–20 px
Buttons:         18–20 px
Section heading: 24–28 px
Main title:      48–64 px
```

Exact sizes may be adjusted for readability.

---

## Task 1.2 — Define a Small Color Palette

Use a compact palette instead of ad-hoc colors.

Suggested starting colors:

```text
Panel dark:       #20262B
Panel lighter:    #2C343A
Text primary:     #F2EFE4
Text muted:       #C9C5B9
Primary accent:   #E8A52B
Garden green:     #5B9A59
Danger red:       #C8574E
Disabled:         #6E7476
```

These are a starting point, not immutable brand colors.

Definition of done:

- [x] theme colors are stored centrally
- [x] normal text is off-white instead of pure white
- [x] buttons no longer use generic black/grey defaults
- [x] disabled states remain readable

---

## Task 1.3 — Style Standard Buttons

Create a consistent button style using rounded `StyleBoxFlat` resources.

Suggested characteristics:

```text
corner radius: 8–12 px
button height: 52–60 px
horizontal padding: generous
```

Required states:

- normal
- hover
- pressed
- disabled
- focus

Behavior:

- hover should visibly brighten or lift the button
- pressed should look slightly darker / pushed in
- focus should be visible for keyboard navigation

Definition of done:

- [x] all menu buttons share the same base style
- [x] hover state is obvious
- [x] pressed state is obvious
- [x] keyboard focus is visible
- [x] no per-button duplicated StyleBox resources unless necessary

---

## Task 1.4 — Add Button Variations

Create theme variations for:

### PrimaryButton

Use for the main action.

Examples:

- Start Game
- Start Wave
- Continue

Should use the primary yellow/orange accent.

### SecondaryButton

Use for normal supporting actions.

Examples:

- Options
- Back
- Restart Level

Should use the normal dark panel/button style.

### DangerButton

Use sparingly.

Examples:

- Quit
- Delete Save if added later

Should use muted red styling rather than bright alarm red.

### TextButton

Use for low-priority actions.

Examples:

- Quit on the main menu
- small back/close actions

Should have less visual weight than PrimaryButton.

Definition of done:

- [x] theme variations exist
- [x] Start Game uses `PrimaryButton`
- [x] Options uses `SecondaryButton`
- [x] Quit uses either `TextButton` or a restrained `DangerButton`
- [x] visual hierarchy is immediately visible

---

# V2 — Main Menu Visual Pass

## Task 2.1 — Improve Main Menu Hierarchy

Keep the current menu flow, but make the hierarchy clearer.

Suggested layout:

```text
GARDEN
TRAUMA

Tiny toys. Serious business.

[ START GAME ]
[ OPTIONS ]

Quit
```

The subtitle is optional.

Changes:

- enlarge the title
- make Start Game the strongest button
- reduce the visual weight of Quit
- increase button width slightly
- keep the menu centered

Suggested button minimum size:

```gdscript
Vector2(320, 56)
```

Definition of done:

- [ ] title is visually dominant
- [ ] Start Game is clearly the primary action
- [ ] Options is secondary
- [ ] Quit is tertiary
- [ ] menu remains responsive

---

## Task 2.2 — Split the Title Visually

Experiment with the title as two lines:

```text
GARDEN
TRAUMA
```

Possible color treatment:

- `GARDEN`: off-white or garden green
- `TRAUMA`: yellow/orange or restrained red-orange

Do not introduce horror styling. The contrast between the dramatic name and playful toy presentation is intentional.

Definition of done:

- [ ] title supports two-line presentation
- [ ] title remains readable at common resolutions
- [ ] no major layout shift occurs when the window changes size

---

## Task 2.3 — Add a Background Image Layer

Add support for a future garden background behind the menu.

Suggested scene structure:

```text
MainMenu
├── Background
│   ├── TextureRect
│   └── DarkOverlay
├── Center
│   └── MenuPanel
└── OptionsPanel
```

For now use either:

- an existing garden screenshot, or
- a simple placeholder texture

The UI should still work without the image.

The overlay should darken the image enough for readable text.

Definition of done:

- [ ] background layer exists
- [ ] background fills the viewport
- [ ] aspect ratio behaves sensibly
- [ ] dark overlay improves contrast
- [ ] menu remains readable on both bright and dark imagery

Do not spend time generating final menu art in this task.

---

## Task 2.4 — Add a Menu Panel

Wrap the menu content in a `PanelContainer`.

Inside it, add a `MarginContainer`.

Suggested internal margins:

```text
left:   32
right:  32
top:    28
bottom: 28
```

Suggested structure:

```text
Center
└── MenuPanel
    └── MarginContainer
        └── VBoxContainer
            ├── Title
            ├── Subtitle
            ├── Spacer
            ├── Start
            ├── Options
            └── Quit
```

Use moderate transparency if it looks good against the background.

Definition of done:

- [ ] menu content has consistent padding
- [ ] buttons do not touch panel edges
- [ ] panel styling comes from the theme
- [ ] scene remains easy to understand

---

# V3 — Options Screen

## Task 3.1 — Apply the Shared Theme

Keep the existing controls:

- Music Enabled
- Music Volume
- SFX Enabled
- SFX Volume
- Back

Apply the shared theme first.

Do not change functionality.

Definition of done:

- [ ] checkboxes match the global visual language
- [ ] sliders are clearly visible
- [ ] heading uses section-heading typography
- [ ] Back uses a secondary or text style

---

## Task 3.2 — Improve Options Layout

Replace the raw vertical developer-form look with grouped rows.

Suggested rough layout:

```text
AUDIO OPTIONS

Music
[✓ Enabled]
Volume  ───────●────

Sound Effects
[✓ Enabled]
Volume  ────●───────

[ Back ]
```

Prefer clear spacing and grouping over decorative elements.

Definition of done:

- [ ] Music controls visually belong together
- [ ] SFX controls visually belong together
- [ ] labels align cleanly
- [ ] screen remains usable with keyboard/controller navigation

---

# V4 — Level Select

## Task 4.1 — Apply Theme Without Redesign

First apply the shared theme to the existing level selector.

Do not replace the buttons yet.

Definition of done:

- [ ] level select matches main menu colors and typography
- [ ] heading has proper hierarchy
- [ ] available and completed levels remain obvious

---

## Task 4.2 — Introduce Level Cards

Replace plain full-width level buttons with reusable level cards.

Suggested content:

```text
[ level preview ]

GARDEN 1
✓ Completed
```

or:

```text
[ level preview ]

GARDEN 2
Available
```

The preview may be a placeholder color/texture initially.

Create a reusable scene if practical, for example:

```text
res://ui/components/level_card.tscn
```

Definition of done:

- [ ] level card scene is reusable
- [ ] supports level name
- [ ] supports status text
- [ ] supports optional preview texture
- [ ] completed / available / locked state can be styled differently

Do not implement the full campaign map here.

---

## Task 4.3 — Prepare for Chapter Grouping

Structure the level selector so it can later support groups such as:

```text
THE GARDEN
1-1  1-2  1-3  1-4  1-5

THE SHED
2-1  2-2  2-3  2-4  2-5
```

Only prepare the layout/component structure.

Do not add all future levels.

Definition of done:

- [ ] existing levels still work
- [ ] UI structure does not assume only two levels
- [ ] later chapter grouping will not require a full rewrite

---

# V5 — In-Game HUD Cleanup

This phase should happen after the menu theme works.

The current in-game UI contains useful development instructions. Do not remove them until the game remains understandable without them.

---

## Task 5.1 — Apply the Theme to the HUD

Apply the same palette and panel styling to:

- tower placement panel
- garden status panel
- wave controls
- buttons

Do not significantly move controls yet.

Definition of done:

- [ ] HUD visually belongs to the same game as the main menu
- [ ] information remains readable
- [ ] tower placement behavior is unchanged
- [ ] wave behavior is unchanged

---

## Task 5.2 — Reduce Developer Instructions

Review instructional text such as:

```text
Select a tower tile. Esc cancels selection.
Select a tower, then click grass to place it.
Click a placed tower to upgrade it.
Right-click or Esc: cancel selection.
```

Move instructions toward:

- tooltips
- contextual hints
- tutorial messages
- a future help screen

Keep only information the player currently needs.

Definition of done:

- [ ] no essential instructions are lost
- [ ] side panels contain less permanent text
- [ ] game area gains more visual breathing room

---

## Task 5.3 — Replace Tower Buttons With Tower Cards

Create a reusable tower-card component.

Suggested design:

```text
╭───────────────╮
│               │
│   [icon]      │
│               │
│ Laser Tower   │
│   ● 90        │
╰───────────────╯
```

Card should support:

- tower icon or placeholder
- display name
- cost
- disabled/unaffordable state
- selected state

Suggested reusable scene:

```text
res://ui/components/tower_card.tscn
```

Definition of done:

- [ ] tower cards are data-driven
- [ ] tower icon can be a placeholder
- [ ] cost is clearly visible
- [ ] selected state is obvious
- [ ] unaffordable state is obvious
- [ ] existing tower-placement logic still works

---

# V6 — Polish Later

These are explicitly not part of the first visual pass.

Possible later improvements:

- live 3D garden scene behind the menu
- animated toy props
- level preview renders
- custom game logo
- custom font
- button sound effects
- menu transitions
- subtle panel animations
- controller glyphs
- tower-card hover animation
- chapter map
- stars / medals / completion ratings
- accessibility color checks
- scalable UI testing at multiple resolutions

Do not implement these unless the earlier phases are complete.

---

# Agent Working Rules

When implementing any task from this document:

1. Keep each PR small.
2. Do not redesign unrelated screens.
3. Preserve existing functionality unless the task explicitly changes it.
4. Prefer reusable Godot Theme resources over per-node overrides.
5. Prefer reusable UI scenes for repeated components.
6. Keep placeholder assets clearly named and easy to replace.
7. Use comments where the Godot theme/resource setup is not obvious.
8. Do not introduce custom shaders just for menu styling in V1.
9. Test at more than one window size when changing layout.
10. Update this document by ticking completed boxes where practical.

---

# Recommended PR Order

Use roughly one PR per item below:

- [ ] PR 1 — shared `game_theme.tres`
- [ ] PR 2 — button states and theme variations
- [ ] PR 3 — main menu hierarchy
- [ ] PR 4 — menu background + panel
- [ ] PR 5 — options visual cleanup
- [ ] PR 6 — level select theme
- [ ] PR 7 — reusable level cards
- [ ] PR 8 — HUD theme pass
- [ ] PR 9 — reduce persistent instructions
- [ ] PR 10 — reusable tower cards

This ordering keeps each change easy to review and makes regressions easier to isolate.
