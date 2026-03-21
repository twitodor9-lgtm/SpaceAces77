# Air Enemy Balance Snapshot

Short reference so we do not need to inspect scenes/scripts every time.

## Air enemies

- **Regular Enemy**
  - Scene: `Enemies/enemy.tscn`
  - HP: `10`
  - Bullet speed: `400.0`
  - Fire interval: `0.8`
  - Turn rate: `1.0`
  - Max speed: `170.0`
  - Shots to kill with regular bullet: `10`

- **Interceptor**
  - Scene: `Enemies/interceptor.tscn`
  - HP: `12`
  - Bullet speed: `460.0`
  - Fire interval: `0.65`
  - Turn rate: `1.5`
  - Engage turn rate: `2.5`
  - Base speed: `190.0`
  - Max speed: `240.0`
  - Shots to kill with regular bullet: `12`

## Player damage sources vs air enemies

- **Regular bullet**
  - Script: `Bullet.gd`
  - Damage: `1`
  - Result:
    - Regular Enemy dies in `10` hits
    - Interceptor dies in `12` hits

- **Star Punch / Meteor**
  - Ability scene: `Abilities/Meteor.tscn`
  - Script: `meteor.gd`
  - Damage: `9999`
  - Result: one-shot kill on current air enemies by design

- **Dolphin Wave**
  - Script: `Abilities/DolphinWave/dolphin_wave.gd`
  - Damage: `9999`
  - Result: one-shot kill on current air enemies by design

## Important implementation note

- In `enemy.gd`, runtime health is initialized from `max_health` in `_ready()`.
- Therefore `max_health` is the value that matters for actual gameplay.
- The old confusing `_health = 15` override in `enemy.tscn` was removed; the regular enemy now explicitly sets `max_health = 10` in the scene.

## Current practical conclusion

- **Regular bullets are not one-shotting air enemies.**
- **Abilities with `9999` damage are one-shotting air enemies intentionally.**
- If an air enemy appears to die in one hit outside those abilities, inspect:
  - which projectile actually hit,
  - whether multiple hits stacked quickly,
  - or whether a different enemy scene has different HP.
