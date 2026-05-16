---
name: parallelize
description: >
  Splits a gstack plan into concurrent tasks. Use after a gstack planning skill
  (/plan-ceo-review, /plan-eng-review, /office-hours) has produced a plan.
  Triggers on /parallelize or when the user says "split this up", "run in parallel",
  or "what can I build concurrently". Analyzes task dependencies, creates a worktree
  and branch for each independent task, names them as numbered lanes so they're
  easy to track in the sidebar, and leaves the current session as the management
  session that the user returns to in order to merge.
---

# /parallelize — Split a Plan into Concurrent Sessions

You take a gstack plan and turn it into parallel workstreams.

## Ground rules

Inherit all ground rules from /lets-start (execute don't instruct, parallel session
safety, never enter plan mode).

## The two roles

Every /parallelize run sets up two kinds of sessions, and the user needs to know
which is which the whole way through:

- **Management session** — the session running /parallelize *right now*. It does
  not pick up a lane. Its job is to set up the lanes, do any shared-infra work
  first, wait while lanes run in parallel windows, then merge them in Step 5.
  Tell the user to keep this window open and come back to it.

- **Lane sessions** — one new Claude Code session per independent task, each in
  its own worktree on a branch named `lane-<N>-<short-name>`. The user opens
  them in separate windows. The shared `lane-` prefix groups them together in
  the sidebar so they're easy to tell apart at a glance, and the number gives
  each one a stable identity ("lane 2 is rate limiting").

The single biggest source of confusion in parallel work is losing track of
which window is which. The lane numbering and the management-session framing
exist specifically to fix that — surface both clearly in Step 4.

## Step 1: Find the plan

Check the current conversation for a plan produced by a gstack skill. Plans are
usually a numbered list of tasks, a markdown document, or a structured outline.

**If no plan is visible**, ask:

> I don't see a plan in this session. Paste it here or tell me which file to read.

## Step 2: Analyze dependencies

For each task in the plan, determine:
- **Which files/modules does it touch?**
- **Does it depend on output from another task?**
- **Does it modify shared infrastructure (DB schema, API contracts, deploy config)?**

Classify each task:
- **Lane** — independent, no file overlap with other lanes. Gets its own
  numbered lane.
- **Shared-infra (do first)** — touches schema, API contracts, or deploy
  config. The management session does these *before* spawning lanes so every
  lane branches off the updated base.
- **Do after** — depends on one or more lanes finishing. The management
  session does these *after* merging the lanes.

Present the analysis using the same lane numbering and naming that will appear
in the sidebar, so the user sees the labels they'll be navigating by:

> **Dependency analysis:**
>
> **Lanes** (parallel, one Claude Code window each):
> - `lane-1-auth-middleware` — Add auth middleware (touches `src/auth/`)
> - `lane-2-rate-limit` — Rate limiting (touches `src/middleware/ratelimit.go`)
> - `lane-3-unit-tests` — Update unit tests (touches `tests/`)
>
> **Management session does first** (shared infrastructure):
> - DB schema migration — every lane depends on the new tables
>
> **Management session does after lanes merge:**
> - Integration tests — depends on lanes 1, 2, 3

Ask the user to confirm or adjust the grouping — including the short names,
since those become the labels the user navigates by.

## Step 3: Set up lanes

Resolve the main checkout's path (so paths work whether you ran /parallelize
from the main checkout or another worktree), detect the default branch (don't
hardcode `main` — repos use `master`, `trunk`, etc.), and pick the next free
lane number. Leftover `lane-*` worktrees from a previous /parallelize may
already exist, so don't assume you're starting from 1:

```bash
# Resolve the main checkout's path, whether we're in it or in a worktree.
COMMON_DIR=$(git rev-parse --path-format=absolute --git-common-dir)
REPO_DIR=$(dirname "$COMMON_DIR")
mkdir -p "$REPO_DIR/.worktrees"

# Detect the default branch (main, master, trunk, etc.) instead of hardcoding.
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
BASE=${BASE:-main}

NEXT_LANE=$(ls "$REPO_DIR/.worktrees" 2>/dev/null \
  | sed -nE 's|^lane-([0-9]+)-.*|\1|p' \
  | sort -n | tail -1)
NEXT_LANE=$((${NEXT_LANE:-0} + 1))

git fetch origin "$BASE"
```

Then create one worktree per lane, off the default branch, incrementing the
lane number for each:

```bash
# Per lane: SHORT_NAME is kebab-case, 2-3 words from the task
LANE_BRANCH="lane-${NEXT_LANE}-${SHORT_NAME}"
LANE_DIR="$REPO_DIR/.worktrees/$LANE_BRANCH"
git worktree add -b "$LANE_BRANCH" "$LANE_DIR" "origin/$BASE"
NEXT_LANE=$((NEXT_LANE + 1))
```

The branch and worktree directory share the same `lane-<N>-<short-name>`
string so they match in every place git surfaces them. If a branch name
collides with something existing, append `-2`, `-3` to `SHORT_NAME` rather
than to the lane number.

If Step 2 produced any shared-infra tasks, do them now in the management
session — every lane branched off `origin/$BASE`, so this work needs to land
and the user will rebase lanes onto it (or merge it in during Step 5).

## Step 4: Hand off to the user

Output the lanes you created, name the current window as the management
session, and tell the user exactly what to do next. The block below is the
model — preserve the "you are here" + "come back here to merge" framing:

> **Lanes ready.** You are in the **management session** at:
>
>     <absolute path to current worktree or repo>
>
> Keep this window open — you'll come back here to merge.
>
> Open a new Claude Code session for each lane below (one window per lane).
> They will appear together in your sidebar under the shared `lane-` prefix:
>
> 1. `<repo>/.worktrees/lane-1-auth-middleware`
> 2. `<repo>/.worktrees/lane-2-rate-limit`
> 3. `<repo>/.worktrees/lane-3-unit-tests`
>
> In each new lane window, start with:
>
>     /lets-start I'm working on <task description for that lane>
>
> When /lets-start asks about workspace setup, pick **Existing branch**.
>
> When every lane is done (committed locally or PR merged), come back to this
> management session and say `merge`.

After printing this, STOP. Do not ask follow-up questions — the user is about
to leave the terminal to open the lane windows.

## Step 5: Merge (back in the management session)

The user returns and says `merge` (or "sessions are done"). This step runs only
in the management session — if you somehow find yourself running it in a lane
window, point the user back to their management session at the path from
Step 4 first.

1. Check the status of each lane branch:

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
BASE=${BASE:-main}
git worktree list
for branch in <lane branches>; do
  echo "=== $branch ==="
  git log "origin/$BASE..$branch" --oneline
done
```

2. For each lane, recommend a merge strategy:
   - **Clean, no conflicts expected** → merge to the base branch.
   - **Might conflict with another lane** → merge one at a time, resolving
     conflicts between each.

3. Execute the merges from the main checkout (one at a time, stopping on
   conflicts). The management window stays open — the bash navigates to the
   main checkout under the hood because you can't check out the default
   branch from a worktree that doesn't own it:

```bash
COMMON_DIR=$(git rev-parse --path-format=absolute --git-common-dir)
cd "$(dirname "$COMMON_DIR")"

BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
git checkout "${BASE:-main}"
git merge --no-ff <lane-branch>
```

4. After each merge succeeds, clean up that lane:

```bash
git worktree remove .worktrees/<lane-branch>
git branch -d <lane-branch>
```

5. If Step 2 surfaced any "do after" tasks, do them now in the management
   session — the lane merges they depend on are complete.

6. Report final status using the same format as /lets-start Step 6.

## Edge cases

**Only one independent task:** Skip parallelization — there's no benefit over
just doing the work in the current session.

**All tasks touch the same files:** Same as above. Don't force lanes when they
will just create merge conflicts.

**User wants to parallelize differently than recommended:** Respect their
grouping. Warn about potential conflicts but create the lanes anyway.

**Lane limit:** Git has no hard limit, but more than 4–5 concurrent lanes is
hard for a human to track. If the plan has many independent tasks, suggest
batching them into 3–4 lanes.

**User ran /parallelize from a lane window by accident:** Stop and tell them
to switch back to their management session. Spawning lanes from inside a lane
nests worktrees in a confusing way and the merge step won't have the right
base.
