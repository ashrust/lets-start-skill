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
  echo "  Fix: move this directory to ~/.claude/skills/lets-start-skill and re-run."
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

  # Clean up a dangling symlink at $target so mkdir -p can proceed.
  if [ -L "$target" ] && [ ! -e "$target" ]; then
    rm "$target"
  fi

  mkdir -p "$target"

  # Refuse to overwrite a real (non-symlink) SKILL.md — likely user customization.
  if [ -e "$target/SKILL.md" ] && [ ! -L "$target/SKILL.md" ]; then
    echo "⚠ $target/SKILL.md is a real file, not a symlink. Refusing to overwrite."
    echo "  Move it aside and re-run: mv \"$target/SKILL.md\" \"$target/SKILL.md.bak\""
    exit 1
  fi

  ln -snf "$skill_dir/SKILL.md" "$target/SKILL.md"
  echo "  ✓ /$name"
done

echo ""
echo "Done. Type /lets-start in Claude Code to get started."
