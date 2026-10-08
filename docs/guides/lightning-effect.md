# Lightning tower and bolt effect

Run `scenes/tower_placement.tscn` and choose **Lightning Tower**, or run `scenes/tower_demo.tscn` and choose it from the selector. The tower has a cylinder on the standard base, a sphere at the top, and a `LightningOrigin` marker above the sphere. The attack code passes the marker and target positions to the bolt effect; it calculates damage separately.

## How the bolt is drawn

`scenes/lightning_effect.tscn` is a reusable visual with a `strike(start, target)` method. Both arguments are world positions. The script converts them to its local space, splits the line into `segment_count` parts, and randomly offsets only the interior points. The sine taper keeps the first and last points attached to their endpoints. Every short `refresh_interval`, it generates new offsets until `lifetime` expires.

Each segment is two crossed, thin triangle ribbons in an `ImmediateMesh`. The crossed faces keep the line visible from the angled 3D cameras. Its `StandardMaterial3D` is unshaded and emissive, giving the bolt a bright cyan look without a custom shader.

Select the root of `lightning_effect.tscn` to edit **Segment Count**, **Width**, **Jitter**, **Color**, **Lifetime**, and **Refresh Interval** in the Inspector. A larger segment count makes finer zigzags; more jitter gives a rougher arc. The effect has no target search or damage rules, so these visual settings cannot change combat behavior.

## First-strike performance and future chains

The placement scene creates 16 hidden effect instances when it starts. Each instance already has its mesh and emissive material, plus a starter triangle surface, before a tower fires. A strike uses the next inactive instance from this pool; if all 16 are busy, it reuses one. The demo scene includes one instance from startup. This follows the same early-instancing approach as the other shot effects to avoid first-use rendering setup during an attack.

`fire_lightning(start, target)` represents one visual link. A future chain attack can choose multiple enemies in gameplay code, apply damage to each, and call `fire_lightning()` once for each pair of consecutive positions. The visual `strike()` method does not need to know how many links the attack has.
