# Current status

This page describes the repository as of 9 October 2026. The detailed planning documents under **Design and planning notes** include older proposals and do not by themselves indicate completion.

## Implemented

- **Playable loop:** main menu, level selection, two gardens, wave schedules, placement costs, kill rewards, garden health, victory and defeat, pause, retry, restart, and progress saving.
- **Combat:** three tower definitions (laser tower, double tank, lightning tower), two enemy definitions, automatic targeting and turning, attack effects, and three sequential attack upgrades per tower. The laser tower uses an imported Blender model.
- **Level system:** JSON tile maps with validated routes, a shared grid, buildable grass, path sand, blocked rock, and a route-following enemy.
- **Tools:** tower demo, debug placement controls, JSON schemas and runtime validation, Blender export and material import, a balance report, and headless checks.
- **Presentation:** basic audio buses and saved volume preferences, positional tower and enemy cues, a shared UI theme foundation, laser, shell, particles, and lightning visuals.

## Current boundary

The two gardens prove a short progression loop. The project still uses simple tower and enemy visuals and some placeholder terrain. Combat damage is instant even when a shell animates toward its target. The balance report estimates one automatic placement policy; it is a comparison aid, not a substitute for playtesting.

The [next steps](next.md) separate work that can follow from design questions that need a prototype or decision. The original [skeleton checklist](../archive/skeleton-checklist.md) is kept as history; its opening paragraph describes an earlier build.
