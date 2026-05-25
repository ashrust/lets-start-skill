#!/usr/bin/env bash
set -eu

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

copy_repo() {
  dest="$1"
  mkdir -p "$dest"
  (
    cd "$REPO_DIR"
    tar \
      --exclude .git \
      --exclude .claude \
      --exclude .worktrees \
      -cf - .
  ) | (
    cd "$dest"
    tar -xf -
  )
}

assert_file() {
  if [ ! -f "$1" ]; then
    echo "missing file: $1" >&2
    exit 1
  fi
}

assert_no_file() {
  if [ -e "$1" ]; then
    echo "unexpected file: $1" >&2
    exit 1
  fi
}

assert_contains() {
  if ! grep -q "$2" "$1"; then
    echo "expected $1 to contain: $2" >&2
    exit 1
  fi
}

run_codex_install() {
  tmp="$(mktemp -d /tmp/lets-start-codex.XXXXXX)"
  mkdir -p "$tmp/.codex/skills"
  copy_repo "$tmp/.codex/skills/lets-start-skill"

  HOME="$tmp" bash "$tmp/.codex/skills/lets-start-skill/setup.sh" --host codex >/tmp/lets-start-codex.log

  assert_file "$tmp/.codex/skills/lets-start/SKILL.md"
  assert_file "$tmp/.codex/skills/audit-tests/SKILL.md"
  assert_file "$tmp/.codex/skills/autoclean/SKILL.md"
  assert_file "$tmp/.codex/skills/parallelize/SKILL.md"
  assert_file "$tmp/.codex/skills/ship-then-deploy/SKILL.md"
  assert_file "$tmp/.codex/skills/tidy-code/SKILL.md"
  assert_contains /tmp/lets-start-codex.log "Done. Type /lets-start in Codex"
  assert_no_file "$tmp/.claude/skills/lets-start/SKILL.md"
}

run_claude_install() {
  tmp="$(mktemp -d /tmp/lets-start-claude.XXXXXX)"
  mkdir -p "$tmp/.claude/skills"
  copy_repo "$tmp/.claude/skills/lets-start-skill"

  HOME="$tmp" bash "$tmp/.claude/skills/lets-start-skill/setup.sh" --host claude >/tmp/lets-start-claude.log

  assert_file "$tmp/.claude/skills/lets-start/SKILL.md"
  assert_file "$tmp/.claude/skills/audit-tests/SKILL.md"
  assert_file "$tmp/.claude/skills/autoclean/SKILL.md"
  assert_file "$tmp/.claude/skills/parallelize/SKILL.md"
  assert_file "$tmp/.claude/skills/ship-then-deploy/SKILL.md"
  assert_file "$tmp/.claude/skills/tidy-code/SKILL.md"
  assert_contains /tmp/lets-start-claude.log "Done. Type /lets-start in Claude Code"
  assert_no_file "$tmp/.codex/skills/lets-start/SKILL.md"
}

run_auto_detection() {
  tmp="$(mktemp -d /tmp/lets-start-auto.XXXXXX)"
  mkdir -p "$tmp/.codex/skills"
  copy_repo "$tmp/.codex/skills/lets-start-skill"
  HOME="$tmp" bash "$tmp/.codex/skills/lets-start-skill/setup.sh" >/tmp/lets-start-auto.log
  assert_contains /tmp/lets-start-auto.log "Installing bundled skills for Codex"
  assert_file "$tmp/.codex/skills/lets-start/SKILL.md"
  assert_file "$tmp/.codex/skills/ship-then-deploy/SKILL.md"
}

run_auto_requires_host_when_external() {
  tmp="$(mktemp -d /tmp/lets-start-external.XXXXXX)"
  copy_repo "$tmp/checkout"
  if HOME="$tmp" bash "$tmp/checkout/setup.sh" >/tmp/lets-start-external.log 2>&1; then
    echo "expected setup.sh without --host to fail outside a host skills root" >&2
    exit 1
  fi
  assert_contains /tmp/lets-start-external.log "Could not infer host"
}

bash -n "$REPO_DIR/setup.sh"
bash "$REPO_DIR/setup.sh" --help >/dev/null
run_codex_install
run_claude_install
run_auto_detection
run_auto_requires_host_when_external

echo "setup smoke tests passed"
