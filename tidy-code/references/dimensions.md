# Dimensions: detection tools per stack

For each dimension, run the tools listed for the detected stack(s). Tools are advisory — they flag candidates, you decide whether to act.

## Node / TypeScript

**Dead code:**
- `npx knip` — unused files, exports, dependencies, types
- `npx ts-prune` — unused exports
- `npx eslint --rule "no-unused-vars: error" --rule "@typescript-eslint/no-unused-vars: error" .`
- `npx tsc --noEmit` — catches dead types referenced nowhere

**DRY:**
- `npx jscpd .` — token-based copy-paste detector (fast; low recall when identifiers are renamed)
- `semgrep scan --config auto src/` — AST-pattern scan; catches identifier-renamed and statement-reordered duplicates that token tools miss
- `npx eslint --rule 'sonarjs/no-identical-functions: error' --rule 'sonarjs/no-duplicated-branches: error' .` — requires `eslint-plugin-sonarjs` in devDependencies; flags function-body and branch-body duplicates at AST level (the exact `--rule` CLI form should be confirmed against `npx eslint --help` for your ESLint version)
- Manual review of `src/` for parallel type definitions

**Defensive cruft:**
- `grep -rn "try {" src/ | wc -l` — get a baseline count, then read each
- `grep -rn "?? " src/` and `grep -rn "|| " src/` — fallback hiding
- `grep -rn "as any\|as unknown" src/` — type-system bypasses

**Legacy:**
- `grep -rn "TODO\|FIXME\|DEPRECATED\|XXX\|HACK" src/`
- `grep -rn "if.*legacy\|if.*old_\|if.*deprecated" src/`

**Verify:**
- `npm run typecheck` (or `npx tsc --noEmit`)
- `npm run lint`
- `npm test`
- `npm run build`

## Python

**Dead code:**
- `vulture .` — unused code (functions, classes, attributes). Run at TWO thresholds: `--min-confidence 80` for items safe to delete on sight, and `--min-confidence 60` for items that need human review (public exports, dynamic dispatch, decorator-registered functions surface here). `run-detectors.sh dead-code` does both automatically.
- `ruff check --select F401,F811,F841,F501 .` — unused imports, redefinitions, unused variables
- `pyflakes .`
- `python -m unused_imports` if installed

**DRY:**
- `pylint --disable=all --enable=duplicate-code .` — line-window token comparison
- `semgrep scan --config auto .` — AST-pattern scan; tolerates identifier renames and minor reordering that pylint misses
- Manual review for parallel Pydantic models, near-duplicate request handlers

**Defensive cruft:**
- `grep -rn "except:\s*$\|except Exception:" .` — bare/broad excepts
- `grep -rn "\.get(.*,\s*None)\|\.get(.*,\s*\"\")" .` — defensive `.get()` hiding missing keys
- `grep -rn "if.*is not None" .` — null checks in typed code

**Legacy:**
- `grep -rn "TODO\|FIXME\|DEPRECATED\|XXX\|HACK" .`
- `grep -rn "if.*legacy\|if.*old_\|# deprecated" .`

**Verify:**
- `mypy .` or `pyright`
- `ruff check .`
- `pytest`
- `python -m build` if it's a package

## Go

**Dead code:**
- `staticcheck ./...` — includes U1000 (unused)
- `go vet ./...`
- `deadcode ./...` if installed
- `unused ./...` if installed

**DRY:**
- `dupl -threshold 50 ./...` — Go-aware AST-token detector; already normalizes identifier names
- `semgrep scan --config auto ./...` — adds cross-package pattern matching for shapes `dupl` misses (e.g. duplicate handler scaffolds across packages)

**Defensive cruft:**
- `grep -rn "if err != nil {\s*return nil\s*}" .` — error swallowing
- `grep -rn "_ = " .` — explicit error ignoring

**Verify:**
- `go build ./...`
- `go test ./...`
- `staticcheck ./...`

## Rust

**Dead code:**
- `cargo clippy --all-targets --all-features -- -W dead_code -W unused_imports`
- `cargo +nightly udeps --all-targets` — unused dependencies
- `RUSTFLAGS="-W dead_code" cargo build`

**DRY:** Manual; clippy catches some.

**Verify:**
- `cargo build --all-targets`
- `cargo test`
- `cargo clippy -- -D warnings`

## Java / Kotlin

**Dead code:**
- `pmd` with the `unusedcode` ruleset
- IntelliJ inspection: "Unused declaration" via `idea inspect` if available
- `gradle dependencyAnalysis` for unused deps

**Verify:**
- `gradle build`
- `gradle test`

## Ruby

**Dead code:**
- `rubocop --only Lint/UnusedMethodArgument,Lint/UselessAssignment`
- `debride lib/`

**Verify:**
- `rubocop`
- `rspec` or `rake test`

## .NET / C#

**Dead code:**
- `dotnet build /p:TreatWarningsAsErrors=true` — surfaces unused
- ReSharper CLI: `inspectcode` if available
- Roslynator analyzers

**Verify:**
- `dotnet build`
- `dotnet test`

## PHP

**Dead code:**
- `composer require --dev phpstan/phpstan` then `vendor/bin/phpstan analyse --level 8`
- `psalm --find-dead-code`

**Verify:**
- `vendor/bin/phpstan analyse`
- `vendor/bin/phpunit`

## DRY handoff (all stacks)

Duplicate detectors have high recall but high noise — they flag boilerplate, test scaffolds, and similar-looking-but-semantically-distinct code. Treat their output as **candidate clusters**, not a kill list. The agent's job is the filter step.

For each DRY pass:

1. Run the detector(s) for the stack. Capture output verbatim into a scratch file.
2. Group findings into clusters by file-pair or pattern. Discard any cluster smaller than the stack's meaningful unit (e.g. <6 lines for TS/Python, <10 for Go).
3. For each remaining cluster, write exactly one line in `TIDY_LOG.md` under the DRY heading:
   - `CONSOLIDATE: <files> → <new shared location>` — the abstraction would be clean
   - `LEAVE: <files> — <reason>` — applies the existing rule "would the shared abstraction be ugly?" (yes → leave), or the duplication is incidental (similar fixtures, similar boilerplate)
   - `CANDIDATE: <files> — needs human review` — can't decide; defer to a human reviewer
4. Apply only the `CONSOLIDATE` clusters. `LEAVE` and `CANDIDATE` entries stay as documentation of what was considered and skipped.

Reviewers should see one decision per cluster in the log, not raw detector output. This makes the precision/recall tradeoff auditable: a future tidy pass can re-read the log and see which clusters were already triaged.

## Polyglot repos

If multiple stacks are present (e.g. TS frontend + Python backend), tidy each stack as a separate dimension cycle. Don't run TS tools against `backend/`. Use the directory boundaries the manifest files imply.

## Tool not installed?

If a recommended detector isn't in the project's dev dependencies, surface that as a finding in `TIDY_LOG.md` ("Recommended adding `vulture` to dev deps for future tidy passes") but **don't add it as a dependency** — that's a stack change, out of scope for tidy.
