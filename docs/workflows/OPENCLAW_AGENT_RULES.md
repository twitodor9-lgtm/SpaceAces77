# OpenClaw Agent Rules

These rules apply to AI agents working on this repository.

## 1. No Silent Assumptions

State assumptions clearly.
Do not guess silently.

Never guess:
- file paths
- branch names
- Godot node names
- APIs
- current project state
- balance values
- user intent

If something is unclear, ask or explicitly mark the assumption.

## 2. Minimal Safe Change

Make the smallest change that solves the task.

Do not:
- add speculative features
- refactor unrelated code
- rewrite whole files when a small patch is enough
- change balance unless explicitly asked
- change speed, damage, cooldowns, survivability, or enemy pressure without approval

## 3. Surgical File Editing

Touch only files that are approved for the task.

Every changed line must directly serve the requested change.

If unrelated problems are found:
- report them
- do not fix them automatically

## 4. Define Success Before Acting

Before implementation, define:
- what will change
- which files will change
- how success will be checked

After implementation, verify:
- git diff is small and relevant
- project still loads when possible
- relevant checks/tests pass when available
- no unrelated systems were changed

## 5. Git Safety

Never work directly on:

- main
- master

Safe base branch:

openclaw/safe-test

Task branch format:

openclaw/<agent>/<task-name>

Examples:

- openclaw/chatgpt/godot-fix
- openclaw/coder/player-movement
- openclaw/blender/export-test
- openclaw/docs/update-rules

Never merge without explicit user approval.

## 6. Godot Safety

Use GodotContextOutput as the source of truth when provided.

If context is partial:
- do not guess
- request more context
- or explain why the patch is unsafe

Prefer small safe patches.

For Godot plugin XML output:
- return exactly one xml code block
- no text before it
- no text after it
- keep the full GodotContextCommand inside that single block

If PatchFiles support is uncertain:
- prefer ReplaceFiles with a complete valid file

Never include conflict markers inside GDScript:

- <<<<<<<
- =======
- >>>>>>>

## 7. Security

Do not add secrets, tokens, API keys, passwords, or .env files.

Do not change:
- repository settings
- GitHub Actions
- secrets
- visibility
- permissions

without explicit user approval.

## 8. Final Response Rule

At the end of a coding or file-change task, report:

- files changed
- what changed
- how to test
- anything not verified
