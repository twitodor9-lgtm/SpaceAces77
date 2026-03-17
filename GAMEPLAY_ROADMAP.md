# SpaceAces77 - Gameplay Roadmap

## Vision
SpaceAces77 starts as a fast air-combat game, but grows into a game with:
- air combat
- crash-to-ground transitions
- ground combat in a more open space
- rideable enemies/creatures
- boss and monster encounters
- future co-op / network multiplayer

The goal is not to build all of that at once.
The goal is to build it in layers, while keeping the project stable.

---

## Core Design Pillar
**Air combat is the entry fantasy.**
The twist is that the game does not end there.
When the player is damaged badly enough, gameplay can shift:
- from air
- to crash
- to ground survival/combat
- to creature interaction and recovery

That transition is the heart of the game's identity.

---

## Phase 1 - Stable Air Combat
### Goal
Make the current flying game fun and readable on its own.

### Includes
- player flight and shooting feel
- enemy and monster tuning
- boss fights
- low altitude / low cover rules
- worm and hazard behavior
- clean HUD and health bars for bosses / major monsters
- arena parity with gameplay rules

### Success condition
If development stopped here, the game would still already be playable and enjoyable.

---

## Phase 2 - Clean Systems Foundation
### Goal
Prepare the codebase so new gameplay layers do not become chaos.

### Includes
- shared gameplay shell
- cleaner stage structure
- shared runtime setup
- consistent inspector tuning for enemies
- cleaner UI responsibilities
- fewer duplicated systems

### Success condition
Adding new gameplay systems becomes easier instead of scarier.

---

## Phase 3 - Crash Transition
### Goal
Introduce the first major mode shift.

### Player fantasy
The plane is hit, the player crashes, and gameplay changes instead of simply ending.

### MVP
- crash trigger state
- fall / transition sequence
- controlled arrival to ground gameplay
- temporary change in controls and rules

### Success condition
The game starts feeling like more than a traditional shooter.

---

## Phase 4 - Ground Mode MVP
### Goal
Build a small but fun ground gameplay layer.

### MVP
- basic ground movement
- basic ground combat or survival tools
- some ground enemies / hazards
- more open terrain than normal stage flow
- readable state transition from air to ground

### Important note
This should start as a focused combat/traversal slice, not a giant open world.

### Success condition
Ground gameplay feels intentional, not like a weak side mode.

---

## Phase 5 - Rideable Creature Prototype
### Goal
Prove that riding enemies/creatures is actually fun.

### Best first candidate
**VoidRaptor**

### Why
- clear movement profile
- understandable shape and role
- easier first mount than the worm

### MVP
- approach creature
- mount it
- gain a temporary movement/combat style
- dismount or lose it

### Success condition
The mount mechanic feels exciting and readable.

---

## Phase 6 - Loop Integration
### Goal
Connect the systems into a real gameplay loop.

### Example loop
1. Air combat
2. Heavy damage / crash
3. Ground combat or survival
4. Ride a creature / gain advantage
5. Escape, relaunch, or progress

### Success condition
The game has a unique identity beyond its individual features.

---

## Phase 7 - Multiplayer-Friendly Architecture
### Goal
Avoid building everything around one hardcoded player.

### Design rule
Every major new system should ask:
**Will this still make sense with 2 players?**

### Should become more general over time
- targeting systems
- damage systems
- health systems
- riding ownership
- crash transitions
- UI ownership / player references
- respawn / recovery flow

### Should be avoided
- too much `get_first_node_in_group("player")`
- UI that assumes only one player forever
- gameplay logic that mixes presentation with authority/state

### Success condition
Future co-op becomes possible without rebuilding everything from scratch.

---

## Phase 8 - Local Co-op Prototype
### Goal
Test whether the game is fun with more than one player before full networking.

### MVP
- 2 local players or a very small co-op test
- enemy targeting that works with multiple players
- shared/adjusted camera idea
- mount interaction rules with more than one player

### Success condition
Co-op feels worth pursuing.

---

## Phase 9 - Online Co-op / Network Multiplayer
### Goal
Add networked multiplayer after the core game loop works well.

### Recommended scope
- co-op first
- 2 to 4 players
- session/mission based
- host-authoritative

### Not recommended at first
- PvP first
- giant persistent world first
- full online sandbox first

### Success condition
The game supports online co-op without collapsing under sync complexity.

---

## Health Bar Policy
### Use health bars for
- bosses
- major monsters
- rideable creatures
- elite enemies

### Usually avoid health bars for
- common fodder enemies
- tiny hazards
- disposable one-hit threats

This helps the player understand what matters without cluttering the screen.

---

## Recommended MVP Slice for the Whole Vision
If the game had to prove itself with one slice, it should include:
- one strong air-combat stage
- one crash transition
- one small ground segment
- one rideable creature (start with VoidRaptor)
- one boss
- worm / low-altitude hazard system
- clear UI for life, bosses, and major monsters
- arena for rapid iteration

If that slice feels good, the bigger vision is real.

---

## Development Principle
Do not build the whole dream at once.
Build the smallest playable version of the dream first.
