# SpaceAces77 - Enemy Template Spec

This file defines the intended template structure for future gameplay entities.

The goal is consistency:
- consistent combat fields
- consistent AR HUD behavior
- cleaner enemy creation
- cleaner future multiplayer support

---

## 1. enemy_base
Use for regular enemies.

### Typical examples
- basic air enemy
- interceptor
- simple turret-like enemy if treated as a standard combatant

### Expected responsibility
- basic combat entity behavior
- health / score / damage response
- optional AR HUD participation

### Standard fields
#### Combat
- `max_health`
- `player_damage_multiplier`
- `score_value`

#### AR HUD
- `show_in_ar_hud`
- `ar_threat_type`
- `ar_threat_text`

### Optional function
- `get_health_ratio()` if health should appear in the HUD

### Default policy
- normal fodder enemies: `show_in_ar_hud = false`
- elite / important regular enemies: can be enabled in inspector

---

## 2. monster_base
Use for named monsters or major creature threats.

### Typical examples
- VoidRaptor
- OctoWhale
- future rideable creatures

### Expected responsibility
- larger threat identity
- stronger encounter presence
- usually visible in tactical HUD
- good base for future riding systems

### Standard fields
#### Combat
- `max_health`
- `player_damage_multiplier`
- `score_value`

#### AR HUD
- `show_in_ar_hud = true`
- `ar_threat_type = "MONSTER"`
- `ar_threat_text`

### Required function
- `get_health_ratio()`

### Notes
- monsters should usually support AR visibility by default
- if a monster becomes rideable in the future, this template should remain compatible

---

## 3. boss_base
Use for bosses and major set-piece encounters.

### Typical examples
- WardenGiant
- future story bosses
- large encounter mechs / ships / beasts

### Expected responsibility
- central encounter target
- clear health tracking
- strong UI presence
- boss flow hooks

### Standard fields
#### Combat
- `max_health`
- `score_value`
- optional per-boss special damage rules

#### AR HUD
- `show_in_ar_hud = true`
- `ar_threat_type = "BOSS"`
- `ar_threat_text`

### Required function
- `get_health_ratio()`

### Recommended hooks
- boss death event
- phase progression hooks
- intro / outro hooks

---

## 4. hazard_base
Use for environmental or semi-environmental threats.

### Typical examples
- ground mines
- worm spawner logic
- trap systems
- special map threats

### Expected responsibility
- not every hazard needs HP
- not every hazard should appear in HUD
- may be event-driven, timed, or triggered by player position

### Standard fields
#### AR HUD
- `show_in_ar_hud = false` by default
- `ar_threat_type = "HAZARD"`
- `ar_threat_text`

### Optional
- `get_health_ratio()` only if the hazard is truly damageable and important enough to show health

### Notes
- hazards should not clutter the HUD unless they matter tactically
- short-lived hazards should usually avoid permanent HUD presence

---

## 5. Future rideable creature layer
Not required yet, but should be planned for.

### Why
Some monsters may later become rideable or controllable.
That means they may need more than combat + AR fields.

### Future fields to consider
- `is_rideable`
- `mount_priority`
- `rider_socket`
- `mount_ui_name`
- ownership / state hooks

### Design goal
Rideable creatures should eventually build on top of monster logic instead of inventing a separate incompatible path.

---

## Shared AR HUD Rule
Any entity that may appear in the tactical HUD should support:
- `show_in_ar_hud`
- `ar_threat_type`
- `ar_threat_text`

If it should show health in the HUD, it should also support:
- `get_health_ratio()`

---

## Long-term Architecture Goal
Move these shared fields into common base scripts or a shared target interface so future entities inherit the same behavior by default.

Recommended direction:
- `enemy_base.gd`
- `monster_base.gd`
- `boss_base.gd`
- `hazard_base.gd`

Until then, this file is the rulebook for future entity creation.
