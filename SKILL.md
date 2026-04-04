---
name: lets-start
description: >
  Session kickoff skill. Use at the beginning of any Claude Code session to gather
  context, set up the workspace, check project setup, and route to the right gstack skill.
  Triggers on /lets-start or when the user says "new session" or "kick off".
---

# /lets-start — Session Kickoff

You are a session coordinator. Walk the user through setup one question at a time.
Ask the first question IMMEDIATELY — no preamble, no scanning, no silent checks.
Speed matters.

## Ground rules

**Execute, don't instruct.** You have a terminal — use it. Run `git fetch`,
`gcloud auth`, `npm install`, etc. yourself. Never paste commands for the user to
copy-run. Only ask the user when it requires their password, is destructive (see
/careful), or needs a browser-based flow.

**Always end with a clear next action.** At every waiting point, suggest the next
step using `AskUserQuestion` with tailored options, a marked recommendation, and an
escape hatch ("something else"). The user should never wonder what to type.

**Wait when the user needs to leave the terminal.** If the next step requires a
browser, a different app, or reading something like a plan, tell them what to do
and then STOP. Do not immediately ask "is that done?" or present follow-up options.
Let the user come back to you when they've completed the task. You may give them a prompt so they know what their response should be.

## Preamble — run silently before Step 1
````bash
_SD="$HOME/.claude/skills/lets-start"
[ -d "$_SD/.git" ] && (cd "$_SD" && git fetch origin -q 2>/dev/null && \
  [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ] && \
  git pull --ff-only origin main -q 2>/dev/null && echo "✓ /lets-start updated.")
````

## Step 1: What are you working on?

Ask this FIRST as plain text — no tool call, no options:

> What are you working on? Give me a one-liner.

If the user already described the task in their prompt (e.g. "lets-start, I need to
add auth to my app"), skip this and use what they said.

## Step 2: Check gstack

Silently check if gstack is installed and up to date:
```bash
test -d ~/.claude/skills/gstack && echo "installed" || echo "missing"
```

**If missing or behind**, tell the user and install/update it:
> gstack isn't installed yet — installing now.

```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup
```

After install, add a "gstack" section to the project's CLAUDE.md (or global
`~/.claude/CLAUDE.md` if no project CLAUDE.md exists) listing available skills
and noting to use `/browse` for all web browsing.

**If installed, skip silently.**

## Step 3: Check global CLAUDE.md conventions

Silently check if `~/.claude/CLAUDE.md` contains a `# Session conventions` section.

**If missing**, ask permission:

> Your global CLAUDE.md is missing some session conventions. Can I add them?

If approved, add a `# Session conventions` section to `~/.claude/CLAUDE.md` with
two subsections:

- `## Communication` — "Always end with a clear next action. Use AskUserQuestion
  with a recommended option and an escape hatch. The user should never wonder what
  to type."

- `## Custom skills` — "Always suggest /lets-start at the beginning of a new session
  if no other skill has been invoked."

Don't duplicate sections that already exist — update in place. If the user
declines, skip and move on.

**If already present**, skip silently.

## Step 4: Workspace setup

**Always create a worktree on a feature branch.** Even for config changes, docs,
or one-line fixes — every session gets its own branch. This prevents conflicts
when running parallel sessions. The only exception is if the user explicitly says "stay on main" or "skip the worktree."

First, detect the current state:
```bash
REPO_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
IN_WORKTREE=$(git rev-parse --is-inside-work-tree 2>/dev/null && \
  [ "$(git rev-parse --show-toplevel)" != "$(git rev-parse --git-common-dir | sed 's|/\.git$||')" ] && \
  echo "yes" || echo "no")
```

Ensure `.worktrees/` exists and is git-ignored:
```bash
mkdir -p "$REPO_DIR/.worktrees"
grep -qxF '.worktrees/' "$REPO_DIR/.gitignore" 2>/dev/null || echo '.worktrees/' >> "$REPO_DIR/.gitignore"
```

**Already in a worktree on a feature branch →** confirm and move on.

**On main (or no repo yet) →** ask via `AskUserQuestion`:
- **New feature branch** (recommended) — derive `feature/<short-kebab>` from their
  task description, confirm the name, then create:
```bash
  BRANCH_SLUG=$(echo "$BRANCH_NAME" | sed 's|/|--|g')
  WORKTREE_DIR="$REPO_DIR/.worktrees/$BRANCH_SLUG"
  git fetch origin
  git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" origin/main
  cd "$WORKTREE_DIR"
```
- **Existing branch** — ask which branch, then find or create its worktree:
```bash
  WORKTREE_DIR="$REPO_DIR/.worktrees/$BRANCH_SLUG"
  git worktree add "$WORKTREE_DIR" "$BRANCH_NAME"  # if worktree doesn't exist
```
- **New project** — create directory, `git init`, no worktree needed yet
- **Something else**

**On a feature branch but in the main checkout (not a worktree) →** create a
worktree for that branch, then restore the main checkout to main:
```bash
WORKTREE_DIR="$REPO_DIR/.worktrees/$BRANCH_SLUG"
git worktree add "$WORKTREE_DIR" "$CURRENT_BRANCH"
cd "$WORKTREE_DIR"
(cd "$REPO_DIR" && git checkout main)
```
Confirm: "Worktree ready at `<path>`. Main checkout restored to main."

**Worktree already exists for the target branch →** just `cd` into it. Never
create a second one.

All worktrees live inside the repo at `.worktrees/`:
`~/code/my-project/.worktrees/feature--add-auth`

## Step 5: Project setup check

After workspace is ready, silently scan for project conventions — CLAUDE.md,
memory files, config files (package.json, pyproject.toml, Dockerfile, fly.toml,
vercel.json, etc.).

- **If found:** present a brief summary. No question needed.
- **If nothing found:** ask if they want stack suggestions or have preferences.

## Step 6: Route to the right gstack skill

**Do NOT use `EnterPlanMode`. gstack skills are the planning mechanism.**

Read the installed gstack skill directories to discover what's available:
```bash
ls -1 ~/.claude/skills/gstack/*/SKILL.md 2>/dev/null | sed 's|.*/\(.*\)/SKILL.md|\1|'
```

Recommend ONE skill via `AskUserQuestion` based on the user's task description.
Include 2–3 alternatives plus "Something else". On confirmation, invoke immediately.

## Updating /lets-start

The canonical source is https://github.com/ashrust/lets-start-skill.
```bash
cd ~/.claude/skills/lets-start && git pull origin main
```
