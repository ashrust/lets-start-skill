---
name: tidy-code
description: Tidy up an existing codebase in safe, reviewable passes. Removes dead code, duplication, defensive cruft, and legacy paths; audits and improves comments and docstrings. Use this skill whenever the user asks to "tidy", "clean up", "refactor for cleanliness", "remove dead code", "remove unused code", "deslop", "audit comments", "add missing comments", "add docstrings", or says the codebase has rotted, gotten messy, accumulated cruft, or needs a quality pass. Trigger even when the user only mentions one of those goals — the skill scopes itself to what they asked for. Do NOT use for behavior changes, framework migrations, dependency upgrades, or new features. Behavior-preserving cleanup only.
---

# /tidy-code — codebase cleanup in safe passes

Tidy is a **behavior-preserving** cleanup pass over an existing codebase. It does five things, in order, each as its own commit:

1. **Detect dead code** — unused exports, functions, classes, variables, types, imports, files, dead conditional branches, commented-out code blocks
2. **Consolidate duplication (DRY)** — near-duplicate helpers, copy-pasted logic, parallel type definitions
3. **Trim defensive cruft** — try/catch that swallows errors, null checks the type system already guarantees, fallback values that hide failure
4. **Remove legacy paths** — `if old_format:` branches, compatibility shims, deprecated API handlers with no callers
5. **Audit comments and docstrings** — remove slop and stale comments, add docstrings to public APIs, add "why" comments where logic is non-obvious

Public API behavior must stay identical. If a change would alter observable behavior, **stop and ask** — that's a refactor, not a tidy.

## Critical rules

- **One dimension per commit.** Never mix dead-code removal with a DRY refactor in the same commit. Reviewers and `git bisect` need clean boundaries.
- **Verify after every dimension.** Run type-check, lint, and tests before moving to the next dimension. If verification fails, fix or revert before continuing.
- **Maintain a deletion log.** Every file removed and every export deleted goes into `TIDY_LOG.md` with a one-line reason. This is the artifact reviewers actually read.
- **When unsure, mark as candidate, don't delete.** A file moved to `// CANDIDATE FOR REMOVAL` with a comment is recoverable. A deleted file in a 200-file diff is not.
- **Do not change public APIs.** Exported function signatures, HTTP routes, CLI flags, env-var names, DB schemas — all stay identical. **Removing a parameter** (even an unused default-valued one) **is a signature change**: surface it as a finding for human review, do NOT delete. **Narrowing an exception type** in a public function is a behavior change too — only do it if the function's documented contract names the specific exception; otherwise flag and leave alone. If a public API has zero internal callers, surface it as a finding for human review, don't delete it.
- **Do not mix in framework migrations or dependency upgrades.** Those go in a separate task. Tidy is structural cleanup against the existing stack.
- **Worktree isolation if running multiple agents.** If the user asks for parallel passes, each agent must work in its own `git worktree`. Never let two agents edit the same branch concurrently.

## Workflow

### Step 0 — Confirm scope

Before touching anything, restate what you're about to do and confirm:

- Which directories are in scope? (default: whole repo, exclude `node_modules/`, `vendor/`, `dist/`, `build/`, generated code, migrations)
- Which dimensions does the user want? (default: all five)
- How aggressive on comments? (default: add docstrings to public APIs, remove obvious slop, keep judgment-call comments)

If the user says "go" or "do everything", proceed with defaults.

### Step 1 — Set up the branch and log

Run `scripts/init-tidy-branch.sh`. It creates `tidy/cleanup-<date>` from the current base branch, drops `TIDY_LOG.md` at the repo root with a header section per dimension, and confirms a clean working tree before any edits.

### Step 2 — Detect the stack

Run `scripts/detect-stack.sh`. It inspects manifest files (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `Gemfile`, `*.csproj`, `composer.json`) and prints the detected stack(s) plus the verification commands it will use later.

If the repo is polyglot (e.g. TypeScript frontend + Python backend), tidy each stack separately — don't try to run all detectors against all directories.

### Step 3 — Run the dimensions, one at a time

For each dimension below, follow the same four-step rhythm:

1. **Detect** — run static-analysis tools to gather evidence. See `references/dimensions.md` for the per-stack tool list.
2. **Plan** — write the proposed deletions/changes into `TIDY_LOG.md` under the dimension's heading. Group by file. For anything ambiguous, mark `CANDIDATE` and skip. **Also fill in the dimension's `### Scanned clean` section** with what was checked and found clean — list only checks you actually ran with concrete evidence (e.g. "412 .ts files scanned for unused imports — none found"). Pad nothing. A short list of real checks beats a long list of vague claims.
3. **Apply** — make the edits. Keep the diff focused on this dimension only.
4. **Verify and commit** — run `scripts/commit-dimension.sh <dimension> "<one-line summary>"`. The script runs `verify.sh` and refuses to commit if anything fails. Never run `git commit` directly — verify gates every dimension. If verify fails, fix the failures or revert before retrying.

Dimensions in order:

#### Dimension 1: Dead code

Tools tell you what's unused. Read `references/dimensions.md` for the per-stack list (`knip`, `ts-prune`, `ruff`, `vulture`, `staticcheck`, `cargo +nightly udeps`, etc.).

Categories:
- Unused exports, functions, classes, methods
- Unused imports, variables, type definitions, Pydantic/Zod models
- Unreachable branches (`if old_format:`, `if False:`, dead `case` arms)
- Commented-out code blocks (excluding doc comments and `references/comments.md` exceptions)
- Test files and cases targeting deleted symbols

Be careful with: dynamic dispatch (reflection, string-based imports, decorators), public APIs with zero internal callers (could be used by external consumers), test helpers used only across test files.

#### Dimension 2: Duplication / DRY

Look for near-duplicate functions, copy-pasted control flow, parallel type/model definitions in multiple files, and repeated request/response shapes.

For each duplicate cluster: extract a single source of truth, replace call sites, remove the duplicates. Don't over-abstract — if two functions look similar but the shared abstraction would be ugly, leave them.

#### Dimension 3: Defensive cruft

This dimension has the most KEEP/REMOVE judgment calls. Read `references/keep-or-remove.md` before applying edits. The rule of thumb:

- **KEEP** error handling for unknown/external input, genuinely unpredictable failures, and catches that do something meaningful (retry, surface a user-facing error, clean up resources)
- **REMOVE** error handling that silently swallows errors, returns fake defaults to hide failures, defends against impossible states the type system already prevents, or wraps code that can't actually throw

#### Dimension 4: Legacy paths

Hunt for: format-version branches no version still emits, feature flags wired to constants, deprecated handler functions with no callers, commented-out alternative implementations.

For each: confirm via grep that nothing actually hits the legacy path, then delete.

#### Dimension 5: Comments and docstrings

This is the dimension users notice most, so do it last (after the code is stable) and follow `references/comments.md` strictly.

Two sub-passes, each with its own commit:

1. **Remove slop** — obvious restatement comments (`# increment x`), AI-generated narration, stale comments contradicted by current code, commented-out code that survived dimension 1
2. **Add docstrings AND why-comments** — every exported/public function, class, and module gets a docstring matching the language convention (JSDoc/TSDoc for TS, Google-style or numpy-style for Python, godoc for Go, rustdoc for Rust). Description, params, return value, raised errors. Also, anywhere the logic looks weird, has a non-obvious constraint, works around a bug, or makes a performance trade-off, add a one-line comment explaining the why. Don't comment the what; the code already shows the what. If after looking carefully there are no genuine why-candidates, that's fine — say so in the log and move on. Don't invent justifications.

### Step 4 — Final report

After all dimensions verify clean, fill in the two summary blocks at the top of `TIDY_LOG.md` and append the disclaimer at the bottom.

**Summary** (the headline numbers reviewers read first):

```
Branch: tidy/cleanup-<date>
Base:   <base-branch>
Dimensions run: dead-code, dry, defensive, legacy, comments
Verification: type-check ✓  lint ✓  tests ✓  build ✓
Stats: N files changed, M files deleted, K files added, L lines net (-Δ)
Commits: <list of dimension commits>
```

**Scan stats** (what was looked at vs. what was acted on — the rigor signal):

```
Files in scope: N (excluded: node_modules, vendor, dist, build, generated)
Tools run: <per dimension, e.g. dead-code → ts-prune, knip; defensive → custom eslint rules>
Candidates surfaced: N total
Applied: N · CANDIDATE (left in place): N · Surfaced as out-of-scope finding: N
```

Append the **Disclaimer** at the end of `TIDY_LOG.md`:

```
## Disclaimer

This cleanup is AI-assisted using static-analysis tooling. Tools can
miss dynamic dispatch, reflection-based usage, and code reachable only
at runtime. Review the diff for anything safety-critical before merging.
```

State the facts. Do not add "next steps" or recommend what to do next — the user knows their workflow.

### Step 5 — Optional: second opinion via gstack

If the project has gstack installed (`~/.claude/skills/gstack/` exists), suggest running `/codex` for a cross-model adversarial review of the cleanup branch before merge. Don't run it automatically.

## What this skill does NOT do

- Behavior changes, even small ones
- Framework migrations or dependency upgrades
- New features, new tests, new types
- Performance optimizations beyond removing obvious wasted work
- Style/formatting changes (use the project's formatter for that)
- Renaming variables, functions, or files for "clarity" — that's a separate refactor

If the user asks for any of these, push back and offer to do them as a separate task after tidy lands.

## Reference files

- `references/dimensions.md` — per-stack tool list and detection commands for each dimension
- `references/comments.md` — comment audit rules (what to remove, what to add, what to keep)
- `references/keep-or-remove.md` — decision rules for defensive code (try/catch, null checks, fallbacks)
- `references/log-template.md` — template for `TIDY_LOG.md`

## Scripts

- `scripts/init-tidy-branch.sh` — create the cleanup branch and seed `TIDY_LOG.md`
- `scripts/detect-stack.sh` — detect language(s) and emit the verification command set
- `scripts/run-detectors.sh <dimension>` — run static-analysis tools for a given dimension
- `scripts/verify.sh` — type-check + lint + tests + build, fail loudly on any red
- `scripts/commit-dimension.sh <dim> "<msg>"` — verify-then-commit; the ONLY way to commit a dimension
