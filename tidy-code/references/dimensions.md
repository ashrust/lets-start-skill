# Dimensions: detection tools per stack

For each dimension, run the tools listed for the detected stack(s). Tools are advisory — they flag candidates, you decide whether to act.

## Node / TypeScript

**Dead code:**
- `npx knip` — unused files, exports, dependencies, types
- `npx ts-prune` — unused exports
- `npx eslint --rule "no-unused-vars: error" --rule "@typescript-eslint/no-unused-vars: error" .`
- `npx tsc --noEmit` — catches dead types referenced nowhere

**DRY:**
- `npx jscpd .` — copy-paste detector
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
- `pylint --disable=all --enable=duplicate-code .`
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

**DRY:** `dupl -threshold 50 ./...`

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

## Polyglot repos

If multiple stacks are present (e.g. TS frontend + Python backend), tidy each stack as a separate dimension cycle. Don't run TS tools against `backend/`. Use the directory boundaries the manifest files imply.

## Tool not installed?

If a recommended detector isn't in the project's dev dependencies, surface that as a finding in `TIDY_LOG.md` ("Recommended adding `vulture` to dev deps for future tidy passes") but **don't add it as a dependency** — that's a stack change, out of scope for tidy.
