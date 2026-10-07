# Sound Design

## Goal

Set up the game's audio system while the project is still small enough to understand the full flow from UI settings to gameplay sounds.

The first version should prove that:

- music can play across the menu and gameplay;
- music and sound effects can be enabled or disabled independently;
- music and sound-effects volume can be adjusted;
- tower firing sounds work in-game;
- the audio setup is reusable for later levels, towers, and enemy sounds.

Keep V1 simple. Placeholder audio is expected and should be easy to replace later.

---

# V1 — Basic Audio Pipeline

## 1. Audio buses

Create these Godot audio buses:

```text
Master
├── Music
└── SFX
```

For now, all gameplay sound effects can use the `SFX` bus.

Later versions may split SFX into more buses if useful.

Example:

```text
SFX
├── Towers
├── Enemies
└── UI
```

This is not required for V1.

---

## 2. Audio asset structure

Use stable, descriptive filenames instead of filenames copied directly from asset packs.

Suggested structure:

```text
assets/
└── audio/
    ├── music/
    │   └── garden_theme_01.ogg
    └── sfx/
        ├── towers/
        │   ├── tower_01_fire.ogg
        │   ├── tower_02_fire.ogg
        │   └── tower_03_fire.ogg
        └── enemies/
            ├── enemy_destroyed_01.ogg
            └── enemy_objective_reached_01.ogg
```

Placeholder assets are fine.

If external placeholder assets are used, add:

```text
assets/audio/audio-sources.md
```

Record:

- source;
- original filename;
- license;
- renamed filename in this project.

Prefer CC0 assets for placeholders.

---

## 3. Main menu

Create a simple main menu scene.

The menu should contain:

```text
Game Title

[ Start ]

[ Options ]

[ Quit ]
```

### Start

The `Start` button loads the current garden level directly.

A level-selection screen will be added later.

Do not design the Start button around a future level selector yet.

### Options

The `Options` button opens a small options panel or options screen.

It should contain:

```text
Music
[x] Enabled
Volume [----------]

Sound Effects
[x] Enabled
Volume [----------]

[ Back ]
```

The controls should affect the Godot audio buses rather than individual audio players.

Required settings:

- Music enabled checkbox
- Music volume slider
- SFX enabled checkbox
- SFX volume slider

Suggested slider range:

```text
0–100
```

Internally this can be converted to Godot's decibel volume.

Muting should use the audio bus mute state.

---

## 4. Settings persistence

Create one small audio/settings manager responsible for applying audio preferences.

Example responsibilities:

```text
AudioSettings
├── music_enabled
├── music_volume
├── sfx_enabled
└── sfx_volume
```

V1 should save these settings so they survive restarting the game.

A simple Godot `ConfigFile` is sufficient.

Suggested file:

```text
user://settings.cfg
```

Do not let individual towers or scenes manage global volume settings.

---

## 5. Background music

Background music should play:

- on the main menu;
- during the garden level.

For V1, use the same music track for both.

The track should continue cleanly when moving from the menu into the level if practical, rather than restarting.

Recommended approach:

Create a small global `AudioManager` autoload containing an `AudioStreamPlayer` for music.

Example:

```text
AudioManager
└── MusicPlayer
```

`MusicPlayer` should:

- use the `Music` bus;
- loop the garden/menu music;
- survive scene changes.

This avoids placing a separate music player in every scene.

---

## 6. Tower firing sounds

Each of the three current towers should play a firing sound when it attacks.

Use:

```text
AudioStreamPlayer3D
```

because tower sounds originate from a world position.

Each tower should own or reference its firing sound.

Example scene structure:

```text
Tower
├── Mesh
├── AttackArea
├── ...
└── FireAudio
```

`FireAudio`:

- uses the `SFX` bus;
- plays when the tower actually fires;
- should not play merely because an enemy enters range.

The firing logic remains responsible for deciding when an attack occurs.

The audio node only represents the sound.

Example concept:

```gdscript
func fire_at(target: Node3D) -> void:
    # Existing attack logic here.
    fire_audio.play()
```

Do not hard-code global volume levels inside the tower.

---

## 7. Three distinct tower sounds

The three towers should have recognisably different placeholder firing sounds.

For example:

```text
Projectile / physical tower
    short toy-like pop or mechanical shot

Laser tower
    short laser zap

Lightning tower
    electrical crack / zap
```

Exact final sound design is not important for V1.

The purpose is to make it immediately obvious that each tower can have its own audio identity.

---

## 8. Enemy sounds

Add placeholders for:

### Enemy destroyed

Play when an enemy is defeated.

Suggested character:

```text
small toy impact / pop / break sound
```

### Enemy reaches objective

Play when an enemy successfully reaches the objective.

Suggested character:

```text
short negative cue / thud / warning
```

These can use `AudioStreamPlayer3D` initially.

If the objective cue later becomes an important game-wide notification, it may be moved to non-positional UI audio.

---

# V1 Acceptance Checklist

## Main menu

- [ ] Main menu scene exists.
- [ ] Start button loads the garden level.
- [ ] Options button opens audio settings.
- [ ] Quit button exits the game.

## Audio settings

- [ ] Music enable/disable checkbox works.
- [ ] Music volume slider works.
- [ ] SFX enable/disable checkbox works.
- [ ] SFX volume slider works.
- [ ] Settings are saved between game launches.
- [ ] Settings operate through audio buses.

## Music

- [ ] Music plays in the main menu.
- [ ] Music plays in the garden level.
- [ ] Music uses the `Music` bus.
- [ ] Music is managed outside individual level scenes.
- [ ] Music survives menu → level transition cleanly.

## Towers

- [ ] Tower 1 has a firing sound.
- [ ] Tower 2 has a firing sound.
- [ ] Tower 3 has a firing sound.
- [ ] The three firing sounds are recognisably different.
- [ ] Tower sounds use positional `AudioStreamPlayer3D`.
- [ ] Tower sounds use the `SFX` bus.

## Enemies

- [ ] Enemy destroyed sound exists.
- [ ] Enemy objective-reached sound exists.
- [ ] Enemy sounds obey SFX settings.

## Assets

- [ ] Placeholder audio has descriptive filenames.
- [ ] Placeholder licenses/sources are documented.
- [ ] Audio files can be replaced without changing gameplay logic.

---

# V2 — Audio Polish

After V1 is working, improve the experience without changing the basic architecture.

Possible additions:

- [ ] Add 2–3 variations of frequently repeated firing sounds.
- [ ] Randomly choose between firing-sound variants.
- [ ] Add slight random pitch variation to repeated tower attacks.
- [ ] Add button hover/click sounds.
- [ ] Add separate `UI`, `Towers`, and `Enemies` buses if useful.
- [ ] Add fade-in/fade-out for music transitions.
- [ ] Give each environment its own music track.
- [ ] Add simple ambient garden sounds such as birds, wind, or distant neighbourhood noise.

Avoid adding all of these before V1 is fully understandable and working.

---

# V3 — Final Sound Direction

Replace placeholders with sounds that support the game's toy-world presentation.

General direction:

- playful rather than militaristic;
- readable and satisfying;
- avoid overly realistic gunfire;
- towers should sound like imaginative toys;
- enemy destruction should feel light and cartoony;
- music should suggest children playing in a garden rather than an actual battlefield.

Possible musical palette:

- pizzicato strings;
- marimba or xylophone;
- light percussion;
- simple acoustic instruments;
- playful melodic motifs.

Each major environment can eventually have its own musical identity:

```text
Garden
Shed
Sandpit
...
```

---

# Implementation Principle

V1 should make the complete chain visible:

```text
Options Menu
    ↓
Audio Settings
    ↓
Godot Audio Buses
    ↓
AudioManager / AudioStreamPlayers
    ↓
Menu Music + Level Music + Tower SFX + Enemy SFX
```

The goal is not sophisticated sound design yet.

The goal is to build one small, understandable audio system that can grow with the rest of the game.
