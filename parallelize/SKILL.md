---
name: parallelize
description: >
  Splits a gstack plan into concurrent tasks. Use after a gstack planning skill
  (/plan-ceo-review, /plan-eng-review, /office-hours) has produced a plan.
  Triggers on /parallelize or when the user says "split this up", "run in parallel",
  or "what can I build concurrently". Analyzes task dependencies, creates a worktree
  and branch for each independent task, and gives the user ready-to-paste session
  commands.
---

# /parallelize — Split a Plan into Concurrent Sessions

You take a gstack plan and turn it into parallel workstreams.

## Ground rules

Inherit all ground rules from /lets-start (execute don't instruct, parallel session
safety, never enter plan mode).

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

Classify each task as:
- **Independent** — no file overlap, no dependency on other tasks
- **Dependent** — must wait for one or more other tasks to finish
- **Shared-infra** — touches schema, API contracts, or deploy config (do first)

Present the analysis:

> **Dependency analysis:**
>
> Independent (can run concurrently):
> - Task 1: Add auth middleware — touches `src/auth/`
> - Task 3: Rate limiting — touches `src/middleware/ratelimit.go`
> - Task 4: Update unit tests — touches `tests/`
>
> Must run first (shared infrastructure):
> - Task 2: DB schema migration — other tasks depend on new tables
>
> Must run after:
> - Task 5: Integration tests — depends on tasks 1, 3, 4

Ask the user to confirm or adjust the grouping before proceeding.

## Step 3: Create worktrees

For each independent task, create a branch and worktree:

```bash
# Resolve the main checkout's path, whether we're in it or in a worktree.
COMMON_DIR=$(git rev-parse --path-format=absolute --git-common-dir)
REPO_DIR=$(dirname "$COMMON_DIR")

# Detect the default branch (main, master, trunk, etc.) instead of hardcoding.
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
BASE=${BASE:-main}

git fetch origin "$BASE"

# Replace this with the actual branches you want to create.
BRANCHES=(feature/example-a feature/example-b)

for TASK_BRANCH in "${BRANCHES[@]}"; do
  BRANCH_SLUG=$(echo "$TASK_BRANCH" | sed 's|/|--|g')
  WORKTREE_DIR="$REPO_DIR/.worktrees/$BRANCH_SLUG"
  git worktree add -b "$TASK_BRANCH" "$WORKTREE_DIR" "origin/$BASE"
done
```

Branch naming: derive from the task description using `feature/<short-kebab>`.
If the branch already exists, append a suffix.

## Step 4: Print session instructions

Present the ready-to-use worktree paths:

> **Parallel sessions ready. Open a new Claude Code session for each path:**
>
> 1. `~/code/my-project/.worktrees/feature--add-auth`
> 2. `~/code/my-project/.worktrees/feature--rate-limiting`
> 3. `~/code/my-project/.worktrees/feature--update-tests`
>
> In each new session, start with:
> `/lets-start I'm working on <task description>` and select "Existing branch"
>
> **Do first** (in this session):
> - Task 2: DB schema migration
>
> **Do after all parallel tasks merge:**
> - Task 5: Integration tests
>
> When parallel sessions are done, come back here and say "merge".

Then STOP. Do not ask follow-up questions.

## Step 5: Merge guidance

When the user comes back after parallel sessions are done (or says "merge" or
"sessions are done"), guide the merge:

1. Check the status of each worktree branch:
```bash
git worktree list
for branch in <branches>; do
  echo "=== $branch ==="
  git log origin/main..$branch --oneline
done
```

2. For each branch, recommend merge strategy:
   - **Clean, no conflicts expected** → merge to main
   - **Might conflict with another parallel branch** → merge one at a time,
     resolve conflicts between each

3. Execute the merges from the main checkout (one at a time, stopping on conflicts):
```bash
# If you're inside a worktree, switch to the main checkout first —
# you can't check out the default branch from a worktree that doesn't own it.
COMMON_DIR=$(git rev-parse --path-format=absolute --git-common-dir)
cd "$(dirname "$COMMON_DIR")"

BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
git checkout "${BASE:-main}"
git merge --no-ff <branch-name>
```

4. After all merges, clean up worktrees:
```bash
git worktree remove .worktrees/<branch-slug>
git branch -d <branch-name>
```

5. Report final status using the same format as /lets-start Step 6.

## Edge cases

**Only one task is independent:** Skip parallelization, tell the user everything
is sequential — no benefit to splitting.

**All tasks touch the same files:** Same as above. Don't force parallelization
when it will just create merge conflicts.

**User wants to parallelize differently than recommended:** Respect their grouping.
Warn about potential conflicts but create the worktrees anyway.

**Worktree limit:** Git has no hard limit, but more than 4–5 concurrent sessions
is hard for a human to manage. If the plan has many independent tasks, suggest
batching into 3–4 groups.
