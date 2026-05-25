# Testing

Run the setup smoke suite before shipping:

```bash
bash tests/setup-smoke.sh
```

The smoke suite verifies:

- `setup.sh` parses and passes shell syntax checks.
- Explicit Codex install links bundled skills under `.codex/skills`.
- Explicit Claude Code install links bundled skills under `.claude/skills`.
- Auto-detection works when the checkout lives under a host skills root.
- Auto-detection fails clearly when the checkout is somewhere else.

These tests intentionally use temporary homes so they do not modify the real
Claude Code or Codex skill directories.
