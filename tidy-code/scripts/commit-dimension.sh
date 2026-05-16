#!/usr/bin/env bash
# commit-dimension.sh <dimension-tag> <commit-message>
# Run verify.sh; commit only if it passes. Refuses to commit on failure.
# This is the only sanctioned way to commit a dimension — never `git commit` directly
# after a tidy edit, because verify must gate every dimension.

set -euo pipefail

DIM="${1:-}"
MSG="${2:-}"
if [[ -z "$DIM" || -z "$MSG" ]]; then
  echo "usage: commit-dimension.sh <dead-code|dry|defensive|legacy|comments> '<message>'" >&2
  exit 2
fi

case "$DIM" in
  dead-code|dry|defensive|legacy|comments) ;;
  *) echo "error: dimension must be one of: dead-code, dry, defensive, legacy, comments" >&2; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! "$SCRIPT_DIR/verify.sh"; then
  echo ""
  echo "✗ verify failed — NOT committing." >&2
  echo "  fix the failures or revert your edits, then try again." >&2
  exit 1
fi

if [[ -z "$(git status --porcelain)" ]]; then
  echo "no changes to commit for dimension '$DIM' — skipping commit" >&2
  exit 0
fi

git add -A
git commit -m "tidy(${DIM}): ${MSG}"
echo "✓ committed: tidy(${DIM}): ${MSG}"
