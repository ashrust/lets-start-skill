# Defensive code: keep or remove

Defensive cruft is the dimension with the most judgment. Get it wrong and you turn a robust system into one that crashes on real-world input. The default bias is **KEEP**; only remove when you can name a specific reason.

## Try / catch and except blocks

Look at every catch and ask the four questions in order. The first YES wins.

**KEEP if any of:**
- The code inside reads input the type system can't validate — user input, HTTP response bodies, file I/O, env vars, JSON from disk
- The catch handles a genuinely unpredictable failure — network error, DB constraint violation, rate limit, disk full, OOM
- The catch does something meaningful — retries with backoff, surfaces a user-facing error, releases a lock, closes a file, falls back to a documented default behavior
- Removing it would change observable behavior (e.g. an HTTP 500 becomes an unhandled exception that crashes the worker)

**REMOVE if all of:**
- The code inside cannot actually throw given the types and inputs
- The catch silently swallows the error (logs and returns, returns a default that hides the failure, or simply `pass`)
- No retry, no user-facing error, no resource cleanup
- Callers don't depend on the swallowing behavior

### Examples

**KEEP** — handles unknown input, surfaces a real error:
```python
try:
    payload = json.loads(request.body)
except json.JSONDecodeError as e:
    raise BadRequestError(f"Invalid JSON: {e}")
```

**REMOVE** — swallows, returns a fake default, hides bugs:
```python
try:
    user = db.get_user(user_id)
except Exception:
    user = None  # ← any DB error here is now invisible
return user
```

**REMOVE** — defends against an impossible state:
```typescript
function format(d: Date): string {
  try {
    return d.toISOString();   // d is typed Date; cannot throw on a real Date
  } catch {
    return "";
  }
}
```

**KEEP, but ADD a comment** — intentionally swallowing for a documented reason:
```python
try:
    cleanup_temp_files()
except OSError:
    pass  # cleanup is best-effort; we already returned the response
```

## Null / None / undefined checks

**KEEP if:**
- The value comes from outside the type system's reach — JSON parse, DB row, FFI, `any`/`unknown`/`interface{}` boundary
- The type genuinely is nullable and the check matters

**REMOVE if:**
- The type system already proves the value is non-null
- The check is followed by a fallback that would mask a real bug rather than handle a real case

```typescript
// REMOVE — `user` is typed `User`, not `User | null`
function greet(user: User) {
  if (!user) return "";   // ← can't happen
  return `Hello, ${user.name}`;
}
```

```python
# KEEP — d is dict from JSON, "email" is genuinely optional
email = user_dict.get("email")
if email is None:
    raise MissingEmailError()
```

## Fallback values

The pattern: `value ?? default`, `value || default`, `dict.get(key, default)`, `Optional.orElse(x)`, `rescue nil`.

**KEEP if** the default is a documented part of the contract (e.g. config with a sensible default, optional parameter).

**REMOVE if** the default is hiding the absence of a value that should never be absent — that's a silent bug factory.

```python
# REMOVE — if the user has no email, that's a data integrity bug, not a default
email = user.email or "unknown@example.com"
db.send_notification(email)
```

```python
# KEEP — page size genuinely defaults to 20
page_size = query.get("page_size", 20)
```

## Bare excepts and broad catches

`except:` and `except Exception:` (Python), `catch (Throwable)` (Java), `catch (e)` without a type filter (TS) — almost always smell. Replace with the specific exception type, or remove if the catch was just swallowing.

The exception is top-level handlers (request handlers, job runners) that need to log-and-return-500 rather than crash the worker. Those KEEP.

**For public functions specifically:** narrowing the exception type IS a behavior change visible to callers (they were catching `Exception` and getting your function's surprise exceptions; now they get a narrower set, and the rest propagate). Only narrow if the function's docstring or type signature already names the specific exception. Otherwise surface as a finding and leave alone — public API behavior preservation wins.

## Rule of thumb

If removing the defensive code would let a real, possible-in-production failure surface as a stack trace instead of being handled — KEEP. If removing it would let a long-hidden bug finally surface — REMOVE, and trust the test suite (and the gradual rollout) to catch the fallout.
