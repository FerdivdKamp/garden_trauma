# Finishing up the skeleton

The project already has a main menu, a tile-based garden level, three placeable towers, two enemy definitions, targeting and damage, attack effects, and basic audio. The current garden scene is still a playground: enemies are spawned manually, towers cost nothing, and a battle has no outcome. This checklist aims for one complete, short level first, then simple progress across levels.

## 1. Make one level playable from start to finish

- [x] Define a small wave schedule for `garden_test_01`: enemy type, count, spawn spacing, and break between waves.
- [x] Replace the manual enemy spawn/reset panel in the normal game flow with automatic wave spawning; keep the panel available only for debugging if useful.
- [x] Track each spawned enemy until it is defeated or reaches the objective, and remove it after its sound/effect finishes.
- [x] Add objective health or lives; each enemy that gets through reduces it once.
- [x] Give the player starting currency, charge each tower's existing `cost`, and prevent unaffordable placement.
- [x] Award each defeated enemy's existing `reward` once; show current currency in the game HUD.
- [x] Show objective health, current wave, enemies remaining, and a clear **Start next wave** control.
- [x] End the level in victory after the final wave is cleared, or defeat when objective health reaches zero.
- [x] Add a result panel with **Retry** and **Main menu** actions; stop spawning and attacking after the result.
- [x] Add pause/resume and restart controls that work during a level.

## 2. Turn the level into a small progression loop

- [ ] Give levels stable IDs and connect each ID to a map file and wave schedule. Keep `garden_test_02.json` as a second playable entry once it has its own waves.
- [ ] Add a simple level selection screen after **Start**, showing which levels are available and completed.
- [ ] Save completed level IDs in `user://` when the player wins, and load them when the game starts. Keep this separate from `user://settings.cfg`, which stores audio preferences.
- [ ] Decide the unlock rule for the first two levels, then apply it in level selection; a simple “finish level 1 to unlock level 2” rule is enough.
- [ ] After victory, offer **Next level** when one is available; otherwise return to level selection.

## 3. Close the basic playability gaps

- [ ] Move prototype controls such as enemy speed, scale, and tile debugging behind a debug mode so the normal HUD stays focused on play.
- [ ] Add a short in-game hint for placing a tower, starting a wave, and the objective's health.
- [ ] Decide whether one simple tower upgrade is needed for the first complete level; if so, make its cost and effect visible before purchase.
- [ ] Play through both levels from a fresh save: win, lose, retry, unlock level 2, restart the game, and confirm completion remains saved.

## Keep outside this skeleton pass

Manual tower control, special abilities, branching campaign territory, strategic resources, final art, and the reward-choice system belong to later experiments in `toy_tower_defense_design.md`. A linear two-level progression is enough to prove the save and menu flow.
