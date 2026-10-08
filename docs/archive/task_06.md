Implement a simple lightning tower (cylinder on a base, with a sphere at the top). It shoot use a reusable lightning attack effect.
The tower shoots / draws a procedural electrical bolt from a start point to a target point. The bolt should consist of multiple segments with randomized jitter, refresh briefly during the strike, and use an emissive material/shader so it looks bright and electrical.

Requirements
* Prevent the stutter by preloading, similar to the existing tower shoot effects.
* Configurable segment count, width, jitter, color, and lifetime.
* A strike(start, target) method.
* Keep gameplay/damage logic separate from the visual effect.
* Structure it so chain lightning can be added later.

The tower should be selectable in the existing tower_demo and tower_placement scenes