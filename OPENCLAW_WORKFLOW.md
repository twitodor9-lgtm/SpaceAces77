# OpenClaw Workflow for SpaceAces77

## Core Rule

Never work directly on main.

All AI work must happen on a dedicated OpenClaw branch.

## Main Safe Branch

The current safe OpenClaw branch is:

openclaw/safe-test

This branch is used as the safe AI testing base.

## Task Branch Naming

New AI task branches should start with:

openclaw/

Recommended format:

openclaw/<agent>/<task-name>

Examples:
- openclaw/chatgpt/godot-fix
- openclaw/grok/review-main-scene
- openclaw/coder/player-movement
- openclaw/blender/export-test
- openclaw/docs/update-workflow

Do NOT create branches under:

openclaw/safe-test/<task-name>

Reason:
openclaw/safe-test already exists as a branch name, and Git branch paths may conflict.

## Forbidden Without User Approval

Do not:
- work directly on main
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

1. Start from openclaw/safe-test or latest approved safe branch.
2. Create a dedicated task branch.
3. Understand the task.
4. Inspect relevant files.
5. Make a short plan.
6. Edit only necessary files.
7. Run checks if possible.
8. Show git diff.
9. Commit only after changes are clear.
10. Ask user before merge.

## Godot Rule

Do not randomly reorganize scenes, assets, node names, or folders.

Prefer small, reversible changes.

## Final Rule

Prepare work.
Do not merge without explicit user approval.

## Agent Behavior Rules

All agents must also follow:

docs/workflows/OPENCLAW_AGENT_RULES.md

Key behavior:
- state assumptions
- make minimal changes
- edit surgically
- define success before acting
- verify before reporting completion
