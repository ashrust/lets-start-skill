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

## Dimension 2: Duplication / DRY

### Consolidated
- `parseBody()` extracted to `src/shared/http.ts`; was duplicated across 7 route handlers
- `UserSummary` type unified between `src/users/types.ts` and `src/admin/types.ts`

### Considered, not done
- `formatCurrency()` and `formatMoney()` look similar but handle different rounding rules; left alone

## Dimension 3: Defensive cruft

### Removed
- 4 try/catch blocks around pure functions that cannot throw (impossible-state defense)
- 12 null checks where the type system proves non-null
- `?? "unknown"` fallback in `getUserEmail()` — masks a real data bug; surfaced as a finding

### KEEP-with-comment
- `cleanup_temp_files()` — added "best-effort cleanup" comment to existing bare except

## Dimension 4: Legacy paths

### Removed
- `if config.api_version == 1` branch — v1 was sunset 2024-Q3
- `legacyAuthHeader` middleware — no callers since cookie migration
- 3 deprecated handlers in `routes/v1/` — replaced by `routes/v2/` with no remaining callers

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

---

## Findings (out of scope, surfaced for human review)

These are things tidy noticed but did not act on. They likely deserve a follow-up task.

- `getUserEmail()` falls back to `"unknown@example.com"` when email is missing — looks like a bug the fallback is hiding
- `vulture` is not in `pyproject.toml` dev deps; would help future tidy passes
- `src/admin/exportSensitive.ts` looks externally exposed but there's no integration test confirming it
```

## Notes for the writer

- Keep entries terse. One line per item is the target. The reviewer is reading a diff of hundreds of files; the log is the index.
- Don't justify obvious removals. "no callers" is enough. The reviewer can pull `git log` if they need more.
- Findings (out-of-scope) are valuable. They show what tidy noticed but disciplined itself not to fix. Reviewers often act on these.
