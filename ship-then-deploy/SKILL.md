---
name: ship-then-deploy
description: >
  End-to-end gstack release wrapper. Ensures deploy configuration exists by
  running gstack setup-deploy when needed, then runs gstack ship followed by
  gstack land-and-deploy. Use when the user says "ship then deploy", "ship
  and deploy", "ship this to production", "run setup-deploy if needed then
  deploy", or wants one command to configure, ship, land, and verify.
---

# /ship-then-deploy - Ship, Land, Deploy

You are the release orchestrator. Your job is to run the normal gstack release
skills in order:

1. `/gstack-setup-deploy` only if this repo does not already have deploy config
2. `/gstack-ship`
3. `/gstack-land-and-deploy`

Do not reimplement the child skills. Read each child `SKILL.md` and follow it
in-process. When a child skill stops for user input, credentials, a failing
check, or a safety gate, stop this wrapper too and report the exact next action.

## Ground Rules

Inherit all ground rules from `/lets-start`: execute, do not instruct; track
workdirs explicitly; respect dirty working trees; and check parallel-session
safety before deploying.

Use the gstack skill names installed for the current host. In Codex, these are
normally `gstack-setup-deploy`, `gstack-ship`, and `gstack-land-and-deploy`.
Older Claude installs may expose the same skills as `setup-deploy`, `ship`, and
`land-and-deploy`; use the installed path you actually find.

## Step 0: Preflight

Confirm you are in a git repo and record the repo root:

```bash
git rev-parse --show-toplevel
git branch --show-current
git status --short
git worktree list
```

If the working tree is dirty, do not abort by default. `/gstack-ship` is allowed
to package intentional release changes, including deploy config created by this
wrapper. Surface the dirty state briefly so the user knows what will be included.

Resolve the three gstack child skill files. Prefer Codex-style prefixed skills,
then fall back to unprefixed Claude Code names:

```bash
resolve_skill() {
  prefixed="$1"
  short="$2"
  for path in \
    "$HOME/.codex/skills/$prefixed/SKILL.md" \
    "$HOME/.claude/skills/$prefixed/SKILL.md" \
    "$HOME/.gstack/repos/gstack/.agents/skills/$prefixed/SKILL.md" \
    "$HOME/.claude/skills/$short/SKILL.md"; do
    [ -f "$path" ] && echo "$path" && return 0
  done
  return 1
}

SETUP_DEPLOY_SKILL=$(resolve_skill gstack-setup-deploy setup-deploy || true)
SHIP_SKILL=$(resolve_skill gstack-ship ship || true)
LAND_DEPLOY_SKILL=$(resolve_skill gstack-land-and-deploy land-and-deploy || true)
printf 'setup=%s\nship=%s\nland=%s\n' "$SETUP_DEPLOY_SKILL" "$SHIP_SKILL" "$LAND_DEPLOY_SKILL"
```

If any child skill is missing, stop and say which one is missing. Do not try to
deploy without the gstack skills.

## Step 1: Decide Whether Setup Is Needed

`/gstack-setup-deploy` persists deploy settings in `CLAUDE.md`, and
`/gstack-land-and-deploy` reads that same section. Do not use `AGENTS.md` for
this check; gstack deploy config currently lives in `CLAUDE.md`.

Run:

```bash
sed -n '/^## Deploy Configuration/,/^## /p' CLAUDE.md 2>/dev/null || true
```

Treat setup as already done when the output contains a `## Deploy Configuration`
section. A section headed `## Deploy Configuration (configured by /setup-deploy)`
is the canonical marker.

If no deploy configuration section exists, say:

> I don't see deploy config in `CLAUDE.md`, so I'm running `/gstack-setup-deploy`
> first. It will detect the platform, production URL, and health checks before
> we ship.

Then read and follow `$SETUP_DEPLOY_SKILL`.

If setup-deploy stops before writing config, stop this wrapper and report what
is needed next. If it completes or the user confirms an existing config, continue.

## Step 2: Ship

Read and follow `$SHIP_SKILL`.

When it completes, confirm that a PR now exists for the current branch. If
`/gstack-ship` stops without creating a PR, stop this wrapper and summarize the
blocker. Do not proceed to landing without a PR.

## Step 3: Land And Deploy

Before handing off, run:

```bash
git worktree list
```

If there are other active worktrees that look like related release work, ask the
user before deploying. Otherwise continue.

Read and follow `$LAND_DEPLOY_SKILL`.

## Step 4: Final Report

Report the release outcome in this shape:

```text
/ship-then-deploy complete
- Setup: skipped (config already existed) / ran / stopped
- Ship: PR created at <url> / stopped
- Land and deploy: merged and healthy / stopped / failed
- Path: <absolute repo path>
- Branch: <branch name>
```

If the deploy failed or was stopped, include the exact next action from the
child skill. Do not invent a workaround outside the gstack workflow.
