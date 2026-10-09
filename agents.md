# agents.md

## Purpose

This repository is both a game project and a learning project.

When working in this repository, do not optimize only for speed of implementation. The code, scenes, project structure, and explanations should also help the project owner learn Godot, game-development patterns, and the reasoning behind technical decisions.

The goal is to build the game incrementally while keeping the project understandable.

---

# Project Reference Documents

Before making significant changes, consult the relevant project documentation.

## Game Design Document

Reference:

```text
docs/roadmap/plans/game-design.md
```

This document describes:

- The intended game concept
- Core gameplay pillars
- Tower-defense mechanics
- Player-intervention systems
- Campaign ideas
- Planned development phases
- Open design questions

Use it to understand **what the game is trying to become**.

Do not treat every idea in the design document as a requirement. Some ideas are intentionally exploratory and should be validated through small prototypes before becoming permanent systems.

---

## Infrastructure / Technical Document

Reference:

```text
docs/reference/project-structure.md
docs/guides/getting-started.md
```

This document describes technical decisions such as:

- Project structure
- Scene organization
- Coding conventions
- Testing
- Version control
- Asset handling
- Tooling
- Build/export setup
- Development workflow

Use it to understand **how the project should be built and maintained**.

If the implementation and the infrastructure document disagree, call out the mismatch instead of silently introducing a new convention.

---

# Core Working Principle

The project owner is learning Godot and game development while building this project.

Therefore:

> Prefer solutions that are understandable, inspectable, and teach useful patterns.

A slightly longer but clear implementation is often better than a clever abstraction that hides how Godot works.

Avoid unnecessary complexity.

---

# Explain Important Decisions

When making a non-trivial change, explain the reasoning behind it.

Examples include:

- Why a node type was chosen
- Why logic belongs in a particular scene or script
- Why a signal is preferable to a direct reference
- Why a resource is used instead of hard-coded values
- Why a scene is split into reusable sub-scenes
- Why composition is preferable to inheritance
- Why a particular Godot lifecycle method is used

Keep explanations practical.

For example:

> The enemy emits a `died` signal instead of directly updating the player's currency. This keeps the enemy reusable and prevents it from needing to know which system owns the economy.

This is more useful than simply implementing the signal without explanation.

---

# Comments

Use comments when they help explain something that may not be obvious to someone learning Godot.

Good comments explain:

- Godot-specific behavior
- Lifecycle assumptions
- Why something is implemented in a certain way
- Non-obvious coordinate-space logic
- Signal relationships
- Workarounds
- Important gameplay assumptions

Example:

```gdscript
# _physics_process is used here because movement interacts with
# the physics engine. Multiplying by delta keeps the speed
# independent of frame rate.
func _physics_process(delta: float) -> void:
    position += direction * speed * delta
```

Avoid comments that merely repeat the code.

Bad:

```gdscript
# Set health to 100.
health = 100
```

Comments should teach or clarify rather than create noise.

---

# Example Scenes

When introducing an important new mechanic or Godot concept, prefer creating a small example scene when practical.

Example scenes are useful for systems such as:

- Enemy path following
- Tower targeting
- Projectiles
- Area detection
- Signals
- Manual tower control
- Camera controls
- Navigation
- Object pooling
- Wave spawning
- UI interactions
- Resources and configuration objects

Example scenes should:

1. Be small.
2. Demonstrate one concept clearly.
3. Avoid depending on the entire game.
4. Be easy to run directly from the editor.
5. Include enough comments or labels to explain what is happening.

Suggested location:

```text
examples/
```

or another location defined by the infrastructure document.

An example scene should not automatically become production architecture. Once a concept is understood and proven, it can be incorporated into the main game cleanly.

---

# Prefer Small Iterations

Build systems in small, testable steps.

For example, when creating a tower:

1. Place a static tower in a scene.
2. Detect enemies within range.
3. Print the selected target.
4. Rotate toward the target.
5. Fire a projectile.
6. Apply damage.
7. Add targeting rules.
8. Add visual polish.

Do not implement the complete tower system, upgrade tree, targeting configuration, animation system, and effects framework in one step unless the surrounding architecture already exists.

Each stage should ideally leave the project runnable.

---

# Avoid Premature Architecture

Do not introduce large frameworks before they are needed.

Be cautious with:

- Deep inheritance trees
- Global service locators
- Large autoload/singleton systems
- Generic event buses
- Dependency injection frameworks
- Complex state machines
- Large data-driven frameworks
- Highly abstract factory systems

These patterns may become useful later, but early prototypes should favor simple Godot-native patterns.

Good early tools include:

- Scenes
- Nodes
- Signals
- Resources
- Exported properties
- Small scripts
- Composition

Introduce abstraction after repeated patterns make its value clear.

---

# Godot-Native Patterns

Prefer normal Godot concepts over recreating patterns from other engines.

Examples:

- Use scenes as reusable components.
- Use signals for decoupled communication.
- Use exported properties for editor-configurable values.
- Use Resources for reusable configuration data.
- Use node composition where practical.
- Use groups for loose categorization and discovery when appropriate.

Do not assume Unity or Unreal patterns should be copied directly into Godot.

If a familiar pattern from another engine differs substantially in Godot, explain the difference.

---

# Scene Structure

Keep scenes focused on a clear responsibility.

Examples:

```text
Enemy
├── Visual
├── Collision
└── HealthComponent
```

```text
Tower
├── Visual
├── DetectionArea
├── WeaponPivot
└── Weapon
```

Prefer reusable sub-scenes when they make relationships easier to understand.

Do not split scenes purely for architectural purity. A scene should exist because it represents a useful reusable or independently understandable unit.

---

# Scripts

Prefer:

- Small scripts
- Descriptive names
- Typed GDScript where practical
- Clear exported variables
- Clear signal declarations
- Simple control flow

Example:

```gdscript
@export var attack_range: float = 8.0
@export var damage: float = 10.0
@export var attacks_per_second: float = 1.0
```

Prefer explicit code over compressed clever code when teaching value is higher.

---

# Naming

Use names that describe the game concept.

Prefer:

```text
ToyTank
EnemyPath
TowerTargeting
WaveSpawner
ManualControl
```

over generic names such as:

```text
Manager2
System
Handler
Thing
Logic
```

Godot node names should also help explain the scene tree when viewed in the editor.

---

# Testing and Debugging

When adding new systems:

- Include simple ways to test them.
- Add temporary debug visualization where useful.
- Make important variables editable in the inspector.
- Prefer deterministic test scenarios when debugging behavior.

Examples:

- Draw tower attack range.
- Show the current target.
- Display enemy health.
- Provide a button for spawning one enemy.
- Create a tiny scene containing one tower and one enemy path.

Remove noisy temporary debugging once it is no longer useful, but retain intentionally useful development tools.

Follow the testing conventions described in the infrastructure document.

---

# Learning-Oriented Responses

When proposing or implementing a change, provide enough explanation that the project owner can understand:

1. What changed.
2. Where it changed.
3. Why the chosen approach fits Godot.
4. How to test it.
5. What concept is worth learning from it.

Do not provide a long tutorial for every trivial edit.

Match explanation depth to the complexity or novelty of the change.

---

# Refactoring

Refactor when:

- A pattern is repeated several times.
- Responsibilities have become unclear.
- A prototype has proven its value and needs production structure.
- A script is becoming difficult to understand.

When refactoring, explain what problem the refactor solves.

Avoid refactoring simply because a more sophisticated architecture exists.

---

# Design Experiments

Many systems in this project are still design experiments.

Examples may include:

- Manual tower control
- Player abilities
- Attack-and-defense levels
- Campaign territory systems
- Enemy use of rejected rewards
- Scouting and imperfect information

For experimental mechanics:

1. Implement the smallest version that tests the idea.
2. Keep it relatively isolated.
3. Avoid building large supporting systems prematurely.
4. Evaluate whether the mechanic is actually enjoyable.
5. Only then integrate it deeply into the game.

The design document should guide which experiments are worth trying.

---

# Scope Awareness

If a requested change is substantially larger than it first appears, point that out.

Separate:

- The smallest useful implementation
- Optional improvements
- Future architecture

For example:

> A basic manually controlled tower only needs targeting input and temporary control ownership. A generalized system that allows every tower type to expose different manual abilities can be designed later if the prototype proves fun.

Prefer completing the smallest useful version first.

---

# Preserve Playability

Whenever possible, leave the project in a runnable state.

Avoid large sequences of changes where:

- Scenes are broken for long periods
- Scripts reference missing systems
- Required assets are absent
- Half-migrated architecture remains in place

If a larger migration is necessary, break it into understandable stages.

---

# Documentation Updates

When a technical decision becomes a stable project convention, consider whether the infrastructure document should be updated.

When a gameplay experiment becomes a confirmed design direction, consider whether the design document should be updated.

Do not silently allow the implementation and documentation to drift apart.

---

# Final Guideline

Optimize for three things at the same time:

1. **A fun game**
2. **A maintainable project**
3. **A project that teaches the owner how it works**

When forced to choose between a clever solution and a clear solution, prefer the clear solution unless there is a strong practical reason not to.
