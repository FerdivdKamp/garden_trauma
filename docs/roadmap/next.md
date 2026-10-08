# Next steps and open questions

This is a prioritized working list, not a commitment to build every idea in the design notes. Confirm each change in the playable game before expanding it.

## Next validation pass

1. Play both gardens in the editor from a fresh save. Check a win, a loss, retry, unlock, and save reload, plus UI legibility and effects on the target hardware. Headless tests already cover the state transitions, but cannot judge presentation.
2. Playtest placement and upgrade choices. Use `python tools/balance_report.py` to spot changed outcomes, then check whether its findings match real play.
3. Replace the two temporary enemy sounds and record their provenance and license in [Audio sources](../reference/audio-sources.md). Verify rights for the supplied music and tower sounds before redistribution.

## Near-term work to consider

- Finish the menu and HUD visual pass from the [menu theme plan](plans/menu-theme.md). Its shared theme foundation exists; most later visual tasks remain open.
- Improve asset and terrain readability from the [art direction](plans/art-direction.md) and [tile system plan](plans/tile-system.md). The current rock is still a placeholder.
- Improve level authoring: an ASCII converter, editor preview, or level picker are suggestions in [Build a tile level](../guides/build-tile-level.md). Choose the smallest tool that removes real friction.
- Extend the [Blender pipeline](plans/blender-asset-import.md) only for materials or validation problems encountered with actual assets.

## Design experiments, still undecided

- Does temporary manual control of a tower make quiet wave time more engaging? Test one tower in a small scene before generalizing it.
- Which player action is worth prototyping first: Marble Spill, Big Hand, or another toy-box ability? Decide its cost, cooldown, and effect on wave balance through play.
- Should attack levels and a campaign map add meaningful choices beyond the current two-level unlock chain? The [game design notes](plans/game-design.md) explore this but do not define implemented rules.
- Would rejected rewards becoming enemy advantages improve strategy or obscure cause and effect? This needs a focused prototype.
- How much wave information should scouting reveal, and how should the player act on it?

These questions belong to later phases. Keep each experiment isolated and retain the playable two-level loop while testing it.
