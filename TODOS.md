# TODOs

Follow-up work surfaced during /plan-eng-review of /autoclean. Not blocking the
initial PR — capture so they don't get lost.

## End-to-end smoke test for /autoclean

**What:** A small test that invokes /autoclean against a fixture repo and
asserts the three child skills ran and created their expected branches.

**Why:** Catches regressions when /audit-tests or /tidy-code change their
behavior contract. Currently zero tests in this repo.

**Context:** Sibling skills /lets-start and /parallelize also have no tests.
A test framework added here would benefit all four skills, not just /autoclean.

**Depends on:** /audit-tests, /tidy-code, /autoclean all merged to main.

## /autoclean --report-only mode

**What:** A flag (or sibling skill /autoclean-report) that runs each child in
its non-mutating mode — audit-only for /audit-tests, plan-only for /tidy-code,
report-only for /cso.

**Why:** Pre-PR dry run where you want to see what would change without
committing anything. Useful for CI integration too.

**Context:** /cso is already read-only. /audit-tests already gates scaffolding
behind a consent prompt. /tidy-code is the one that needs new behavior — it
currently commits per dimension and has no plan-only mode.

**Depends on:** /tidy-code adding a plan-only mode upstream first.
