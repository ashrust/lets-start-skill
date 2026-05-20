---
name: audit-tests
description: >
  Audits a repo's test suite against a short rubric and scaffolds a comprehensive
  one if it's thin or missing. Detects language and test framework, measures
  coverage where possible, identifies gaps (no unit tests, no integration tests,
  no CI hook, slow or flaky suite, uncovered critical paths), and presents a
  scored verdict. With explicit consent, scaffolds the framework, writes
  representative tests for the golden path and key error paths in the most
  important modules, and wires up a CI hook.
  Triggers on /audit-tests or when the user says "do we have tests", "check test
  coverage", "the tests are thin", "set up testing", "I need a test suite",
  "are the tests any good", or "audit the tests". Use this skill whenever the
  user mentions testing, test coverage, missing tests, scaffolding tests, or
  wants to know whether the codebase is well-tested — even if they don't
  explicitly ask for an "audit".
---

# /audit-tests — Audit and Scaffold a Test Suite

You evaluate a repo's test suite against a short rubric, then offer to fix what
is missing. The audit is read-only; scaffolding only happens with explicit
consent.

## Ground rules

Inherit all ground rules from /lets-start (execute don't instruct, parallel
session safety, never enter plan mode).

**Trust what you see, not what you remember.** Test-framework conventions vary
per project and change frequently. Before claiming "this repo uses pytest",
read the config files. Before claiming a coverage number, run the coverage
tool. Don't assume — verify in the repo you're looking at right now.

**Don't write tests blind.** A test that asserts current behavior without
understanding intent is worse than no test — it freezes bugs in place. When
you scaffold tests, cover the *obvious* contracts (a function returns what
its name says, an endpoint returns the documented status, an error path
raises the documented error). For anything subtler, ask the user what the
function is supposed to do, or hand off to /plan-eng-review.

**Don't overwrite existing tests.** If a test file already exists for a module,
add new tests alongside or skip — never replace.

**Show before you install.** Any new dependency, config file, or CI workflow
goes through `AskUserQuestion` first with the exact thing you plan to add.
The user should never be surprised by what landed in their repo.

**Commit each phase cleanly.** Scaffolding work commits itself as it goes
on whatever branch you're currently on (`/lets-start` typically set up a
feature branch). Three commit points: framework + tooling setup, each
iteration of tests added, and the CI hook. Each commit must leave the
suite passing — never commit a red test. At the end of Step 4 the tree
must be clean so `/autoclean` (and the user) can trust the handoff.

## The rubric

Score the suite on five dimensions, each 0–2. Total: 0–10.

| Dimension | 2 (strong) | 1 (partial) | 0 (missing) |
|---|---|---|---|
| **Coverage** | Measurable line coverage ≥ 70% | Tests exist but coverage unmeasured, or 30–70% | No tests, or < 30% |
| **Pyramid** | Unit + integration tests both present | Only one type | No discernible test types |
| **Critical paths** | Golden path + key error paths covered for main modules | Golden path only, or only some modules | Neither |
| **Speed** | Full suite runs in < 2 min and looks deterministic | 2–10 min, or uses real network/DB without isolation | > 10 min or known-flaky |
| **CI hook** | Tests run on every PR in CI | Manual or local-only script | None |

Verdicts:
- **0–5 → "comprehensive scaffold"** — the suite is thin enough that we build
  it end-to-end: framework, coverage tooling, tests for every public surface,
  CI hook. See Step 4 for the iteration loop.
- **6–8 → "fill gaps"** — the suite is real but has specific holes; add only
  what is missing, prioritized by the rubric dimensions that scored low.
- **9–10 → "leave alone"** — recommend /qa (for web apps) or /health (for
  ongoing tracking) instead of more tests.

Treat the scores as conversation starters, not absolute truth. Explain the
reasoning behind each dimension so the user can push back.

## Step 1: Detect the project

Read the repo to figure out what we're dealing with. Look for the obvious
signals — exact filenames vary by language, but the pattern is the same:

- **Language**: `pyproject.toml` / `requirements.txt` / `setup.py` (Python),
  `package.json` (JS/TS), `go.mod` (Go), `Cargo.toml` (Rust), `Gemfile`
  (Ruby), `pom.xml` / `build.gradle` (JVM), `composer.json` (PHP). Multiple
  of these means polyglot.
- **Test framework**: pytest config in `pyproject.toml` or `pytest.ini`;
  vitest/jest config in `package.json` or a `vitest.config.*` / `jest.config.*`;
  `_test.go` siblings for Go; `[dev-dependencies]` in `Cargo.toml`; `spec/`
  for RSpec; `src/test/` for Maven/Gradle.
- **CI**: `.github/workflows/*.yml`, `.gitlab-ci.yml`, `.circleci/config.yml`,
  `Jenkinsfile`, `bitbucket-pipelines.yml`.
- **Package manager**: lockfiles are the source of truth (poetry.lock,
  package-lock.json, bun.lockb, yarn.lock, pnpm-lock.yaml, Cargo.lock, etc.).

Special cases:

- **Monorepo** (workspaces, multiple lockfiles in subdirectories, top-level
  `packages/` or `apps/`): don't try to audit everything at once. Ask which
  package or directory to focus on.
- **Polyglot repo** (e.g., Python backend + TS frontend): pick the larger
  or more critical side first, confirm with the user before doing both.
- **Nothing detected**: the repo may be empty or use a layout you haven't
  seen — ask the user how their tests are organized rather than guessing.

## Step 2: Inventory and run

Count test files. Look at the shape — are tests grouped by feature or by
source file? Single `tests/` directory or scattered `*_test.*` siblings?
Roughly how many assertions?

Then **actually run the suite** using whatever the project conventions say
(a script in `package.json`, a `Makefile` target, a `pyproject.toml`
script, or the framework default). Capture:

- Pass / fail counts.
- Wall-clock time.
- Coverage percentage *if* the framework already supports it. Don't install
  new tooling here — if coverage isn't configured, note it as a gap and move
  on. Installing things mid-audit conflates measurement with change.

If the suite is broken (tests fail or won't start), **stop the audit** and
recommend /investigate. A score on a broken suite is meaningless, and adding
more tests on top of broken ones makes everything harder to debug.

## Step 3: Score and report

Score against the rubric and write a persistent timestamped audit to a
file. The file is the authoritative record; chat is a summary of it.

### Set up the artifact location

```bash
mkdir -p .gstack/test-audits
grep -qxF '.gstack/' .gitignore 2>/dev/null || echo '.gstack/' >> .gitignore
```

If that line modified `.gitignore`, stage and commit it as
`chore(audit-tests): gitignore .gstack/ for audit artifacts` before
writing the artifact, so the tree stays clean for the next /autoclean
phase. If `.gstack/` was already ignored, do nothing.

### Write the artifact

Path: `.gstack/test-audits/<YYYY-MM-DD>-audit-tests.md`. Shape:

```markdown
# Test Suite Audit — <repo>

**Date:** <YYYY-MM-DD>
**Branch:** <branch>
**Stack:** <detected stack(s)>
**Run mode:** audit / fill-gaps / comprehensive-scaffold

## Verdict

**Total: <N>/10 — "<verdict>"**

| Dimension      | Score | Notes |
|---|---|---|
| Coverage       | <N>/2 | <evidence — file refs if relevant> |
| Pyramid        | <N>/2 | <evidence> |
| Critical paths | <N>/2 | <evidence> |
| Speed          | <N>/2 | <evidence> |
| CI hook        | <N>/2 | <evidence> |

## Scan stats

- Test files: <N>
- Tests: <N>
- Runtime: <X>s wall-clock
- Skipped / xfail / ignored: <N> / <N> / <N>
- Coverage: <X%> (or "not measured — <reason>")

## What was checked and came back clean

List only checks you actually ran with concrete evidence. A short list of
real checks beats a long list of vague claims. Pad nothing — if you
didn't look, don't list.

- <e.g. "No `.skip` / `xfail` markers in 312 tests">
- <e.g. "3 consecutive runs produced identical results — not flaky">
- <e.g. "Fixtures scoped per-test; no shared mutable state observed">
- <e.g. "Test discovery in `pyproject.toml` matches actual test layout">

## Gaps that drove the score

For each below-2 dimension, name the specific gap with evidence:

- **Coverage <N>/2:** <reason with file refs>
- **Pyramid <N>/2:** <reason>
- **CI hook <N>/2:** <reason>

## What changed (filled in by Step 5 if scaffold ran)

- Added: <files>
- Modified: <files>
- Commits: <list>

## Disclaimer

This audit is AI-assisted. Coverage tools and rubrics catch common gaps
but cannot verify whether tests genuinely exercise critical paths or
match real product behavior. Use as a first pass between manual reviews,
not as a substitute.
```

### Chat summary

After writing the artifact, summarize in chat — keep the rubric table
and reference the artifact path:

> **Test suite audit — `<repo>`** · <stack> · <N> test files · <T>s · coverage <X%>
>
> | Dimension | Score | Notes |
> |---|---|---|
> | Coverage | 1/2 | Tests exist but no `coverage` config |
> | Pyramid | 1/2 | Unit only; no integration tests for HTTP |
> | Critical paths | 2/2 | Golden + key error paths |
> | Speed | 2/2 | Fast and deterministic |
> | CI hook | 0/2 | No `.github/workflows/` |
>
> **Total: 6/10 — "fill gaps"** · artifact: `.gstack/test-audits/<date>-audit-tests.md`
>
> Biggest gaps: no coverage tracking, no integration tests, no CI hook.

End with `AskUserQuestion` offering the next move. Pick a recommendation
based on the score:

- < 6 → Recommend **Scaffold a comprehensive suite**
- 6–8 → Recommend **Fill the gaps**
- 9+ → Recommend **Stop here** + route to /qa or /health

Always include **Just the report, thanks** and **Something else** as options.

## Step 4: Scaffold (only with consent)

The goal is a *comprehensive* test suite, not a starter kit. When the user
opts to scaffold, the skill works the test surface end-to-end: every public
function, every endpoint, every CLI command, every documented behavior earns
coverage, and the loop continues until a real coverage target is hit or it's
clear no more progress is possible.

If the user explicitly asks for just a starter kit ("minimum viable", "just
the framework"), or the codebase is so domain-specific that comprehensive
coverage without their input would produce mostly wrong tests, drop to the
**Minimal scaffold** sub-mode at the end of this step. Comprehensive is the
default.

### Comprehensive scaffold

1. **Framework + tooling first.** Install the test framework as a dev
   dependency (not runtime). Add the conventional config file using the
   ecosystem's standard location and shape — defaults are usually right and
   easier for the team to maintain. Add the standard coverage tool for the
   ecosystem (e.g., `coverage` for pytest, built-in for vitest / `go test` /
   `cargo`, simplecov for Ruby). Show the planned config diff before
   applying it.

   **Coverage threshold rule:** never set the CI threshold higher than the
   *current* measured coverage. Start the threshold at the current number
   (0 if no tests existed). It rises as the iteration loop adds coverage —
   each iteration bumps it to the new measured value, so regressions break
   the build but the first PR doesn't.

   **Commit the setup.** Once the framework, coverage tool, and initial
   config are in place and the (empty or pre-existing) suite still passes,
   commit with a message like `test: scaffold <framework> with coverage`.
   This keeps the tooling change separate from the test additions that
   follow, so reviewers can see the setup as one atomic step.

2. **Enumerate the public surface.** Walk the codebase and list everything
   that needs coverage. Don't pick favorites — list it all:
   - Exported / public functions, methods, and classes
   - HTTP routes and handlers
   - CLI commands and subcommands
   - Event handlers and message consumers
   - Background jobs and scheduled tasks
   - Documented behaviors in the README

   For each item, decide what kind of test fits best (unit / integration /
   contract) and what the obvious cases are: golden path, documented error
   paths, and edge cases clear from the signature (null / empty / boundary).

   Save this list — it becomes the iteration backlog.

3. **Write tests in iterations.** Don't try to do it all at once; iterate
   in small enough batches that each pass produces a working, mergeable
   diff. For each iteration:

   - **Pick the next batch (~10 tests)** prioritized by risk: entry points
     and core business logic first, glue code next, pure helpers last.
   - **Write the tests.** Use the ecosystem's conventions exactly — match
     existing tests if any exist, otherwise match what the framework's docs
     show. Each test asserts a real behavior (return value, side effect,
     thrown error), never just an existence check.
   - **Run the suite.** Tests must pass. If a new test fails, it either
     found a real bug (flag it; the user decides whether to fix the bug or
     adjust the test) or the test is wrong (fix or drop it).
   - **Measure coverage.** Record line and branch coverage.
   - **Bump the CI threshold** to the new measured value.
   - **Commit the iteration.** Only after the suite is green and coverage
     is measured. Use a message that names the modules and the coverage
     delta, e.g. `test: cover auth + validation handlers (62% → 71% line)`.
     One commit per iteration — never bundle multiple iterations into one
     commit; reviewers and `git bisect` need clean boundaries. If a real
     bug was flagged and the user opted to fix the bug rather than adjust
     the test, that fix is a separate commit before this one.

   Then look at what's still uncovered and plan the next batch from there.

4. **Ask the user when intent is genuinely ambiguous.** If a function's
   contract isn't obvious from its name, signature, and existing call
   sites, batch the ambiguity questions and ask via `AskUserQuestion`
   (5–10 at a time, not one per call). Examples:

   - Two reasonable interpretations of a return value (empty list vs. null
     for "no results")
   - Side effects that aren't documented (does this also write to a log?)
   - Error handling philosophy (throw vs. return Result-style)

   Don't punt ambiguity by writing a smoke test that asserts current
   behavior — that freezes whatever bug might exist. Ask, or skip the item
   and note it as needing the user's attention.

5. **CI hook.** Add (or extend) a CI config that runs the test command and
   the coverage check on every PR. Detect which CI system the repo already
   uses; default to GitHub Actions if none. Keep the workflow minimal:
   check out, install deps, run tests with coverage, fail on threshold
   regression. Show the planned workflow before adding it. Commit it
   separately with a message like `ci: run tests + coverage on every PR`.

6. **Final verify.** Run the full suite and coverage tool one more time.
   Confirm: passes, coverage at or above the target, CI workflow valid,
   and `git status` is clean (every iteration committed, no stray files).
   If anything fails, fix it or back out — don't leave the repo in a worse
   state than you found it.

### Stop conditions

The iteration loop stops on the first of these:

- **Target reached.** Coverage at or above the agreed target (default
  80% line, 70% branch) **and** every item in the Step 4.2 inventory has
  at least golden-path coverage. This is the win condition.
- **Plateau.** Three consecutive iterations added less than 2% coverage
  each. The remaining gaps probably need design changes (untestable code,
  hidden dependencies, code that should be refactored to be testable) or
  domain knowledge the skill doesn't have. Stop, surface what's still
  uncovered with specifics, and recommend `/investigate` (for the
  untestable bits) or `/plan-eng-review` (for the refactor).
- **Iteration cap.** After 10 iterations, stop regardless. Report what
  landed, what's uncovered, and let the user decide whether to push
  further in a follow-up session.

In every stop case, run Step 5 (rescore + hand off) before exiting.

### Minimal scaffold (opt-in only)

Use only if the user explicitly asks for a starter kit, or the codebase is
so domain-specific that intent-free tests would mostly be wrong.

Same Step 4.1 (framework + tooling), Step 4.5 (CI hook), and Step 4.6
(verify), but skip the surface enumeration and the iteration loop. Instead,
write 2–4 representative sample tests for the most important modules —
golden path plus one error path each. Commit them as a single
`test: add starter tests for <modules>` commit once the suite is green.
Be explicit in the Step 5 handoff that this is a *starter*, not a
comprehensive suite, and that the next step is either another /audit-tests
run on comprehensive or a manual extension.

## Step 5: Report and hand off

Re-score against the same rubric and **update the existing artifact** at
`.gstack/test-audits/<YYYY-MM-DD>-audit-tests.md`:

- Set `Run mode` to reflect what actually ran (`fill-gaps` or
  `comprehensive-scaffold`) — Step 3 wrote `audit` initially.
- Overwrite the Verdict table with the new scores.
- Update Scan stats with the post-scaffold numbers (test count, runtime,
  coverage %).
- Fill in the "What changed" section: added/modified files and the
  commit list from Step 4.3.
- Add any new entries to "What was checked and came back clean" that
  the scaffold work newly verified (e.g. "CI workflow YAML lints clean
  via `actionlint`").

Then summarize the before / after in chat:

> **After scaffold:**
> - Coverage: 1/2 → 2/2 (now 78%)
> - Pyramid: 1/2 → 2/2 (added HTTP integration tests)
> - CI hook: 0/2 → 2/2 (added `.github/workflows/test.yml`)
>
> **Total: 6/10 → 10/10** · artifact updated

Then suggest the next step via `AskUserQuestion`. Tailor to what just
landed — typical options:

- `/ship` (Recommended) — push the scaffold commits and open a PR
- `/plan-eng-review` — design a deeper test strategy if the suite still
  needs more thought
- `/health` — track quality over time
- Something else / stop

## Edge cases

**No source code yet.** Repo is empty or only contains docs. Don't scaffold
— say so and suggest coming back once there's code to test.

**Tests exist but fail.** Don't score, don't scaffold. Recommend /investigate
to root-cause the failures first. Adding more tests on top of broken ones
makes debugging harder.

**Generated or vendored code.** Exclude `node_modules/`, `vendor/`, `dist/`,
`build/`, `__pycache__/`, `target/`, etc. from both the audit and any
scaffolded coverage config. Coverage of generated code is meaningless.

**Monorepo with many packages.** Audit one package at a time. If the user
wants all of them, audit each in sequence and produce a combined report —
don't try to score a monorepo as one number.

**User insists on scaffolding when the suite is already 9+.** Respect the
request, but flag that they might be looking for /plan-eng-review (test
strategy) or /qa (live testing) rather than more unit tests.

**Suite uses a non-standard or legacy framework.** Don't force a migration.
Use the existing framework and add tests in its idiom. Suggest migration as
a separate project, not bundled into the audit.

**The suite or audit takes more than ~5 minutes to run.** Something is wrong
— the suite is huge, slow, or stuck. Stop, report what you have, and ask
the user before going further.

**User wants only the audit, no scaffold.** Stop after Step 3. The report
alone is valuable.

**User wants only the scaffold (already knows the suite is bad).** Run a
quick Step 1+2 to detect the framework and existing layout, then jump to
Step 4 with a default rubric assumption of "0–3 across the board" and
**comprehensive** as the default mode. Don't skip detection entirely —
scaffolding the wrong framework is worse than scaffolding slowly. If the
user wants the minimal sub-mode instead, they have to say so.

**Coverage tool fights you (slow, broken on this codebase, false reports).**
Don't paper over it. Score Coverage as 1/2 with a note, and recommend a
separate /investigate session to fix the tooling rather than blocking the
audit.
