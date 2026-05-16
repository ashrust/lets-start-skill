#!/bin/bash
# Creates real directories with symlinked SKILL.md files so Claude Code
# discovers each skill at ~/.claude/skills/<name>/SKILL.md
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(dirname "$REPO_DIR")"

# Sanity check: skills must live under ~/.claude/skills/ to be discovered.
if [ "$SKILLS_DIR" != "$HOME/.claude/skills" ]; then
  echo "⚠ Expected this repo at ~/.claude/skills/lets-start-skill, found it at:"
  echo "    $REPO_DIR"
  echo ""
  echo "  Symlinks would land in $SKILLS_DIR and Claude Code wouldn't discover them."
  echo "  Fix: rm -rf \"$REPO_DIR\" && git clone https://github.com/ashrust/lets-start-skill.git ~/.claude/skills/lets-start-skill"
  exit 1
fi

for skill_dir in "$REPO_DIR"/*/; do
  skill_dir="${skill_dir%/}"
  [ -f "$skill_dir/SKILL.md" ] || continue
  name=$(basename "$skill_dir")
  target="$SKILLS_DIR/$name"

  # Stale single-skill install (real git repo) — refuse to clobber.
  if [ -d "$target/.git" ]; then
    echo "⚠ Found an older install at $target with its own .git directory."
    echo "  Remove it before re-running setup:"
    echo "    rm -rf \"$target\""
    exit 1
  fi

  mkdir -p "$target"
  ln -snf "$skill_dir/SKILL.md" "$target/SKILL.md"
  echo "  ✓ /$name"
done

echo ""
echo "Done. Type /lets-start in Claude Code to get started."
