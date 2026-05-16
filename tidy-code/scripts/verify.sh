#!/usr/bin/env bash
# verify.sh
# Run the verification suite for the detected stack(s). Exit non-zero on any failure.
# Run this after every dimension before committing.

set -uo pipefail   # NOTE: intentionally NOT using -e so we can collect all failures

declare -a FAILED=()

run() {
  local label="$1"; shift
  echo ""
  echo "==> ${label}: $*"
  if "$@"; then
    echo "    ✓ ${label} passed"
  else
    echo "    ✗ ${label} FAILED"
    FAILED+=("${label}")
  fi
}

# Node / TS
if [[ -f "package.json" ]]; then
  if grep -q '"typecheck"' package.json 2>/dev/null; then
    run "typecheck" npm run typecheck --silent
  elif [[ -f "tsconfig.json" ]]; then
    run "typecheck" npx --yes tsc --noEmit
  fi
  grep -q '"lint"' package.json 2>/dev/null && run "lint"  npm run lint  --silent
  grep -q '"test"' package.json 2>/dev/null && run "tests" npm test      --silent
  grep -q '"build"' package.json 2>/dev/null && run "build" npm run build --silent
fi

# Python
if [[ -f "pyproject.toml" || -f "setup.py" || -f "requirements.txt" ]]; then
  command -v mypy   >/dev/null 2>&1 && run "mypy"   mypy .
  command -v ruff   >/dev/null 2>&1 && run "ruff"   ruff check .
  command -v pytest >/dev/null 2>&1 && run "pytest" pytest -q
fi

# Go
if [[ -f "go.mod" ]]; then
  run "go build" go build ./...
  run "go test"  go test  ./...
  command -v staticcheck >/dev/null 2>&1 && run "staticcheck" staticcheck ./...
fi

# Rust
if [[ -f "Cargo.toml" ]]; then
  run "cargo build"  cargo build --all-targets
  run "cargo test"   cargo test
  run "cargo clippy" cargo clippy -- -D warnings
fi

# Ruby
if [[ -f "Gemfile" ]]; then
  command -v rubocop >/dev/null 2>&1 && run "rubocop" rubocop
  command -v rspec   >/dev/null 2>&1 && run "rspec"   rspec
fi

# .NET
shopt -s nullglob
CSPROJ=( ./*.csproj )
shopt -u nullglob
if [[ ${#CSPROJ[@]} -gt 0 ]]; then
  run "dotnet build" dotnet build --nologo
  run "dotnet test"  dotnet test  --nologo
fi

# PHP
if [[ -f "composer.json" ]]; then
  [[ -x "vendor/bin/phpstan" ]] && run "phpstan" vendor/bin/phpstan analyse
  [[ -x "vendor/bin/phpunit" ]] && run "phpunit" vendor/bin/phpunit
fi

# Java (Maven)
[[ -f "pom.xml" ]] && command -v mvn >/dev/null 2>&1 && run "maven verify" mvn -B verify

# Java (Gradle)
{ [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; } && command -v gradle >/dev/null 2>&1 && run "gradle build" gradle build

echo ""
echo "----------------------------------------"
if [[ ${#FAILED[@]} -eq 0 ]]; then
  echo "ALL VERIFICATIONS PASSED"
  exit 0
else
  echo "FAILED: ${FAILED[*]}"
  echo "Fix or revert before continuing to the next dimension."
  exit 1
fi
