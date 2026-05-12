# OpenClaw Workflow for SpaceAces77

## Core Rule

Never work directly on main.

All AI work must happen on a dedicated branch.

## Safe Branches

Use branches named:

openclaw-<agent>-<task>

Examples:
- openclaw-chatgpt-safe-test
- openclaw-godot-fix
- openclaw-blender-export
- openclaw-grok-review

## Forbidden Without User Approval

Do not:
- merge into main
- force push
- delete branches
- delete important files
- change GitHub Actions
- change secrets
- add API keys or tokens
- upload .env files
- change repository visibility
- change repository settings

## Required Workflow

1. Understand the task.
2. Inspect relevant files.
3. Make a short plan.
4. Edit only necessary files.
5. Run checks if possible.
6. Show git diff.
7. Commit only after changes are clear.
8. Ask user before merge.

## Godot Rule

Do not randomly reorganize scenes, assets, or node names.

Prefer small, reversible changes.

## Final Rule

Prepare work. Do not merge without explicit approval.
