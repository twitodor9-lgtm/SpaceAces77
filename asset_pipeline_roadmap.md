# Asset Pipeline Roadmap

## Goal
Build a fast, flexible, legally safe asset pipeline for the project without modeling everything from scratch.

---

## Main Strategy

### 1. Characters / Enemies / Creature Bases
**Preferred sources**
- Quaternius
- Poly Pizza
- OpenGameArt (only if license is clear)

**Recommended use**
- Start from a base model
- Modify proportions and silhouette
- Add project-specific identity: helmet, scarf, jetpack, weapons, tail, gear
- Clean up in Blender
- Export as GLB or render to 2D when needed

**Use for this project**
- enemy bases
- creature variations
- humanoid and animal blockouts

---

### 2. Environments / Trees / Rocks / Props / Stage Pieces
**Preferred sources**
- Poly Haven
- Kenney
- Quaternius

**Recommended use**
- Build stage kits from existing CC0 assets
- Combine and simplify in Blender
- Adjust scale, color, and readability
- Use for 2.5D environment building or 2D renders

**Use for this project**
- crash site environment
- trees, rocks, ground props
- modular stage pieces
- background dressing

---

### 3. License Tracking
Every external asset must be registered in:
`asset_license_registry.md`

**Rule**
If the license is not clear, do not use the asset in the project.

---

## Workflow

### Step A — Find
- Search for a good base asset
- Prefer CC0
- Save source link immediately

### Step B — Check
- silhouette
- editability
- style fit
- commercial use
- attribution requirement

### Step C — Blender Cleanup
- remove unwanted parts
- fix proportions
- combine parts
- rename cleanly
- assign basic materials

### Step D — Export
- GLB for working assets
- PNG/sheets for render-to-2D workflow if needed

### Step E — Register
Update:
`asset_license_registry.md`

---

## Source Priority

### Character / Enemy Sources
1. Quaternius
2. Poly Pizza
3. OpenGameArt (carefully)

### Environment / Stage Sources
1. Poly Haven
2. Kenney
3. Quaternius

---

## Rules of Use

- Prefer **CC0**
- Use **CC-BY** only if credit is manageable
- Avoid **NC / ND / Editorial**
- Do not rely on unclear AI asset sites
- AI models are allowed as base/reference only until terms are verified
- Keep both source files and cleaned project files

---

## Definition of Done
An external asset is approved only if:
- source is documented
- license is documented
- Blender cleanup is done
- export file is saved
- project use is defined
- attribution need is known