#!/usr/bin/env bash
# detect-stack.sh
# Inspect manifest files to determine the stack(s) and print verification commands.

set -euo pipefail

declare -a STACKS=()

# Enable nullglob so non-matching globs expand to empty arrays at the call site.
shopt -s nullglob globstar

# helper: does any path match the given glob?
has_glob() { [[ $# -gt 0 ]]; }

[[ -f "package.json" ]] && STACKS+=("node")
{ [[ -f "tsconfig.json" ]] || has_glob ./**/tsconfig.json; } && STACKS+=("typescript")
[[ -f "pyproject.toml" || -f "setup.py" || -f "requirements.txt" ]] && STACKS+=("python")
[[ -f "go.mod" ]] && STACKS+=("go")
[[ -f "Cargo.toml" ]] && STACKS+=("rust")
[[ -f "pom.xml" ]] && STACKS+=("java-maven")
{ [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; } && STACKS+=("java-gradle")
[[ -f "Gemfile" ]] && STACKS+=("ruby")
has_glob ./*.csproj && STACKS+=("dotnet")
[[ -f "composer.json" ]] && STACKS+=("php")

shopt -u nullglob globstar

# de-dupe (typescript can be added on top of node)
mapfile -t STACKS < <(printf "%s\n" "${STACKS[@]}" | awk '!seen[$0]++')

if [[ ${#STACKS[@]} -eq 0 ]]; then
  echo "warn: no recognized manifest files found in $(pwd)" >&2
  echo "      tidy can still run, but you'll need to specify verify commands manually." >&2
  exit 2
fi

echo "Detected stack(s): ${STACKS[*]}"
echo ""
echo "Verification commands (will be run by verify.sh):"
echo ""

for stack in "${STACKS[@]}"; do
  case "$stack" in
    node)
      # If typescript is also detected, skip — the typescript case handles npm scripts
      printf '%s\n' "${STACKS[@]}" | grep -qx typescript && continue
      grep -q '"lint"'  package.json 2>/dev/null && echo "  npm run lint"
      grep -q '"test"'  package.json 2>/dev/null && echo "  npm test"
      grep -q '"build"' package.json 2>/dev/null && echo "  npm run build"
      ;;
    typescript)
      if grep -q '"typecheck"' package.json 2>/dev/null; then
        echo "  npm run typecheck"
      else
        echo "  npx tsc --noEmit"
      fi
      grep -q '"lint"'  package.json 2>/dev/null && echo "  npm run lint"
      grep -q '"test"'  package.json 2>/dev/null && echo "  npm test"
      grep -q '"build"' package.json 2>/dev/null && echo "  npm run build"
      ;;
    python)
      command -v mypy >/dev/null 2>&1 && echo "  mypy ."
      command -v ruff >/dev/null 2>&1 && echo "  ruff check ."
      command -v pytest >/dev/null 2>&1 && echo "  pytest"
      ;;
    go)
      echo "  go build ./..."
      echo "  go test ./..."
      command -v staticcheck >/dev/null 2>&1 && echo "  staticcheck ./..."
      ;;
    rust)
      echo "  cargo build --all-targets"
      echo "  cargo test"
      echo "  cargo clippy -- -D warnings"
      ;;
    java-maven)
      echo "  mvn verify"
      ;;
    java-gradle)
      echo "  gradle build"
      echo "  gradle test"
      ;;
    ruby)
      command -v rubocop >/dev/null 2>&1 && echo "  rubocop"
      command -v rspec >/dev/null 2>&1 && echo "  rspec"
      ;;
    dotnet)
      echo "  dotnet build"
      echo "  dotnet test"
      ;;
    php)
      [[ -x "vendor/bin/phpstan" ]] && echo "  vendor/bin/phpstan analyse"
      [[ -x "vendor/bin/phpunit" ]] && echo "  vendor/bin/phpunit"
      ;;
  esac
done

echo ""
# write detected stacks into TIDY_LOG.md
if [[ -f "TIDY_LOG.md" ]]; then
  python3 - <<PY 2>/dev/null || sed -i.bak "s|^Stack:.*|Stack:  ${STACKS[*]}|" TIDY_LOG.md
import re, pathlib
p = pathlib.Path("TIDY_LOG.md")
text = p.read_text()
text = re.sub(r"^Stack:.*$", "Stack:  ${STACKS[*]}", text, count=1, flags=re.MULTILINE)
p.write_text(text)
PY
  rm -f TIDY_LOG.md.bak
fi
