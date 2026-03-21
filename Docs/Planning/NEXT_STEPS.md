# SpaceAces77 - Practical Next Steps

## Track A - Immediate polish (current branch)
### 1. Finish HUD readability
- add a label next to the health bar
- show whether the tracked target is a boss or monster
- optionally show the target's name

### 2. Verify big creature health bars
Test in arena and real stages:
- WardenGiant
- OctoWhale
- VoidRaptor
- decide whether SpaceWorm should keep or lose its bar for now

### 3. Finish stage rebuild direction
- complete `Stage01_new`
- build `Stage02_new`
- build `Stage03_new`
- keep all of them aligned with `gameplay_shell.tscn`

---

## Track B - Vertical Slice preparation
### 4. Define the crash rule
Decide exactly when the player transitions from air to crash.
Questions:
- on life loss?
- on specific damage threshold?
- only in selected stages?
- is crash a second chance, a phase shift, or a scripted event?

### 5. Build a minimal crash prototype
- trigger crash state
- disable normal flight
- transition camera / control mode
- land player on ground safely

### 6. Build a minimal ground prototype
- basic movement on ground
- one weapon or action
- one simple ground enemy encounter
- one small test area

---

## Track C - Rideable creature prototype
### 7. Pick the first mount
Recommended first mount:
- VoidRaptor

### 8. Prototype mount interaction
- approach creature
- press interaction
- mount state begins
- movement changes
- dismount / loss condition

### 9. Decide mount design rules
For every rideable creature decide:
- how player mounts it
- how long it can be used
- what special movement it gives
- what attack it gives
- what causes losing it

---

## Track D - Multiplayer-safe cleanup
### 10. Reduce single-player assumptions
Over time replace direct single-player assumptions with more general systems:
- target selection
- current active player reference
- ownership/state for mounts
- enemy logic that can choose between multiple players

### 11. Mark systems that are already multiplayer-sensitive
Examples:
- player targeting
- UI ownership
- camera behavior
- crash transitions
- rideable creatures
- score and respawn logic

---

## Track E - AR HUD enemy checklist
### 12. Make AR HUD support part of the enemy template
For any future enemy, monster, boss, or rideable creature that should appear in the HUD, verify:
- `show_in_ar_hud`
- `ar_threat_type`
- `ar_threat_text`
- `get_health_ratio()` if it should show health

### 13. Default policy for new content
- normal fodder enemies: off by default
- bosses / major monsters / rideable creatures: on by default
- special turrets or elite threats: case by case in inspector

### 14. Long-term cleanup goal
Move AR HUD fields into a shared base script or common target layer, so future enemies inherit HUD compatibility automatically.

---

## Recommended order for the next few work sessions
### Session 1
- health bar label / target name polish
- confirm boss + monster bars feel good

### Session 2
- finish `Stage01_new`
- confirm stage shell flow is stable
- tune Stage 1 core shmup pacing

### Session 3
- build a first crash prototype in arena or a test scene

### Session 4
- build the first ground control prototype

### Session 5
- mount prototype for VoidRaptor

### Future session
- prototype rescue / extraction flow for grounded players
- decide how AI rescue and player rescue differ
- connect extraction concept to future co-op structure

---

## MVP definition
The first real milestone should be:
- one polished air stage
- crash event
- short ground sequence
- one rideable VoidRaptor
- one boss encounter

If this milestone works, the larger game direction is validated.

## Track F - FX pipeline and polish discipline
### 15. Define the reusable FX pipeline
Document and follow three tiers:
- shared runtime FX
- editable component FX
- special set-piece FX

### 16. Promote repeated effects into reusable assets
If an effect is reused across multiple enemies or players, move it toward:
- shared script utility
- reusable FX scene
- per-enemy/per-player presets

### 17. Keep gameplay and FX ownership separate
- gameplay triggers the effect
- FX components own appearance, color, scale, and animation
- prefer editor-tunable nodes for assets that will need art iteration
