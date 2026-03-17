# SpaceAces Architecture Notes

## Core flow

- `scripts/GameState.gd` controls current stage index and scene switching.
- `main.gd` is the gameplay orchestrator for stage scenes.
- `scripts/Balance.gd` provides per-stage rules and tuning values.
- `player.gd` owns flight, weapons, abilities, damage/lives, and some temporary UI hooks.
- `ui_root.gd` is the active gameplay UI root.
- `low_cover_controller.gd` is now the single source of truth for low-altitude state.

## Stage scene structure

Typical stage scenes contain:
- `Player`
- `GroundLine`
- `EnemySpawnTimer`
- `GroundEnemyTimer`
- `CloudSpawner`
- `WormSpawner`
- `MonsterDirector`
- `LowCoverController`
- `UIRoot`
- `Background`

This means stages are currently prefab-like compositions around `main.gd`.

## What each major script owns

### `main.gd`
Owns:
- stage bootstrap
- UI hookup
- background hookup
- timer hookup
- boss enable/disable
- monster director setup
- stage rule application
- enemy spawning
- score updates
- stage clear flow
- void raptor spawning

Concern:
- too many responsibilities in one script
- partial overlap with `MonsterDirector`

### `player.gd`
Owns:
- movement / rotation
- bullets / bombs
- loop maneuver
- ability input dispatch
- ability label display
- lives / invulnerability
- deflector shield logic
- cloud hidden state
- wraparound and ground response

Concern:
- mixes gameplay, HUD lookup, and ability dispatch in one place
- knows too much about UI node structure

### `ui_root.gd`
Owns:
- score/stage display
- star punch bar
- low altitude label display
- boss bar
- stage clear button flow

Current state:
- much cleaner now that low-altitude detection is no longer duplicated here

### `low_cover_controller.gd`
Owns:
- computing whether player is in low-altitude / low-cover zone
- writes result into `player.is_hidden_low`

Current state:
- should remain the single source of truth for this feature

### `MonsterRegistry` + `MonsterDirector`

`monster_registry.gd`
- maps monster ids to scenes
- instantiates monster scenes by id

`monster_director.gd`
- resolves registry
- ensures one active instance per monster id via `spawn_once`
- currently auto-spawns `void_raptor` on stage 2

Concern:
- there is overlap with `main.gd`, which also spawns monsters directly
- current usage is inconsistent: some monsters use director/registry, others are spawned directly from `main.gd` or test arena

### `Tests/test_arena.gd`
Owns:
- sandbox/test harness
- custom debug UI
- manual spawning buttons
- stage-rule simulation via `GameBalance.stage_index`

Concern:
- currently duplicates some runtime assembly logic from stage scenes
- useful, but becoming a second orchestration path

## Biggest architectural issues

1. **Spawning is split across multiple systems**
   - `main.gd`
   - `MonsterDirector`
   - `WormSpawner`
   - `Tests/test_arena.gd`

2. **Player still knows too much about HUD structure**
   - direct UI node resolution inside gameplay script

3. **Legacy / duplicate paths still exist**
   - `hud.gd` and `ui_root.gd` overlap conceptually
   - test arena assembles systems manually instead of reusing a clearer shared setup path

4. **Stage scenes are composition-heavy and rely on exact node names**
   - `GroundLine`, `UIRoot`, timers, etc.
   - this works, but is brittle

## Recommended cleanup order

### Phase 1 - Stabilize ownership
- Keep `low_cover_controller.gd` as sole low-altitude authority
- Keep `ui_root.gd` as sole gameplay HUD presenter
- Treat `hud.gd` as legacy unless still actively instantiated somewhere important

### Phase 2 - Normalize monster spawning
- Decide one policy:
  - either all special monsters go through `MonsterDirector + MonsterRegistry`
  - or keep direct spawning in `main.gd` and use registry only for test tools
- Best option: special monsters through director/registry, generic enemies via local stage spawners

### Phase 3 - Reduce player/UI coupling
- move gameplay HUD presentation behind methods/signals on `UIRoot`
- player should avoid searching the scene tree for labels when possible

### Phase 4 - Improve test arena reuse
- make sandbox use the same spawn/services patterns as real stages
- avoid custom one-off paths when a shared service exists

## Practical current recommendation

Short version:
- `GameState` = navigation
- `Balance` = tuning
- `main.gd` = stage orchestration
- `player.gd` = player gameplay only
- `ui_root.gd` = HUD only
- `low_cover_controller.gd` = low-altitude state only
- `MonsterDirector/Registry` = named special-monster spawning only
- `test_arena.gd` = debug shell around those same systems

## Files worth auditing next

- `Enemies/Monsters/VoidRaptor/*`
- `Enemies/Monsters/OctoWhale/*`
- `Enemies/BOSS/*`
- `background_controller.gd` / background scene flow
- whether `hud.gd` is still actually needed in runtime
