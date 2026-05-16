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
- **0–5 → "scaffold over"** — the suite is thin enough that a fresh framework
  + sample tests + CI hook is the right move.
- **6–8 → "fill gaps"** — the suite is real but has specific holes; add only
  what is missing.
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

Apply the rubric. Present the result in this shape:

> **Test suite audit — `<repo or package name>`**
>
> Language: Python (pytest) · 47 test files · 312 tests · 4.2s · coverage not measured
>
> | Dimension | Score | Notes |
> |---|---|---|
> | Coverage | 1/2 | Tests exist but no `coverage` config — couldn't measure |
> | Pyramid | 1/2 | Unit tests only; no integration tests for the HTTP layer |
> | Critical paths | 2/2 | Golden path covered; error paths for auth + validation |
> | Speed | 2/2 | Fast and deterministic |
> | CI hook | 0/2 | No `.github/workflows/` — tests don't run on PR |
>
> **Total: 6/10 — "fill gaps"**
>
> The big gaps: no coverage tracking, no integration tests for HTTP, no CI hook.

End with `AskUserQuestion` offering the next move. Pick a recommendation
based on the score:

- < 6 → Recommend **Scaffold a comprehensive suite**
- 6–8 → Recommend **Fill the gaps**
- 9+ → Recommend **Stop here** + route to /qa or /health

Always include **Just the report, thanks** and **Something else** as options.

## Step 4: Scaffold (only with consent)

If the user opts in, scaffold the missing pieces. Order matters — get the
infrastructure right before writing tests on top of it.

1. **Framework config first.** Make sure the test framework is installed in
   the right place (dev dependency, not runtime). Set up a proper config
   file using the ecosystem's conventional location and shape. Don't pick
   exotic options — defaults are usually right and easier for the team to
   maintain. Show the planned config diff before applying it.

2. **Coverage tooling.** Add the standard coverage tool for the ecosystem
   (e.g., `coverage` for pytest, built-in for vitest / `go test` / `cargo`,
   simplecov for Ruby). Configure a minimum threshold the user agrees to.
   Never set the threshold higher than the current coverage — that just
   creates a broken build on the first PR. Show the planned threshold and
   the current coverage side by side before setting it.

3. **Sample tests for key modules.** Identify the 2–4 most important modules
   — usually entry points, core business logic, anything the README
   highlights. For each, write tests covering:
   - **The golden path** — call it the way it's documented or used in
     practice.
   - **One or two error paths** — invalid input, missing resource, etc.

   Keep these short and readable. Their job is to model the pattern, not
   to exhaustively cover the module. The user (or a follow-up session) will
   extend them. If the module's intent isn't obvious from the code, ask
   before writing — better to write one good test than five wrong ones.

4. **CI hook.** Add a CI config that runs the test command on every PR.
   Detect which CI system the repo already uses; if none, default to
   GitHub Actions (most common). Keep the workflow minimal: check out,
   install deps, run tests, upload coverage if applicable. Show the
   planned workflow before adding it.

5. **Verify.** Run the suite one more time. Confirm it passes, coverage
   is now measured, and the new tests are picked up. If anything fails,
   either fix it or back out the change — don't leave the repo in a worse
   state than you found it.

## Step 5: Report and hand off

Re-score against the same rubric and show the before / after:

> **After scaffold:**
> - Coverage: 1/2 → 2/2 (now 78%)
> - Pyramid: 1/2 → 2/2 (added HTTP integration tests)
> - CI hook: 0/2 → 2/2 (added `.github/workflows/test.yml`)
>
> **Total: 6/10 → 10/10**

Then suggest the next step via `AskUserQuestion`. Tailor to what just
landed — typical options:

- `/ship` (Recommended) — commit and PR what we just added
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
Step 4 with a default rubric assumption of "0–3 across the board". Don't
skip detection entirely — scaffolding the wrong framework is worse than
scaffolding slowly.

**Coverage tool fights you (slow, broken on this codebase, false reports).**
Don't paper over it. Score Coverage as 1/2 with a note, and recommend a
separate /investigate session to fix the tooling rather than blocking the
audit.
