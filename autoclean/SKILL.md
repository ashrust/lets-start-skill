---
name: autoclean
description: >
  Sequential pre-release cleanup pipeline. Runs /audit-tests, then /tidy-code,
  then /cso (comprehensive) in fixed order, gating between phases so you can
  review each result and skip or stop. Triggers on /autoclean or when the user
  says "clean up this repo", "pre-release cleanup", "full cleanup pass",
  "tidy and security", or "get this branch ready to land". Best run on a
  clean working tree before cutting a release. Each child skill commits its
  own work on its own branch; /autoclean itself never commits.
---

# /autoclean — Sequential cleanup pipeline

You orchestrate three child skills in fixed order, one phase at a time, gating
between each so the user can review, skip, or stop. /autoclean is the
conductor — it does no cleanup work itself.

## The three phases

1. **/audit-tests** — score the test suite, optionally scaffold what's missing
2. **/tidy-code** — behavior-preserving code cleanup in 5 dimensions
3. **/cso** (comprehensive mode) — security audit, findings only, no commits

**Order rationale (do not change):** tests first because /tidy-code's dimension
verification re-runs the suite — a broken or thin suite makes tidy unsafe.
Tidy second because cleaner code makes the security audit's findings cleaner.
CSO last because it is read-only and should evaluate the final state of the
code, not an in-progress version.

Users who want a different order invoke the skills individually.

## Ground rules

Inherit all ground rules from /lets-start (execute don't instruct, parallel
session safety, never enter plan mode).

**Gate every phase.** After each child returns, summarize what landed and ask
via AskUserQuestion: Continue / Skip next phase / Stop. Never chain phases
silently.

**Never commit from /autoclean.** /autoclean stays out of git itself —
each child skill is responsible for its own commits. /tidy-code creates
a cleanup branch (e.g. `tidy/cleanup-<date>`) and commits per dimension.
/cso writes findings outside the repo and produces no commits.
/audit-tests is expected to commit its own scaffolding work. If a child
skill ever leaves the tree dirty (a bug or interrupted run), /autoclean
catches that at the next gate and asks the user how to proceed — the
orchestrator does not silently commit, stash, or discard the user's
working state.

**Never merge between phases.** Each phase's branch stays independent. The
user merges them in their own order via `/ship` or manual `git merge` after
the pipeline finishes.

**Stateless and re-runnable.** /autoclean keeps no state of its own. If a
phase stops or fails, the user re-runs /autoclean and chooses which phase
to start from at the preflight prompt.

## Step 0: Preflight

Run three checks up front before invoking any child skill.

### 0a. Working tree must be clean

```bash
git status --short
```

If the output is non-empty, ask via AskUserQuestion: commit, stash, or abort.
Do not proceed with a dirty tree — each child skill expects to branch off
clean state, and a dirty tree would land in whichever child's branch runs
first.

### 0b. Dependent skills must exist

Check that all three skills are installed on this machine:

```bash
for s in audit-tests tidy-code cso; do
  [ -f "$HOME/.claude/skills/$s/SKILL.md" ] \
    || [ -f "$HOME/.claude/skills/gstack/$s/SKILL.md" ] \
    && echo "ok:$s" || echo "missing:$s"
done
```

If everything is present, continue silently. If anything is missing, name
which skills and ask via AskUserQuestion:

- **Skip missing phase(s) and continue** — run only the phases whose skills
  are installed.
- **Stop and install first** — exit the pipeline so the user can install
  the missing skills (e.g. by re-running `setup.sh` in this repo, or
  installing gstack if /cso is missing).
- **Abort** — leave everything as-is.

Do not silently no-op a missing phase. The user must know what ran and
what didn't.

### 0c. Confirm starting phase

Ask via AskUserQuestion: "Start from Phase 1 /audit-tests (recommended), or
skip ahead?" Offer Phase 1 / Phase 2 / Phase 3 / Abort. This makes
/autoclean re-runnable after a partial run — the user picks up where they
left off without re-doing finished phases.

## Step 1: Phase 1 — /audit-tests

Invoke /audit-tests via the Skill tool. /audit-tests runs its own scope
confirmation, scores the test suite against its rubric, and optionally
scaffolds with consent.

When /audit-tests returns, capture:

- Final score (0–10)
- Whether it scaffolded (i.e. modified files)
- Branch name if it created one

Summarize in 2–3 lines, then run a tree-state check before gating:

```bash
git status --short
```

If the tree is dirty after /audit-tests returns (a child-skill bug or an
interrupted run — children are expected to commit or skip cleanly), do
not assume any specific resolution. Surface the dirty state and ask the
user how to proceed via AskUserQuestion: **Commit and continue**,
**Stash and continue**, **Skip /tidy-code (only /cso left, which reads)**,
or **Stop here**. /autoclean does not commit or stash on its own.

If the tree is clean, gate normally:
- **Continue to /tidy-code** (recommended)
- **Skip /tidy-code, go to /cso**
- **Stop here**

If the user picks Stop, skip to Step 4 (final report). If Skip, jump to
Step 3.

## Step 2: Phase 2 — /tidy-code

Invoke /tidy-code via the Skill tool. /tidy-code runs its own scope
confirmation (Step 0 in its workflow), detects the stack, and walks the
five cleanup dimensions, committing each on the `tidy/cleanup-<date>`
branch it creates.

When /tidy-code returns, capture:

- Branch name (e.g. `tidy/cleanup-2026-05-16`)
- Dimensions actually run (it may stop mid-pipeline on a failed verify)
- Files changed / lines net (from `TIDY_LOG.md` summary)

Summarize and gate via AskUserQuestion:

- **Continue to /cso** (recommended)
- **Stop here**

If Stop, skip to Step 4.

## Step 3: Phase 3 — /cso (comprehensive)

Invoke /cso via the Skill tool in **comprehensive mode**. /autoclean
intentionally picks comprehensive over daily because it is meant to be a
pre-release ritual — the deeper scan is the point. Pass the
`--comprehensive` flag explicitly (per /cso's Arguments spec); the bare
word `comprehensive` will not select the right mode.

/cso produces a security findings report (no code commits). When it
returns, capture:

- Overall score
- Severity counts (critical / high / medium / low)
- Path to the findings report file

## Step 4: Final report

Aggregate what completed and what didn't. Use a table:

> **/autoclean complete.**
>
> | Phase | Status | Result | Artifact |
> |---|---|---|---|
> | /audit-tests | ✓ | 7/10 → 9/10 (scaffolded, committed) | current branch |
> | /tidy-code | ✓ | 12 files, -340 lines, 5/5 dims | `tidy/cleanup-2026-05-16` branch |
> | /cso (comprehensive) | ✓ | 0 critical, 2 medium | findings report file |
>
> One branch ready to merge.

If any phase was skipped or stopped, show its row with status `skip` or
`stop` and no branch.

Before presenting the next-step prompt, check for stashed work:

```bash
git stash list | head -3
```

If the output is non-empty (the user picked "Stash and continue" at any
gate, or there is unrelated pre-existing stashed work), surface a
one-line reminder below the table:

> ⚠ You have stashed work: `<top stash line>`. Run `git stash pop` to
> restore it if it's from this /autoclean run.

End with AskUserQuestion offering the next move:

- **/ship** (recommended) — ship the first ready branch
- **Review a branch manually** — `git checkout <branch>` to inspect
- **Re-run /autoclean** — useful if you skipped a phase and want to come
  back to it
- **Stop**

## Edge cases

**Child skill stops mid-phase or crashes.** Do not retry automatically. The
final-report table marks that phase as `stopped` with the branch (if any)
that the child left behind. The user re-runs /autoclean and picks the next
phase from Step 0c.

**User picks Stop at a gate.** Honor it. Skip to Step 4 immediately and
produce the final report with the remaining phases marked `skipped`.

**Missing /cso (gstack not installed).** Step 0b surfaces this. If the user
elects to continue without it, /autoclean runs phases 1 and 2 and notes
"cso skipped — gstack not installed" in the final report.

**Tree gets dirty mid-pipeline.** Should not happen — each child commits its
own work to its own branch. If it does (e.g. a child crashed without
committing), surface this loudly and refuse to start the next phase until
the user resolves it.

**Running on a non-git directory.** /autoclean requires a git repo. Step 0a
fails closed; report and abort.

**Running inside a worktree that already has a `tidy/cleanup-*` branch.**
/tidy-code handles this itself by appending a counter. /autoclean does not
need to intervene.

**User wants daily /cso mode instead of comprehensive.** /autoclean v1 is
fixed to comprehensive — by design, since the skill exists for pre-release
ritual depth. Users who want daily run `/cso` directly.

**User wants to reorder phases.** Not supported in v1 (see Order rationale
above). Run the skills individually.
