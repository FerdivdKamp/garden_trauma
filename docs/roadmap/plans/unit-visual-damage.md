# Unit visual damage

!!! note "Proposal for review"
    The first Godot destruction experiment is implemented for the car variants and wind-up robot. Partial damage and any Blender animation remain future experiments.

Run `examples/unit_destruction.tscn` with F6 to replay the three effects. Use **Destroy units** and **Reset** to compare them at leisure. Wave enemies are removed after the effect and sound finish. The car's mirrored wheel meshes are split into left and right pieces at defeat, with centered pivots for the outward roll. Robot parts use fitted box-shaped physics bodies and a temporary floor at path height. The floor and debris use a separate collision layer, so the effect does not interfere with gameplay. The box shapes approximate the main parts; smaller details such as the antenna do not have separate colliders.

## Goal and visual direction

Make defeated toys visibly come apart in a playful, readable way. Large pieces and clear movement should read from the normal gameplay camera, in keeping with the project's toy-diorama art direction. The effect is visual feedback: it must not change combat, pathing, rewards, or wave timing.

## Two damage states

### Partial damage — later

A unit is partially damaged while it still has health and can continue moving and fighting. There are no new partial-damage visuals in the first experiment. Possible approaches, such as a wobble, loose parts, or surface damage, can be explored later after the destruction effects have been evaluated. Health thresholds and specific effects are deliberately undecided.

### Destroyed — first experiment

When health reaches zero, the unit is defeated immediately and its destruction effect plays once:

- **Car:** its wheels come off and scatter a short distance; the remaining car settles onto the ground. Start with the formula car, then check whether the same approach works for the battery variant. The exact wheel setup in each imported model needs inspection before choosing how to separate the pieces.
- **Wind-up robot:** its arms, legs, and head fall off, and its body drops to the floor. Give the parts enough separation to read as a toy coming apart, with a short, playful fall rather than a violent explosion.

Other unit types keep their existing defeat visuals for now. Reaching the objective is a separate outcome and should not trigger destruction.

## Proposed approach

1. **Inspect the assets and make a small test scene.** Check the imported hierarchy, individual wheel meshes, robot parts, pivots, scale, and ground position. The robot already exposes named arm, leg, and head pivots used by its walking animation; confirm whether those pivots contain everything that should fall with each part. If needed, adjust the Blender source and re-export through the existing asset pipeline. Use a small Godot scene to trigger each effect repeatedly before integrating it into a battle.
2. **Prototype the motion in Godot.** Stop the unit's walking or driving animation at defeat and animate its visible pieces from their current pose. Start with simple authored motion, such as tweens or an `AnimationPlayer`, so the timing and landing positions are easy to inspect. Keep the body and pieces aligned with the unit's actual world position, orientation, scale, and the local ground. Try the effect on a bend as well as a straight path. Use lightweight physics only if a test shows it improves the result; it is not required for the first version.
3. **Keep gameplay and presentation separate.** The existing `defeated` signal should still fire immediately and exactly once, so rewards and wave progression do not wait for the visual. The current cleanup hides the visual immediately and keeps the enemy around until its destruction sound finishes. Change that lifecycle carefully: the destruction presentation must remain visible long enough to finish, and its sound must finish independently of the visual timing. One possible approach is a short-lived visual effect scene placed in the world, leaving the defeated enemy free to follow its normal gameplay cleanup. Decide the simplest arrangement after testing the existing scene and its callers; prevent defeated units from being targeted again.
4. **Clean up the debris.** After a short, adjustable display period, remove the temporary pieces and effect scene. They should not block routes, affect gameplay, or accumulate throughout a wave. Check behavior when the level is restarted or exited during an effect.
5. **Evaluate at gameplay scale.** Test one of each unit, different headings and visual scales, repeated hits, simultaneous defeats, and a unit reaching the objective. Check that the body reaches the ground, parts do not visibly float, sounds finish, rewards and wave completion still happen once, and the effect is readable without obscuring nearby enemies. Use a representative battle as well as the focused test scene.

## Later option: Blender animation

If the Godot prototype feels stiff or difficult to tune, try an authored destruction animation in Blender and export it with the unit model. Blender offers more direct control over timing, arcs, and poses; Godot can still trigger the animation and manage its lifetime. Compare the result at gameplay camera distance before choosing it. A Blender animation may need an explicit transition from the robot's current walking pose to avoid a visible snap; test that transition rather than assuming it will work automatically.

Godot and Blender are alternatives to evaluate, not commitments to implement both. Keep the simplest result that looks good and is practical to maintain.

## Review questions

- Does the amount of scattering feel toy-like and readable without being distracting?
- How long should the wreckage remain visible before disappearing?
- Does the battery car need distinct behavior, or should both car variants share the same visual treatment?
- Is the Godot prototype expressive enough, or would a Blender-authored animation noticeably improve it?

The initial motion is a starting point for visual playtesting; timing, landing positions, and a possible Blender animation can be adjusted after review.
