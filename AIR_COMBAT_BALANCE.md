# Air Combat Balance v1

Working design note for tuning flight combat before writing permanent architecture rules.

## Goal

The player should keep a **qualitative advantage** over air enemies:
- better control
- better repositioning
- better burst tools
- better defensive windows

Air enemies should create pressure through:
- numbers
- angle coverage
- projectile presence
- forcing mistakes

Not through permanent superiority over the player ship.

## Core balance model

We use three top-level concepts:

### 1. Enemy Pressure
How much real combat pressure enemies create.

Built from:
- enemy count
- fire interval
- projectile speed
- spread / effective accuracy
- burst / reload cycle
- active threat angles
- special behaviors (interceptor pressure, missiles, hazards)

### 2. Player Survivability
How much punishment and recovery room the player has.

Built from:
- lives
- invulnerability windows
- movement escape potential
- cover effectiveness
- defensive abilities

### 3. Player Control
How much the player controls the pace of the fight.

Built from:
- damage output
- projectile reliability
- mobility / turning
- loop / wrap / turbo / jump tools
- crowd clear / burst abilities

## Balance rule

Normal solo combat should feel fair when:

`PlayerControl + PlayerSurvivability > EnemyPressure`

Target feel bands:
- comfortable: `1.25x - 1.45x`
- tense but fair: `1.10x - 1.25x`
- oppressive / likely overtuned: `< 1.0x`

## Variables we currently care about

### Player-side
- lives
- invulnerability time
- forward speed
- rotation speed
- bullet damage
- bullet speed
- fire rate
- spread
- ability cooldowns
- ability uptime
- defensive uptime
- reposition tools

### Enemy-side
- HP
- base/max speed
- turn rate / engage turn rate
- fire interval
- reload time
- clip size
- bullet speed
- missile speed
- aim spread
- burst behavior
- special pressure role

### Arena / rules-side
- low cover enabled
- low cover accuracy multiplier
- hidden blocks fire
- spawn density
- simultaneous threat angles
- telegraph time

## Current verified facts

### Air enemies
- **Regular Enemy**
  - HP: `10`
  - Max speed: `170.0`
  - Bullet speed: `400.0`
  - Fire interval: `0.8`
  - Threat budget draft: `1.0`

- **Interceptor**
  - HP: `12`
  - Base speed: `190.0`
  - Max speed: `240.0`
  - Bullet speed: `460.0`
  - Fire interval: `0.65`
  - Threat budget draft: `1.6`

### Player damage vs air enemies
- regular bullet damage: `1`
- regular enemy dies in `10` bullet hits
- interceptor dies in `12` bullet hits
- Star Punch / meteor damage: `9999` (intentional one-shot)
- Dolphin Wave damage: `9999` (intentional one-shot)

## Threat budget draft

Use this for quick encounter sanity checks.

- Regular Enemy = `1.0`
- Interceptor = `1.6`
- Missile-heavy air enemy (future placeholder) = `1.8`

Suggested solo encounter bands:
- light pressure: `2.0 - 3.0`
- normal pressure: `3.0 - 4.5`
- intense pressure: `5.0 - 6.0`

Examples:
- 3 regular enemies = `3.0`
- 1 interceptor + 2 regulars = `3.6`
- 2 interceptors + 1 regular = `4.2`

## Low cover / hidden rules

### Hidden
Verified behavior:
- hidden currently blocks air-enemy fire attempts

### Low cover
Verified behavior:
- low cover is detected through `low_cover_controller.gd`
- air enemy telemetry shows the low-cover multiplier affects firing windows and spread
- with `low_cover_accuracy_mul = 0.2`, observed behavior included:
  - allowed firing angle reduced from `30°` to `6°`
  - spread increased to roughly `14.6°`

Interpretation:
- low cover is now a real tactical defense tool, not just a visual state

## Telemetry status

Current telemetry is in `Enemies/enemy.gd` and reports:
- `blocked_hidden`
- `blocked_low_cover`
- `blocked_angle`
- `fired`
- `reload_start`

This should be used to validate tuning before promoting values into permanent architecture docs.

## Multiplayer scaling draft

Do not scale linearly by player count.

Use:

`EffectivePlayers = 1 + 0.75 * (N - 1)`

Then scale mainly through:
- encounter budget
- enemy count
- moderate HP increase
- only small accuracy increase

Avoid solving multiplayer by massively increasing enemy damage.

## Current recommendation

Before copying this into long-term architecture notes:
1. validate low-cover feel in sandbox
2. validate interceptor pressure and firing angles
3. refine threat budgets from playtests
4. only then promote the stable parts into `ARCHITECTURE_NOTES.md`
