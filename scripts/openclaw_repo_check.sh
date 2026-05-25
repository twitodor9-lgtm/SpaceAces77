#!/usr/bin/env bash
set -e

echo "== OpenClaw Repo Check =="

echo
echo "Branch:"
CURRENT_BRANCH="$(git branch --show-current)"
echo "$CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
  echo "ERROR: You are on main/master. AI agents must not work here."
  exit 1
fi

echo
echo "Git status:"
git status --short

echo
echo "Godot project:"
if [ -f "project.godot" ]; then
  echo "OK: project.godot found"
else
  echo "WARNING: project.godot not found"
fi

echo
echo "File counts:"
find . \( -path "./.git" -o -path "./.godot" -o -path "./PNGStarJets" -o -path "./images" -o -path "./addons" -o -path "./Abilities" \) -prune -o -name "*.gd" -print | wc -l | xargs echo "GDScript files:"
find . \( -path "./.git" -o -path "./.godot" -o -path "./PNGStarJets" -o -path "./images" -o -path "./addons" -o -path "./Abilities" \) -prune -o -name "*.tscn" -print | wc -l | xargs echo "Scene files:"
find . \( -path "./.git" -o -path "./.godot" -o -path "./PNGStarJets" -o -path "./images" -o -path "./addons" -o -path "./Abilities" \) -prune -o -name "*.tres" -print | wc -l | xargs echo "Resource files:"

echo
echo "Secret scan:"
grep -RniE "api_key|apikey|token|secret|password|OPENAI|GROQ|GITHUB|ANTHROPIC" . \
  --exclude-dir=.git \
  --exclude-dir=.godot \
  --exclude-dir=.import \
  --exclude-dir=imported \
  --exclude-dir=PNGStarJets \
  --exclude-dir=images \
  --exclude-dir=addons \
  --exclude-dir=Abilities \
  --exclude="*.import" \
  --exclude="*.uid" \
  --exclude="*.tmp" \
  --exclude="*.png" \
  --exclude="*.jpg" \
  --exclude="*.jpeg" \
  --exclude="*.gif" \
  --exclude="*.blend" \
  --exclude="*.blend1" \
  | head -80 || true

echo
echo "Done."
