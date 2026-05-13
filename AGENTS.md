# AGENTS.md - SpaceAces77

This is the project-specific agent entry file.

It contains no private user memory.

## Before Doing Work

Read:

1. `OPENCLAW_WORKFLOW.md`
2. `docs/workflows/OPENCLAW_AGENT_RULES.md`

## Core Rules

- Never work directly on `main` or `master`.
- Use `openclaw/safe-test` as the safe base branch.
- Use task branches named `openclaw/<agent>/<task-name>`.
- Make minimal, surgical changes.
- Do not change balance unless explicitly asked.
- Do not add secrets, tokens, passwords, or `.env` files.
- Show the diff and checks before merge.
- Never merge without explicit user approval.

## Godot Rule

When Godot context is provided, treat it as the source of truth.

If context is partial, do not guess.
