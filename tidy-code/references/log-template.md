# Tidy log template

This file is created in the repo root by `init-tidy-branch.sh` and updated as each dimension runs. It's the artifact reviewers actually read when the PR opens.

## Template

```markdown
# Tidy cleanup — <YYYY-MM-DD>

Branch: tidy/cleanup-<date>
Base:   <base-branch>
Stack:  <detected-stack(s)>

## Summary

(filled in at the end)

- Files changed: N
- Files deleted: M
- Files added:   K
- Net lines:     -L

Verification:
- type-check ✓
- lint       ✓
- tests      ✓
- build      ✓

Scan stats:
- Files in scope: N (excluded: node_modules, vendor, dist, build, generated)
- Tools run: <per dimension — e.g. dead-code → ts-prune, knip; defensive → custom eslint rules>
- Candidates surfaced: N total
- Applied: N · CANDIDATE (left in place): N · Surfaced as out-of-scope finding: N

Commits:
- abc1234  tidy(dead-code): remove N unused exports across src/
- def5678  tidy(dry): consolidate parseBody into shared/http.ts
- 9abcdef  tidy(defensive): drop impossible try/catch in 7 sites
- 0123456  tidy(legacy): remove old_format branch from importers/
- 2468ace  tidy(comments): remove slop, add docstrings, add why-comments

---

## Dimension 1: Dead code

### Removed
- `src/legacy/oldExporter.ts` — no callers, last touched 2023
- `parseUserV1()` in `src/users/parse.ts` — superseded by `parseUser()`, no callers
- 14 unused imports across `src/` (see commit)
- Dead `if old_format:` branches in `importers/csv.py`, `importers/xlsx.py`

### Candidates (left in place, flagged for human review)
- `src/admin/exportSensitive.ts` — exported, zero internal callers, but might be used by ops scripts
- `lib/utils/formatLegacy()` — used only in tests; unclear whether tests are still relevant

### Scanned clean
- 412 .ts/.tsx files scanned for unused exports via ts-prune — none beyond the items above
- All `import` statements resolve; no remaining dead `import` lines after auto-cleanup
- Decorator-based dispatch paths (3) hand-traced — no false positives flagged

## Dimension 2: Duplication / DRY

### Consolidated
- `parseBody()` extracted to `src/shared/http.ts`; was duplicated across 7 route handlers
- `UserSummary` type unified between `src/users/types.ts` and `src/admin/types.ts`

### Considered, not done
- `formatCurrency()` and `formatMoney()` look similar but handle different rounding rules; left alone

### Scanned clean
- jscpd similarity scan across `src/`, threshold 50 tokens — no other near-duplicates above the noise floor
- Type definitions in `src/types/` and `src/admin/types.ts` cross-checked by name — no other parallel pairs

## Dimension 3: Defensive cruft

### Removed
- 4 try/catch blocks around pure functions that cannot throw (impossible-state defense)
- 12 null checks where the type system proves non-null
- `?? "unknown"` fallback in `getUserEmail()` — masks a real data bug; surfaced as a finding

### KEEP-with-comment
- `cleanup_temp_files()` — added "best-effort cleanup" comment to existing bare except

### Scanned clean
- 38 try/catch sites reviewed against `references/keep-or-remove.md` rules — others KEEP unchanged (legitimate I/O or external-API guards)
- All catches that re-throw or surface user errors confirmed as KEEP without comment changes

## Dimension 4: Legacy paths

### Removed
- `if config.api_version == 1` branch — v1 was sunset 2024-Q3
- `legacyAuthHeader` middleware — no callers since cookie migration
- 3 deprecated handlers in `routes/v1/` — replaced by `routes/v2/` with no remaining callers

### Scanned clean
- All feature-flag constants in `src/flags.ts` cross-referenced against call sites — none are wired to dead branches
- `git log --all -S "old_format"` confirms no producer still emits the v1 format

## Dimension 5: Comments and docstrings

### Removed
- 47 obvious-restatement comments
- 12 commented-out code blocks
- 8 stale comments contradicted by current code
- 3 ASCII section dividers

### Added
- Docstrings on 23 public exports across `src/api/`
- Module docstrings on 4 non-trivial modules
- 11 "why" comments at non-obvious decision points (links to issues where applicable)

### Kept untouched
- All TODO/FIXME with author attribution
- All `# noqa` and `// eslint-disable` directives
- Generated-code markers

### Scanned clean
- 187 public exports reviewed for docstring presence — coverage now at 100% on `src/api/` and `src/admin/`
- All existing docstrings cross-checked against current signatures — no stale param lists found
- Why-comment candidates evaluated at 23 non-obvious sites; 11 added, 12 dropped as restating code

---

## Findings (out of scope, surfaced for human review)

These are things tidy noticed but did not act on. They likely deserve a follow-up task.

- `getUserEmail()` falls back to `"unknown@example.com"` when email is missing — looks like a bug the fallback is hiding
- `vulture` is not in `pyproject.toml` dev deps; would help future tidy passes
- `src/admin/exportSensitive.ts` looks externally exposed but there's no integration test confirming it

---

## Disclaimer

This cleanup is AI-assisted using static-analysis tooling. Tools can
miss dynamic dispatch, reflection-based usage, and code reachable only
at runtime. Review the diff for anything safety-critical before merging.
```

## Notes for the writer

- Keep entries terse. One line per item is the target. The reviewer is reading a diff of hundreds of files; the log is the index.
- Don't justify obvious removals. "no callers" is enough. The reviewer can pull `git log` if they need more.
- Findings (out-of-scope) are valuable. They show what tidy noticed but disciplined itself not to fix. Reviewers often act on these.
- "Scanned clean" entries are the rigor signal — they show what was looked at, not just what was changed. List only checks you actually ran with concrete evidence (tool name, file count, exact pattern grepped). Skip the section entirely for a dimension if you have nothing real to say. Padding it kills the signal.
