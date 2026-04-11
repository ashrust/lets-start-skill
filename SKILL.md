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

**Parallel session safety.** Before force-pushing, rebasing, or deploying, check
for other active worktrees:
```bash
git worktree list
```
Force-push and rebase are fine on your own feature branch. Never force-push or
rebase shared branches. If other worktrees are active, ask the user before deploying.

**Never enter plan mode.** Do not use `EnterPlanMode` or switch to plan mode.
gstack skills (`/plan-ceo-review`, `/plan-eng-review`, `/office-hours`, etc.) are
the planning mechanism. If you feel the urge to "plan first", route to a gstack
skill instead.

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

- `## Skill invocation` — "If the user's message starts with a /command, STOP.
  Do not read the rest of the message. Invoke the matching skill immediately.
  The skill will process the user's task description. The slash command is a gate, not a label."

Don't duplicate sections that already exist — update in place. If the user
declines, skip and move on.

**If already present**, skip silently.

## Step 4: Workspace setup

**Always create a worktree on a feature branch.** Even for config changes, docs,
or one-line fixes — every session gets its own branch. This prevents conflicts
when running parallel sessions. The only exception is if the user explicitly says
"stay on main" or "skip the worktree."

Detect current state:
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

**On main →** derive `feature/<short-kebab>` from the task description, confirm
the name, then create:
```bash
BRANCH_SLUG=$(echo "$BRANCH_NAME" | sed 's|/|--|g')
WORKTREE_DIR="$REPO_DIR/.worktrees/$BRANCH_SLUG"
git fetch origin
git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" origin/main
cd "$WORKTREE_DIR"
```
If the branch name already exists, append a suffix (`-2`, `-3`, etc.).
Two sessions must never share a branch.

Also offer via `AskUserQuestion`: **Existing branch**, **New project** (`git init`,
no worktree needed), or **Something else**.

**On a feature branch but not in a worktree →** create one and restore main:
```bash
WORKTREE_DIR="$REPO_DIR/.worktrees/$BRANCH_SLUG"
git worktree add "$WORKTREE_DIR" "$CURRENT_BRANCH"
cd "$WORKTREE_DIR"
(cd "$REPO_DIR" && git checkout main)
```

**Worktree already exists →** just `cd` into it.

All worktrees live at `.worktrees/`:
`~/code/my-project/.worktrees/feature--add-auth`

### Parallel session rules

After setup, check `git worktree list`. If other worktrees are active, apply
these rules silently for the rest of the session:
- Force-push and rebase are fine on your own feature branch. Never force-push
  or rebase shared branches (`main`, `develop`, `deploy`, etc.).
- Before deploying, check deploy history for commits from the last 10 minutes.
  If found, ask the user before proceeding.
- Never squash-merge unless the user explicitly asks.

## Step 5: Route to the right gstack skill

The session isn't started until a gstack skill is running. This step is not optional
— every session must end with a skill invocation (unless the user explicitly opts out).

Read the installed gstack skill directories to discover what's available:
```bash
ls -1 ~/.claude/skills/gstack/*/SKILL.md 2>/dev/null | sed 's|.*/\(.*\)/SKILL.md|\1|'
```

Recommend ONE skill via `AskUserQuestion` based on the user's task description.
Include 2–3 alternatives plus "I'll drive manually (skip skill)".

**On confirmation → invoke the skill immediately.** Do not summarize, do not ask
follow-up questions, do not add commentary. Call the `Skill` tool and get out of
the way.

**If the user picks "I'll drive manually" →** accept it, but remind them they can
invoke any skill later with `/<skill-name>`.

**If the user picks "Something else" or describes a task that doesn't map →**
don't give up. Read the SKILL.md files for the top 2–3 candidates to understand
their scope, then re-recommend with better context. Only fall through to manual
mode if the user explicitly declines a second time.

## Step 6: Session wrapup

When the user signals they're done (or the task is complete), always report the
session status before closing:

> **Session status:**
> - **Branch:** `<branch name>`
> - **Uncommitted changes:** yes/no
> - **Unpushed commits:** yes/no
> - **Deploy status:** last deploy time + whether current branch changes are live

Check with:
```bash
git status --short
git log origin/<branch>..HEAD --oneline
```

If anything is uncommitted, unpushed, or undeployed, don't fix it automatically —
just report it clearly and let the user decide.

## Edge cases

**No git repo:** Ask if they want to `git init` or point to an existing repo.

**Dirty working tree:** Warn about uncommitted changes — offer stash, commit, or continue.

**Skip to a skill:** If they say "lets-start, then straight to eng review", skip
routing and respect the request. Still do workspace setup.

**Parallel deploys:** If the user asks to deploy and other worktrees are active
on the same repo, check deploy history before proceeding. Never assume it's safe.

## Updating /lets-start

The canonical source is https://github.com/ashrust/lets-start-skill.
```bash
cd ~/.claude/skills/lets-start && git pull origin main
```
