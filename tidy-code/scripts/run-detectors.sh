#!/usr/bin/env bash
# run-detectors.sh <dimension>
# Run static-analysis detectors for a given dimension. Output is advisory; the
# skill body decides what to act on.
#
# Dimensions:
#   dead-code   — unused code finders
#   dry         — duplication detection
#   defensive   — patterns suggesting defensive cruft
#   legacy      — legacy markers (TODO/FIXME/DEPRECATED/old_format branches)

set -uo pipefail

DIMENSION="${1:-}"
if [[ -z "$DIMENSION" ]]; then
  echo "usage: run-detectors.sh <dead-code|dry|defensive|legacy>" >&2
  exit 2
fi

run() {
  local label="$1"; shift
  echo ""
  echo "==> ${label}: $*"
  "$@" || true   # detectors often exit non-zero when they find things; that's expected
}

case "$DIMENSION" in
  dead-code)
    [[ -f "package.json" ]] && {
      command -v npx >/dev/null && run "knip"      npx --yes knip
      command -v npx >/dev/null && run "ts-prune"  npx --yes ts-prune
      command -v npx >/dev/null && run "tsc"       npx --yes tsc --noEmit
    }
    [[ -f "pyproject.toml" || -f "setup.py" ]] && {
      if command -v vulture >/dev/null; then
        echo ""
        echo "==> vulture (HIGH confidence ≥80 — usually safe to delete):"
        vulture . --min-confidence 80 || true
        echo ""
        echo "==> vulture (MEDIUM confidence ≥60 — REVIEW EACH; public exports and dynamic dispatch surface here):"
        vulture . --min-confidence 60 || true
      fi
      command -v ruff    >/dev/null && run "ruff (unused)" ruff check --select F401,F811,F841 .
      command -v pyflakes>/dev/null && run "pyflakes" pyflakes .
    }
    [[ -f "go.mod" ]] && {
      command -v staticcheck >/dev/null && run "staticcheck" staticcheck ./...
      run "go vet" go vet ./...
      command -v deadcode >/dev/null && run "deadcode" deadcode ./...
    }
    [[ -f "Cargo.toml" ]] && {
      run "clippy dead_code" cargo clippy --all-targets -- -W dead_code -W unused_imports
    }
    [[ -f "Gemfile" ]] && {
      command -v debride >/dev/null && run "debride" debride lib/
      command -v rubocop >/dev/null && run "rubocop unused" rubocop --only Lint/UnusedMethodArgument,Lint/UselessAssignment
    }
    ;;

  dry)
    [[ -f "package.json" ]] && command -v npx >/dev/null && run "jscpd" npx --yes jscpd .
    [[ -f "pyproject.toml" || -f "setup.py" ]] && command -v pylint >/dev/null && \
      run "pylint duplicate-code" pylint --disable=all --enable=duplicate-code .
    [[ -f "go.mod" ]] && command -v dupl >/dev/null && run "dupl" dupl -threshold 50 ./...
    ;;

  defensive)
    echo "==> grepping for defensive patterns"
    # exclude common noise dirs (array so word-splitting is intentional and safe)
    EXCL=(--exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=dist
          --exclude-dir=build --exclude-dir=.git --exclude-dir=target
          --exclude-dir=__pycache__)
    echo ""
    echo "--- bare/broad excepts (Python) ---"
    grep -rn "${EXCL[@]}" -E "except:\s*$|except Exception:" . 2>/dev/null || true
    echo ""
    echo "--- swallowed errors (TS/JS): catch with empty body ---"
    grep -rn "${EXCL[@]}" -E "catch\s*\([^)]*\)\s*\{\s*\}" . 2>/dev/null || true
    echo ""
    echo "--- Python: .get() with non-None default (review — may hide missing data) ---"
    # flags any .get(key, default) including string and placeholder defaults like 'unknown'
    grep -rn "${EXCL[@]}" -E "\.get\([^,)]+,\s*[^)]+\)" . 2>/dev/null \
      | grep -v "os.environ.get" 2>/dev/null || true
    echo ""
    echo "--- Python: 'value or default' fallback pattern ---"
    grep -rn "${EXCL[@]}" -E "= [a-zA-Z_][a-zA-Z0-9_.]* or [\"']" . 2>/dev/null || true
    echo ""
    echo "--- type-system bypasses (TS) ---"
    grep -rn "${EXCL[@]}" -E "as any\b|as unknown\b" . 2>/dev/null || true
    echo ""
    echo "--- Go error swallowing ---"
    grep -rn "${EXCL[@]}" -E "_ = " . 2>/dev/null | grep -v "_test.go" || true
    ;;

  legacy)
    EXCL=(--exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=dist
          --exclude-dir=build --exclude-dir=.git --exclude-dir=target)
    echo "==> grepping for legacy markers"
    echo ""
    echo "--- TODO / FIXME / DEPRECATED / XXX / HACK ---"
    grep -rn "${EXCL[@]}" -E "TODO|FIXME|DEPRECATED|XXX|HACK" . 2>/dev/null | head -200 || true
    echo ""
    echo "--- legacy/old format branches ---"
    grep -rn "${EXCL[@]}" -E "if.*legacy|if.*old_|if.*deprecated|if.*v1[^0-9]|api_version" . 2>/dev/null || true
    echo ""
    echo "--- commented-out code blocks (heuristic) ---"
    echo "(scan manually — too noisy to detect cleanly)"
    ;;

  *)
    echo "error: unknown dimension '$DIMENSION'" >&2
    echo "valid: dead-code | dry | defensive | legacy" >&2
    exit 2
    ;;
esac

echo ""
echo "==> ${DIMENSION} detection complete. Review output, then plan edits in TIDY_LOG.md before applying."
