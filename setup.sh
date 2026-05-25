#!/bin/bash
# Creates real skill directories with symlinked SKILL.md files so Claude Code
# and Codex discover each skill at their host-specific skills root.
set -eu

usage() {
  cat <<'EOF'
Usage: bash setup.sh [--host claude|codex|auto]

Installs this repo's bundled skills into the selected host's skills directory.

  claude  -> ~/.claude/skills/<name>/SKILL.md
  codex   -> ~/.codex/skills/<name>/SKILL.md
  auto    -> infer from the repo location; pass --host when cloned elsewhere
EOF
}

HOST="auto"
HOST_EXPLICIT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --host)
      if [ $# -lt 2 ]; then
        echo "Missing value for --host (expected claude, codex, or auto)." >&2
        exit 1
      fi
      HOST="$2"
      HOST_EXPLICIT=1
      shift 2
      ;;
    --host=*)
      HOST="${1#--host=}"
      HOST_EXPLICIT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_PARENT="$(dirname "$REPO_DIR")"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
CODEX_SKILLS_DIR="$HOME/.codex/skills"

if [ "$HOST" = "auto" ]; then
  if [ "$REPO_PARENT" = "$CODEX_SKILLS_DIR" ]; then
    HOST="codex"
  elif [ "$REPO_PARENT" = "$CLAUDE_SKILLS_DIR" ]; then
    HOST="claude"
  else
    echo "Could not infer host from repo location: $REPO_DIR" >&2
    echo "Re-run with --host claude or --host codex." >&2
    exit 1
  fi
fi

case "$HOST" in
  claude)
    SKILLS_DIR="$CLAUDE_SKILLS_DIR"
    HOST_LABEL="Claude Code"
    ;;
  codex)
    SKILLS_DIR="$CODEX_SKILLS_DIR"
    HOST_LABEL="Codex"
    ;;
  *)
    echo "Unknown --host value: $HOST (expected claude, codex, or auto)." >&2
    exit 1
    ;;
esac

mkdir -p "$SKILLS_DIR"

if [ "$HOST_EXPLICIT" -eq 1 ] && [ "$REPO_PARENT" != "$SKILLS_DIR" ]; then
  echo "Note: installing symlinks into $SKILLS_DIR that point back to:"
  echo "  $REPO_DIR"
fi

echo "Installing bundled skills for $HOST_LABEL:"

for skill_dir in "$REPO_DIR"/*/; do
  skill_dir="${skill_dir%/}"
  [ -f "$skill_dir/SKILL.md" ] || continue
  name=$(basename "$skill_dir")
  target="$SKILLS_DIR/$name"

  # Stale single-skill install (real git repo) - refuse to clobber.
  if [ -d "$target/.git" ]; then
    echo "Found an older install at $target with its own .git directory." >&2
    echo "Remove it before re-running setup:" >&2
    echo "  rm -rf \"$target\"" >&2
    exit 1
  fi

  # Clean up a dangling symlink at $target so mkdir -p can proceed.
  if [ -L "$target" ] && [ ! -e "$target" ]; then
    rm "$target"
  fi

  mkdir -p "$target"

  # Refuse to overwrite a real (non-symlink) SKILL.md - likely user customization.
  if [ -e "$target/SKILL.md" ] && [ ! -L "$target/SKILL.md" ]; then
    echo "$target/SKILL.md is a real file, not a symlink. Refusing to overwrite." >&2
    echo "Move it aside and re-run:" >&2
    echo "  mv \"$target/SKILL.md\" \"$target/SKILL.md.bak\"" >&2
    exit 1
  fi

  ln -snf "$skill_dir/SKILL.md" "$target/SKILL.md"

  # Symlink sibling files/dirs (references/, scripts/, etc.) so multi-file
  # skills work after install. Same safety rule: never clobber a real file/dir.
  for sibling in "$skill_dir"/*; do
    [ -e "$sibling" ] || continue
    sname=$(basename "$sibling")
    [ "$sname" = "SKILL.md" ] && continue
    if [ -e "$target/$sname" ] && [ ! -L "$target/$sname" ]; then
      echo "$target/$sname is a real file/dir, not a symlink. Refusing to overwrite." >&2
      echo "Move it aside and re-run:" >&2
      echo "  mv \"$target/$sname\" \"$target/$sname.bak\"" >&2
      exit 1
    fi
    ln -snf "$sibling" "$target/$sname"
  done

  echo "  /$name"
done

echo ""
echo "Done. Type /lets-start in $HOST_LABEL to get started."
