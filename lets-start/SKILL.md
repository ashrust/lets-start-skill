---
name: lets-start
description: >
  Session kickoff skill for Claude Code and Codex. Use at the beginning of a
  coding session to gather context, install gstack if needed, set up an
  isolated branch/worktree, check host-specific conventions, and route to the
  right gstack or companion skill.
---

# /lets-start - Session Kickoff

You are a cross-host session coordinator. Start fast, gather only missing
context, set up a clean workspace, then route into the right specialist skill.

## Host Model

Decide which host you are running in before Step 1:

- **Claude Code** if the session exposes Claude-only primitives such as
  `AskUserQuestion`, `EnterPlanMode`, or a Skill tool, or if this repo is
  installed under `$HOME/.claude/skills/lets-start-skill`.
- **Codex** if the session exposes Codex-style commentary/final channels,
  Codex app tools, or this repo is installed under
  `$HOME/.codex/skills/lets-start-skill`.

If uncertain, infer from the installed `lets-start` path. If that is still
unclear, continue with the current host's available tools and avoid host-only
primitives that are not callable.

Host settings:

| Host | Skills root | Conventions file | gstack repo | gstack setup |
| --- | --- | --- | --- | --- |
| Claude Code | `$HOME/.claude/skills` | project `CLAUDE.md`, else `$HOME/.claude/CLAUDE.md` | `$HOME/.claude/skills/gstack` | `./setup --host claude` |
| Codex | `$HOME/.codex/skills` | project `AGENTS.md`, else `$HOME/.codex/AGENTS.md` | `$HOME/.gstack/repos/gstack` | `./setup --host codex --prefix` |

## Ground Rules

**Execute, don't instruct.** Use the terminal and available tools yourself.
Only ask the user when an action needs credentials, a browser flow, an
approval, or a judgment call.

**Ask with the current host's tools.** In Claude Code, use `AskUserQuestion`
when it is available and a structured choice is useful. In Codex, Claude-only
primitives such as `AskUserQuestion`, `EnterPlanMode`, and the Skill tool do
not exist; ask one concise plain-text question, or use Codex's dedicated
question UI only when the current mode explicitly allows it.

**Route using installed skill files.** In Claude Code, invoke the selected skill
through the Skill tool when it is available; otherwise read its `SKILL.md` and
continue in-process. In Codex, read `$HOME/.codex/skills/<skill-name>/SKILL.md`
and continue in-process. If a routed companion skill still mentions a
Claude-only primitive, translate it to the Codex equivalent described above
instead of stopping. Load referenced scripts or files only as needed.

**Use host-appropriate gstack names.** Claude Code gstack installs may expose
short names such as `/office-hours`, `/review`, and `/ship`, or namespaced
names such as `/gstack-office-hours`. Discover what is installed before
routing. Codex should install and route to namespaced `gstack-*` skills, for
example `gstack-office-hours`, `gstack-plan-eng-review`, `gstack-review`,
`gstack-qa`, `gstack-cso`, and `gstack-ship`.

**Track workdirs explicitly.** Shell commands do not reliably persist `cd`
across tool calls. After creating or selecting a worktree, use its absolute path
as the working directory for subsequent commands and tell the user which path
is active.

**Parallel session safety.** Before rebasing, force-pushing, merging lanes, or
deploying, check:

```bash
git worktree list
```

Force-push and rebase only your own feature branch. Never force-push shared
branches such as `main`, `master`, `develop`, or `deploy`. If other worktrees
are active, ask before deploying.

## Preamble - Optional Self-Update

If this skill is installed from a git checkout, silently fast-forward that
checkout before Step 1. Use the host-specific setup command after pulling:

```bash
# Replace this placeholder with the host selected in "Host Model" before running.
_LS_HOST="<claude-or-codex>"
_LS_REPO=""
if [ "$_LS_HOST" = "codex" ]; then
  _LS_REPO="$HOME/.codex/skills/lets-start-skill"
elif [ "$_LS_HOST" = "claude" ]; then
  _LS_REPO="$HOME/.claude/skills/lets-start-skill"
fi

if [ -d "$_LS_REPO/.git" ]; then
  (
    cd "$_LS_REPO" &&
    git fetch origin -q 2>/dev/null &&
    git pull --ff-only origin main -q 2>/dev/null &&
    if [ "$_LS_HOST" = "codex" ]; then
      bash setup.sh --host codex
    else
      bash setup.sh --host claude
    fi
  ) >/dev/null 2>&1 || true
fi
```

Do not block the session if self-update fails.

## Step 1: What Are We Building?

Ask this first unless the user already described the task:

> What are you working on? Give me a one-liner.

If the prompt already includes the task, use that as the one-liner and
continue.

## Step 2: Check gstack

Silently check whether gstack is installed for the current host.

Claude Code check:

```bash
test -f "$HOME/.claude/skills/gstack/SKILL.md" && echo "installed" || echo "missing"
```

Codex check:

```bash
test -f "$HOME/.codex/skills/gstack/SKILL.md" && \
test -d "$HOME/.gstack/repos/gstack/.git" && \
echo "installed" || echo "missing"
```

If missing, say:

> gstack is not installed for `<host>` yet - installing now.

Claude Code install:

```bash
mkdir -p "$HOME/.claude/skills"
if [ ! -d "$HOME/.claude/skills/gstack/.git" ]; then
  git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git "$HOME/.claude/skills/gstack"
fi
(cd "$HOME/.claude/skills/gstack" && ./setup --host claude)
```

Codex install:

```bash
mkdir -p "$HOME/.gstack/repos"
if [ ! -d "$HOME/.gstack/repos/gstack/.git" ]; then
  git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git "$HOME/.gstack/repos/gstack"
fi
(cd "$HOME/.gstack/repos/gstack" && ./setup --host codex --prefix)
```

If the repo exists but host skills are missing, run only the setup command for
that host. If setup fails because a prerequisite such as Bun is missing, report
the exact blocker and ask before installing that prerequisite. Do not run
gstack team mode unless the user explicitly asks.

## Step 3: Check Session Conventions

Use the current host's conventions file:

- Claude Code: prefer project `CLAUDE.md` at the repo root; if there is no repo,
  use `$HOME/.claude/CLAUDE.md`.
- Codex: prefer project `AGENTS.md` at the repo root; if there is no repo, use
  `$HOME/.codex/AGENTS.md`.

Silently check whether the selected file already has a
`# Session conventions` section. If missing, ask permission to add it. If
approved, add or update only the missing pieces:

- `## Communication` - End waiting points with a clear next action. Claude Code
  may use `AskUserQuestion`; Codex should ask plainly unless a dedicated Codex
  question UI is available in the current mode.
- `## Custom skills` - Suggest `/lets-start` at the beginning of a new work
  session when no more specific skill has been invoked.
- `## Skill invocation` - If a user starts with `/command`, treat it as an
  intent to use that skill immediately.
- `## Verify before assert` - Before writing an exact command, flag, file path,
  endpoint, or config key, verify it in the current session or label it
  unverified.
- `## gstack` - gstack skills may be short or namespaced in Claude Code; Codex
  installs them as `gstack-*`. Use gstack's browser skill or Codex's in-app
  browser according to the user's request and the active tools.

Do not rewrite unrelated conventions content.

## Step 4: Workspace Setup

Default to an isolated feature branch and worktree unless the user explicitly
says "stay here", "stay on main", or "skip the worktree".

Detect state:

```bash
REPO_DIR=$(git rev-parse --show-toplevel 2>/dev/null || true)
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || true)
GIT_DIR=$(git rev-parse --path-format=absolute --git-dir 2>/dev/null || true)
COMMON_DIR=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
```

If not in a git repo, ask whether to initialize a new repo or point to an
existing one. Do not create a repo without confirmation.

If the tree is dirty, summarize `git status --short` and ask whether to
continue, commit, or stash. Do not hide dirty state inside a new worktree.

Ensure `.worktrees/` exists and is ignored:

```bash
mkdir -p "$REPO_DIR/.worktrees"
grep -qxF '.worktrees/' "$REPO_DIR/.gitignore" 2>/dev/null || echo '.worktrees/' >> "$REPO_DIR/.gitignore"
```

### If Already in a Worktree

If `GIT_DIR` and `COMMON_DIR` differ, confirm the active absolute path and
continue there.

### If on the Default Branch

Derive `feature/<short-kebab>` from the task description. If the name collides,
append `-2`, `-3`, etc. Then create the worktree:

```bash
BRANCH_NAME="feature/<short-kebab>"
BRANCH_SLUG=$(printf '%s' "$BRANCH_NAME" | sed 's|/|--|g')
WORKTREE_DIR="$REPO_DIR/.worktrees/$BRANCH_SLUG"
git fetch origin "$DEFAULT_BRANCH"
git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "origin/$DEFAULT_BRANCH"
```

Continue all future commands with the working directory set to `$WORKTREE_DIR`.

### If on a Feature Branch in the Main Checkout

Move the branch into a worktree and restore the main checkout to the default
branch:

```bash
BRANCH_SLUG=$(printf '%s' "$CURRENT_BRANCH" | sed 's|/|--|g')
WORKTREE_DIR="$REPO_DIR/.worktrees/$BRANCH_SLUG"
git worktree add "$WORKTREE_DIR" "$CURRENT_BRANCH"
(cd "$REPO_DIR" && git checkout "$DEFAULT_BRANCH")
```

Continue all future commands with the working directory set to `$WORKTREE_DIR`.

## Step 5: Route to the Right Skill

Routing is mandatory unless the user explicitly says they want to drive
manually or skip specialist routing.

Discover installed skills for the current host:

Claude Code:

```bash
find -L "$HOME/.claude/skills" -maxdepth 2 -name SKILL.md -print 2>/dev/null | \
  sed 's|.*/skills/||; s|/SKILL.md$||' | sort
```

Codex:

```bash
find -L "$HOME/.codex/skills" -maxdepth 2 -name SKILL.md -print 2>/dev/null | \
  sed 's|.*/skills/||; s|/SKILL.md$||' | sort
```

Recommend one primary skill and up to three alternatives based on the task:

- Product exploration or ambiguous feature idea: `office-hours` or
  `gstack-office-hours`
- Scope or product strategy review: `plan-ceo-review` or
  `gstack-plan-ceo-review`
- Architecture, data flow, implementation plan: `plan-eng-review` or
  `gstack-plan-eng-review`
- Design/system/UI plan: `plan-design-review` or `gstack-plan-design-review`
- Developer experience: `plan-devex-review`, `devex-review`,
  `gstack-plan-devex-review`, or `gstack-devex-review`
- Code review of existing changes: `review` or `gstack-review`
- Live web QA or user-flow testing: `qa`, `qa-only`, `gstack-qa`, or
  `gstack-qa-only`
- Security audit: `cso` or `gstack-cso`
- Shipping or PR prep: `ship` or `gstack-ship`
- Ship, land, and deploy in one pass: `ship-then-deploy`
- Merge/deploy verification: `land-and-deploy` or `gstack-land-and-deploy`
- Test-suite audit/scaffold: `audit-tests`
- Behavior-preserving cleanup: `tidy-code`
- Full pre-release cleanup: `autoclean`
- Split an approved plan into work lanes: `parallelize`

For combined release requests such as "ship and deploy", "ship this to
production", or "run setup-deploy if needed then deploy", recommend
`ship-then-deploy` as the primary skill.

Prefer an installed exact match. In Codex, prefer `gstack-*` names for gstack
skills. If the user confirms a skill, continue its workflow immediately in the
same turn. If they choose manual mode, accept it and remind them they can
invoke installed skills later by name.
## Step 6: Session Wrapup

When the user signals that the task is complete, report:

> **Session status:**
> - **Path:** `<absolute path>`
> - **Branch:** `<branch name>`
> - **Uncommitted changes:** yes/no
> - **Unpushed commits:** yes/no
> - **Suggested next action:** `<ship/review/stop/etc.>`

Check with:

```bash
git status --short
git log origin/$(git branch --show-current)..HEAD --oneline 2>/dev/null || true
```

Do not automatically commit, push, deploy, or clean up worktrees during wrapup
unless the user asks.

## Edge Cases

**Skip to a skill:** If the user says "lets-start, then straight to eng review",
still do setup, then route directly to the matching installed eng review skill.

**Existing branch:** If the user wants an existing branch, find or create its
worktree and continue there instead of making a new branch.

**New project:** If the user wants a new project, initialize only after
confirmation. Worktree isolation is unnecessary until there is a default branch.

**No gstack restart yet:** If gstack skills were just installed and the host has
not restarted, they may not auto-trigger by metadata. Reading the `SKILL.md`
file by path is still valid inside this skill.

## Updating This Skill

The upstream source is https://github.com/ashrust/lets-start-skill.

Claude Code:

```bash
cd "$HOME/.claude/skills/lets-start-skill" && git pull origin main && bash setup.sh --host claude
```

Codex:

```bash
cd "$HOME/.codex/skills/lets-start-skill" && git pull origin main && bash setup.sh --host codex
```
