# /lets-start

A Claude Code skill that makes it easy to get started. At the start of every session: asks what you're building, sets up a worktree, checks your project config, and routes you to the right [gstack](https://github.com/garrytan/gstack) skill.

## Install

```bash
git clone https://github.com/ashrust/lets-start-skill.git ~/.claude/skills/lets-start
```

Then type `/lets-start` in Claude Code.

## What it does

1. Asks what you're working on
2. Installs [gstack](https://github.com/garrytan/gstack) if missing
3. Adds session conventions to `~/.claude/CLAUDE.md` (asks permission first)
4. Creates a feature branch + worktree at `.worktrees/` inside your repo
5. Scans project config and summarizes your stack
6. Routes to the right gstack skill (`/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, etc.)

## What it modifies

- **`~/.claude/CLAUDE.md`** — adds a `# Session conventions` section (communication style + custom skill trigger). Only on first run, only with your permission.
- **`.gitignore`** — appends `.worktrees/` if not already present.
- **`~/.claude/skills/gstack/`** — installs gstack if missing.

It does not modify any source code.

## Uninstall

```bash
rm -rf ~/.claude/skills/lets-start
```

Then remove the `# Session conventions` section from `~/.claude/CLAUDE.md` if you added it.

## Update

```bash
cd ~/.claude/skills/lets-start && git pull origin main
```

Also auto-updates at the start of each session.

## License

MIT

## Author

[Ash Rust](https://github.com/ashrust)

## Acknowledgments

Built to work with [gstack](https://github.com/garrytan/gstack) by [Garry Tan](https://github.com/garrytan).