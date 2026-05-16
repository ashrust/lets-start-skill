#!/usr/bin/env bash
# init-tidy-branch.sh
# Create the tidy/cleanup-<date> branch, seed TIDY_LOG.md, confirm clean tree.

set -euo pipefail

# --- preflight ---

if ! command -v git >/dev/null 2>&1; then
  echo "error: git is not installed" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: not inside a git working tree" >&2
  exit 1
fi

# require clean tree — tidy must start from a known state
if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: working tree is not clean. Commit or stash before starting tidy." >&2
  git status --short >&2
  exit 1
fi

# detect base branch (main or master, fall back to current)
BASE_BRANCH=""
for candidate in main master; do
  if git show-ref --verify --quiet "refs/heads/$candidate"; then
    BASE_BRANCH="$candidate"
    break
  fi
done
if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  echo "note: no main/master branch found; using current branch '$BASE_BRANCH' as base" >&2
fi

# --- branch ---

DATE="$(date +%Y-%m-%d)"
BRANCH="tidy/cleanup-${DATE}"

if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  echo "error: branch ${BRANCH} already exists. Delete it or pick a different date." >&2
  exit 1
fi

git checkout -b "${BRANCH}" "${BASE_BRANCH}"

# --- seed log ---

LOG="TIDY_LOG.md"
if [[ -f "$LOG" ]]; then
  echo "warn: ${LOG} already exists; appending a new section instead of overwriting" >&2
  {
    echo ""
    echo "---"
    echo ""
  } >> "$LOG"
fi

cat >> "$LOG" <<EOF
# Tidy cleanup — ${DATE}

Branch: ${BRANCH}
Base:   ${BASE_BRANCH}
Stack:  (filled in by detect-stack.sh)

## Summary

(filled in at the end)

---

## Dimension 1: Dead code

### Removed

### Candidates

## Dimension 2: Duplication / DRY

### Consolidated

### Considered, not done

## Dimension 3: Defensive cruft

### Removed

### KEEP-with-comment

## Dimension 4: Legacy paths

### Removed

## Dimension 5: Comments and docstrings

### Removed

### Added

### Kept untouched

EOF

git add "$LOG"
git commit -m "tidy: initialize cleanup log for ${DATE}" --quiet

echo "✓ created branch:  ${BRANCH}"
echo "✓ seeded log:      ${LOG}"
echo "✓ base:            ${BASE_BRANCH}"
echo ""
echo "next: run scripts/detect-stack.sh"
