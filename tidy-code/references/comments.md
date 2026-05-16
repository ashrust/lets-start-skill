# Comment audit rules

This is the dimension users notice most. Get it right.

The default position: **the code shows the *what*; comments explain the *why*.** If a comment is restating what the code already says in plain English, it's noise.

## Two sub-passes, two commits

### Pass 1: REMOVE slop

Delete these. Each is its own micro-decision but the patterns are obvious once you see them.

**Restatement comments** — the comment says what the code already says.
```python
# REMOVE: # increment counter
counter += 1

# REMOVE: # return the user
return user
```

**AI narration / step-by-step verbosity** — comments that read like an AI explaining itself to a beginner.
```typescript
// REMOVE: // First, we check if the user is authenticated
// REMOVE: // Then, we proceed with the request
// REMOVE: // Finally, we return the response
```

**Stale comments** — comment contradicts the code. The code is the source of truth; the comment lied.
```python
# REMOVE: # Returns the user's email   ← but the function returns the full User object
def get_user(id): ...
```

**Commented-out code blocks** — should have been caught in dimension 1, but sweep again.
```javascript
// REMOVE:
// const oldHandler = (req) => { ... 40 lines ... }
```

**Section-divider art** — banner comments that exist purely to break up code visually.
```python
# REMOVE:
# ============================================================
# HELPER FUNCTIONS
# ============================================================
```

**Author / changelog noise** — `// Modified by Bob 2019-04-12 to handle edge case` belongs in git history, not the file. Exception: legal headers (license, copyright) which the project's `.editorconfig` or LICENSE policy may require.

### Pass 2: ADD docstrings to public APIs AND why-comments at non-obvious points

This pass does two related things in one commit. Docstrings first (the bigger job), then a scan for why-comments while the code is fresh in mind.

**Docstrings:** for every **exported / public** function, class, method, and module that lacks one, add a docstring matching the language convention.

A docstring covers:
- One-line summary (imperative mood: "Compute the…", "Return the…")
- Parameters with types and meaning (skip if signature already types them and names are obvious)
- Return value
- Errors raised / exceptions thrown
- Side effects, if any

**Python** — Google-style or numpy-style; pick whichever the project already uses. If none, default to Google-style.
```python
def fetch_holdings(account_id: str, *, refresh: bool = False) -> list[Holding]:
    """Return current holdings for an account.

    Args:
        account_id: Monarch account identifier.
        refresh: If True, force a sync before reading.

    Returns:
        Holdings ordered by market value, descending.

    Raises:
        AccountNotFoundError: If account_id has no matching record.
    """
```

**TypeScript / JavaScript** — TSDoc / JSDoc.
```typescript
/**
 * Compute net delta exposure for a covered-call position.
 *
 * @param position - The position record from Monarch.
 * @param spot - Current spot price of the underlying.
 * @returns Net delta in shares.
 * @throws {InvalidPositionError} If position has no contracts.
 */
```

**Go** — godoc convention: comment starts with the name of the symbol.
```go
// FetchHoldings returns current holdings for an account, sorted by market value descending.
// Returns ErrAccountNotFound if the account does not exist.
func FetchHoldings(accountID string) ([]Holding, error) { ... }
```

**Rust** — rustdoc with `///`.
```rust
/// Return current holdings for an account, sorted by market value descending.
///
/// # Errors
/// Returns `Error::AccountNotFound` if the account does not exist.
pub fn fetch_holdings(account_id: &str) -> Result<Vec<Holding>, Error> { ... }
```

**Skip docstrings for:**
- Private / unexported functions whose name and signature are self-explanatory
- One-line getters with no logic
- Test functions (the test name is the spec)
- Auto-generated code

### Pass 3: ADD "why" comments (part of Pass 2's commit)

After docstrings are in, scan the code with fresh eyes. Anywhere the code looks weird, has a non-obvious constraint, or makes a trade-off the next reader will question, add a one-line comment explaining the why.

**Add when:**
- A workaround for a known bug (link the issue if one exists)
- A performance trade-off (`# O(n²) is fine here, n < 50`)
- A non-obvious ordering constraint (`# must run before X — X mutates the cache`)
- A deliberately weak check that looks accidentally weak
- A magic number whose source isn't obvious (`# IRS Form 1099-DIV box 1a`)
- An empty `except` or `catch` that's intentional (explain why swallowing is correct)

**Don't add when:**
- The code is self-explanatory
- The reason is obvious from the function name or the surrounding code
- You'd be inventing a justification because there's no real reason — that's a smell that the code itself should change

**If, after scanning, there are no genuine candidates:** that's a fine outcome. Note it in `TIDY_LOG.md` (e.g., "Why-comments: no candidates after docstring pass — code is self-evident") and move on. Don't invent why-comments to fill a quota.

## What to KEEP unchanged

- TODO/FIXME with a name and date or issue link
- Existing rationale comments that still match the code
- License headers and SPDX identifiers
- `# noqa`, `# type: ignore`, `// eslint-disable-next-line` and similar lint directives
- Generated-code markers (`@generated`, `// Code generated — DO NOT EDIT.`)
- Pragma / compiler directives

## When in doubt

Leave the comment alone. A questionable comment is noise; deleting a comment that turns out to have been load-bearing rationale is a regression. If you can't tell, mark it `// REVIEW:` and move on.
