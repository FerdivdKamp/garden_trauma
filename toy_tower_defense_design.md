# Toy Tower Defense — Design Notes & Build Roadmap

## 1. High-Level Concept

A slow-paced, toy-themed tower defense game built around **low mechanical intensity but high player attention**.

The player should not need to constantly click or micromanage. Instead, the game should regularly create meaningful decisions:

- Should I intervene now or save an ability?
- Should I manually control a tower for extra value?
- Should I reinforce this route or accept some damage?
- Should I push forward or stay defensive?
- Which territory should I attack next?
- Which reward do I choose, knowing the enemy may get the alternative?

The goal is to preserve the satisfying passiveness of tower defense games:

> I built this machine. Now I get to watch it work.

But avoid the player becoming completely detached or apathetic.

A useful design target is:

> **Low APM, high attention.**

The game should move through a rhythm of:

**Plan → Watch → Notice → Intervene → Recover → Plan**

rather than demanding constant action.

---

# 2. Theme and Setting

The battles are imagined conflicts between toys.

Possible units and towers include:

- Plastic soldiers
- Toy tanks
- Wind-up robots
- Toy dogs
- Wooden blocks
- Toy helicopters
- Marble traps
- Lightning/electric toys
- Cardboard forts
- Toy vehicles

The environments can be ordinary places transformed by imagination:

- Garden
- Sandbox
- Patio
- Shed
- Tree house
- Living room
- Bedroom
- Kitchen
- Garage

A level may initially appear to be a dramatic battlefield, with the full real-world context only becoming clear later.

For example, after winning a garden battle, the camera could pull back and reveal that everything was simply toys scattered across the lawn while two children are called inside for dinner.

This contrast between the imagined war and the mundane real environment can become an important part of the game's identity.

---

# 3. Core Design Pillars

## 3.1 Mostly Autonomous Defense

Towers and units should work effectively without constant player input.

The player primarily:

- Chooses placement
- Chooses upgrades
- Manages resources
- Responds to unusual threats
- Uses occasional abilities
- Makes strategic campaign decisions

Watching the defense function successfully should itself be enjoyable.

---

## 3.2 Optional Manual Control

Some or all towers can optionally be controlled directly.

Manual control should provide an advantage without being mandatory.

Examples:

### Toy Tank

Normally:

- Automatically tracks enemies
- Prioritizes according to standard AI rules
- Fires its cannon autonomously

When manually controlled:

- Player chooses the target
- Player can lead shots
- Player can prioritize dangerous enemies
- Potentially gains a small accuracy or damage bonus

### Toy Helicopter

Normally:

- Patrols automatically

When controlled:

- Can be repositioned
- Can focus on a particular lane
- Can rescue or support another area

### Lightning Tower

Normally:

- Chains automatically between nearby targets

When controlled:

- Player chooses where the chain starts
- Enables more efficient targeting

### Design Rule

Manual control should be:

> **An intervention tool, not a requirement.**

Ignoring a tower must remain viable.

---

# 4. Player Actions / Toy Box Abilities

The player can have a small collection of actions separate from towers.

These provide moments of activity without turning the game into an action game.

Possible abilities:

## Wind-Up

Temporarily overclocks a mechanical toy.

Possible effects:

- Faster attack speed
- Faster movement
- Increased range
- Temporary special attack

---

## Magnifying Glass

A focused beam of sunlight damages enemies in an area.

Could require the player to aim it briefly.

---

## Marble Spill

A group of marbles rolls across part of the battlefield.

Possible effects:

- Knockback
- Stun
- Damage
- Temporarily block a route

---

## Building Blocks

The player creates a temporary wall or obstacle.

Possible uses:

- Redirect a wave
- Delay enemies
- Protect a vulnerable tower
- Create a temporary chokepoint

---

## Big Hand

A child reaches into the battlefield and physically moves a toy.

Possible uses:

- Relocate a tower
- Rescue a unit
- Move an enemy
- Clear an obstacle

Within the toys' imagined world, this could appear almost supernatural.

---

# 5. Defense and Attack Levels

Some levels can move beyond traditional tower defense.

Instead of simply defending a base, both sides can control territory.

Example layout:

```text
Your Toy Box
     |
Defensive Line
     |
Contested Garden
     |
Enemy Defensive Line
     |
Cardboard Castle
```

The player's units push forward automatically while enemy units advance toward the player's base.

Towers can help secure territory.

As the player gains ground:

- New tower locations become available
- Resource income may increase
- Spawn points move forward
- Enemy defenses become vulnerable

This creates a strategic tension:

> How much can I invest in attacking without weakening my own defense?

The underlying gameplay can still remain relatively passive because armies continue to fight autonomously.

---

# 6. Campaign Map

A larger campaign map can connect individual tower-defense battles.

Example:

```text
                  [Tree House]
                       |
[Sandbox] — [Lawn] — [Patio] — [Kitchen Door]
     |           |
   [Shed]   [Flower Bed]
```

Each territory can provide a persistent bonus.

Examples:

| Territory | Player Bonus |
|---|---|
| Sandbox | Stronger barricades |
| Shed | Cheaper mechanical toys |
| Patio | Extra deployment slot |
| Tree House | Better scouting information |
| Flower Bed | Nature-themed defenses or resources |
| Garage | Vehicle upgrades |

---

# 7. Enemy Claims Unchosen Territory

A major campaign mechanic could be:

> When the player chooses one territory to attack, the enemy may capture another.

Example:

The player chooses to attack the **Shed**.

While that battle takes place, the enemy captures the **Sandbox**.

This means level selection becomes a strategic decision rather than simply choosing the next mission.

The player is deciding:

- What do I want?
- What can I afford to let the enemy have?
- Which enemy bonus will be most dangerous later?

---

# 8. Territories Benefit Whoever Owns Them

Territories can give different benefits depending on who controls them.

Example:

## Shed

Player owns it:

- Mechanical towers cost 15% less

Enemy owns it:

- Enemy waves contain more vehicles

## Sandbox

Player owns it:

- Barricades have additional health

Enemy owns it:

- Enemy forces gain sandbag positions or temporary cover

## Tree House

Player owns it:

- Better information about upcoming waves

Enemy owns it:

- Enemy wave composition becomes harder to predict

This allows the campaign state to directly alter individual tower-defense battles.

---

# 9. Mutually Exclusive Rewards

Some victories or discoveries can present a choice between two toys or upgrades.

Example:

## The Dog or the Robot

The player discovers two damaged toys but can only repair one.

### Toy Dog

- Fast
- Melee
- Chases enemies that break through defensive lines
- Good emergency interceptor

### Robot

- Slow
- Ranged
- Powerful laser
- Strong against armored enemies

The important twist:

> The enemy eventually gains the toy the player did not choose.

This means player choices create both:

- Player strengths
- Future enemy threats

The same idea can apply to:

- Towers
- Heroes
- Vehicles
- Abilities
- Territory upgrades
- Factions

---

# 10. Imperfect Information

Instead of always showing precise wave information, the game can sometimes provide incomplete scouting reports.

Traditional information:

```text
Wave 12:
14 infantry
8 armored enemies
2 bosses
```

Toy-world scouting:

```text
Scouts report something large moving through the flowerbed.

Vehicle tracks were found near the sandbox.

Unknown activity detected behind the shed.
```

The player then decides how much to prepare.

This keeps the player mentally engaged without requiring constant clicking.

Possible scouting quality:

- No intelligence
- Vague warning
- Enemy category known
- Approximate numbers
- Exact composition

Campaign territories and upgrades could improve scouting.

---

# 11. Quiet Time Is Part of the Game

The game should not attempt to eliminate passive moments.

Watching a successful defense work is one of the pleasures of tower defense.

The game can intentionally provide calm periods after significant decisions.

Example:

The player has:

- Built several towers
- Selected upgrades
- Chosen a lane to reinforce
- Used resources carefully

Now the player gets thirty seconds simply watching the system work.

Then something changes:

> **CLUNK**

A large wind-up robot appears behind the hedge.

The player becomes engaged again.

This creates a rhythm between calm observation and sudden decision points.

---

# 12. Potential Core Hook

A strong initial combination could be:

1. Traditional autonomous tower defense
2. Optional manual control of towers
3. A small number of active player abilities
4. A territory-based campaign map
5. Enemy capture of unchosen territories
6. Choices where the enemy may receive the rejected option

The central campaign rule could be:

> **Things you don't choose may become enemy assets.**

This fits naturally with the toy theme and creates consequences without requiring a highly complex grand-strategy layer.

---

# 13. Development Roadmap

The project should be built in layers.

Each phase should result in something playable before adding more systems.

---

## Phase 0 — Technical Playground

### Goal

Learn the required Godot workflows and establish the smallest reusable technical foundation.

### Build

- Small 3D test environment
- Camera controls
- Basic navigation path
- Enemy movement
- Simple tower targeting
- Projectile or hitscan attacks
- Health and damage
- Basic UI
- Restart level button

### Ignore for now

- Final art
- Campaign
- Manual tower control
- Complex upgrades
- Save system
- Story
- Multiple maps

### Success condition

One enemy can walk along a path and one tower can automatically shoot it.

---

# 14. Phase 1 — Minimal Tower Defense

### Goal

Create a complete but very small traditional tower-defense loop.

### Build

- Enemy waves
- Currency
- Tower placement
- Two or three tower types
- Tower upgrades
- Base health
- Win condition
- Lose condition
- Wave controls
- Basic sound effects

Possible first towers:

### Toy Soldier

- Cheap
- Fast attack
- Low damage

### Toy Tank

- Expensive
- Slow firing
- Area damage

### Lightning Toy

- Medium cost
- Chain attack

### Success condition

A complete 10–15 minute level can be played from start to finish.

This becomes the baseline against which later mechanics can be judged.

---

# 15. Phase 2 — Anti-Apathy Systems

### Goal

Test whether occasional player intervention improves engagement without destroying the relaxed pace.

### Add

- Manual control of one tower type
- Two player abilities
- One unusual enemy requiring attention

Suggested first implementation:

### Manual Tank Control

Click the tank to temporarily aim its cannon manually.

### Marble Spill

Area knockback ability.

### Big Hand

Move one tower to another valid location.

### Special Enemy

A dangerous but clearly telegraphed enemy such as a wind-up robot.

### Questions to test

- Does manual control feel rewarding?
- Do players feel forced to use it?
- How often should abilities become available?
- Are calm periods still enjoyable?
- Does the game retain its tower-defense identity?

### Success condition

The player regularly notices situations worth reacting to but does not feel required to constantly interact.

---

# 16. Phase 3 — Toy Identity

### Goal

Make the game feel distinctly like a toy-world tower defense rather than a generic tower defense using toy models.

### Add

- More toy-specific towers
- Toy-specific abilities
- Environmental interactions
- Garden prototype level
- Stronger visual language
- Scale cues

Possible environmental interactions:

- Rolling marble hazards
- Water from a sprinkler
- Falling building blocks
- Sandbox terrain
- Toy cars crossing lanes
- Garden hose creating temporary barriers

### Narrative experiment

After completing the level, briefly reveal the real garden and the children playing with the toys.

### Success condition

Someone seeing a short clip should immediately understand that the toy-world concept is central to the game.

---

# 17. Phase 4 — Attack and Defense Prototype

### Goal

Test whether pushing territory can coexist with tower-defense pacing.

### Add

- Friendly automatically spawning units
- Enemy defensive structures
- Capturable forward positions
- New tower placement zones unlocked by advancement
- Enemy counterattacks

### Keep scope small

Build this first as one experimental level rather than redesigning the whole game around it.

### Questions to test

- Does offensive pressure create interesting decisions?
- Is the player still mostly planning rather than micromanaging?
- Does territory movement make battles more dynamic?
- Is traditional defense still important?

### Success condition

The level creates meaningful decisions between investing in offense and maintaining defense.

---

# 18. Phase 5 — Campaign Map Prototype

### Goal

Connect several levels into a small strategic campaign.

### Build

A map with approximately 5–7 territories.

For example:

```text
                  [Tree House]
                       |
[Sandbox] — [Lawn] — [Patio]
     |           |
   [Shed]   [Flower Bed]
```

### Add

- Territory selection
- Persistent ownership
- Territory bonuses
- Basic campaign resources
- Enemy territory capture
- Save/load campaign state

### First campaign rule

When the player attacks one territory, the enemy takes or contests another.

### Success condition

Choosing the next level is itself an interesting decision.

---

# 19. Phase 6 — Enemy Gains Your Rejected Choices

### Goal

Create stronger consequences and campaign identity.

### Add

- Mutually exclusive rewards
- Rejected rewards enter an enemy pool
- Enemy uses those rewards in later battles

Example:

```text
Choose one:

[Repair Toy Dog]
[Repair Toy Robot]
```

Player chooses Toy Dog.

Later:

> Enemy forces have repaired the Robot.

This system can gradually expand to:

- Towers
- Units
- Abilities
- Territory upgrades
- Commanders
- Special weapons

### Success condition

Campaign decisions generate memorable consequences several battles later.

---

# 20. Phase 7 — Scouting and Imperfect Information

### Goal

Increase strategic attention without increasing mechanical activity.

### Add

- Scout reports
- Unknown wave compositions
- Recon upgrades
- Campaign locations that affect intelligence quality

Example information progression:

### Poor intelligence

> Something large is approaching.

### Medium intelligence

> Heavy mechanical units are approaching.

### Good intelligence

> Approximately three heavy robots are approaching from the sandbox route.

### Excellent intelligence

Exact enemy composition is shown.

### Success condition

The player makes meaningful preparation decisions based on uncertain information.

---

# 21. Phase 8 — Campaign Expansion

Only after the core systems are fun should the campaign grow substantially.

Potential additions:

- Branching campaign paths
- More territories
- Multiple gardens / houses
- Different enemy factions
- Persistent tower unlocks
- Toy collection system
- Difficulty modifiers
- Optional challenge battles
- Territory recapture
- Special campaign events
- Boss toys
- Multiple endings

---

# 22. Prototype Scope Recommendation

The first serious playable prototype should remain deliberately small.

## One Map

Garden / lawn.

## Three Towers

- Toy Soldier
- Toy Tank
- Lightning Toy

## Four Enemy Types

- Basic plastic soldier
- Fast toy car
- Armored enemy
- Wind-up robot

## Two Player Abilities

- Marble Spill
- Big Hand

## One Manually Controllable Tower

Toy Tank.

## One Complete Level

Approximately 10–15 minutes.

This should be enough to answer the most important early question:

> **Is the basic loop enjoyable when the game is mostly passive but occasionally asks for deliberate intervention?**

Do not build the campaign layer until that answer is yes.

---

# 23. Design Questions to Keep Open

These do not need answers yet.

### Tower Control

- Can every tower be manually controlled?
- Or only certain special towers?
- Is control unlimited?
- Does manual control consume a resource?

### Abilities

- Cooldowns?
- Limited uses per level?
- Shared energy resource?
- Earned through good defense?

### Economy

- Currency from kills?
- Passive income?
- Territory-based income?
- Economy towers?

### Pathing

- Fixed lanes?
- Player-created paths?
- Temporary rerouting?
- Multiple simultaneous routes?

### Campaign

- Can lost territories be reclaimed?
- Can the enemy attack player territory?
- Is there a campaign fail state?
- Does the enemy have its own visible campaign movement?

### Rejected Rewards

- Does the enemy always receive the rejected option?
- Is there a delay?
- Can the player prevent it?
- Can rejected toys appear as bosses?

### Tone

- Purely playful?
- Slightly nostalgic?
- Comedy?
- A child's imagination presented completely seriously?
- Gradual reveal of what is actually happening?

---

# 24. Guiding Principle

When evaluating a new mechanic, ask:

> **Does this give the player something meaningful to think about without forcing them to constantly do something?**

If yes, it probably fits the game.

If it mainly increases clicking, reaction speed, or micromanagement, it may work against the intended experience.

The game should reward attention more than activity.
