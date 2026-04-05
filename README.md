# /lets-start

A Claude Code skill that makes it easy to get started. At the start of every session: asks what you're building, sets up a worktree, checks your project config, and routes you to the right [gstack](https://github.com/garrytan/gstack) skill.

## Install

```bash
git clone https://github.com/ashrust/lets-start-skill.git ~/.claude/skills/lets-start
```

Then type `/lets-start` in Claude Code.

## What it does

1. Asks what you're working on
2. Routes you to the correct [gstack](https://github.com/garrytan/gstack) skill to get started
3. Ensures you know what step is recommended next by adding session conventions to `~/.claude/CLAUDE.md` (asks permission first)
4. Sets up your workspace: creates a feature branch + worktree at `.worktrees/` inside your repo
5. Summarizes your current stack and makes suggestions, if needed

## What it modifies

- **`~/.claude/CLAUDE.md`** — adds a `# Session conventions` section (communication style + custom skill trigger). Only on first run, only with your permission.
- **`.gitignore`** — appends `.worktrees/` if not already present.
- **`~/.claude/skills/gstack/`** — installs gstack if missing.

It does not modify any source code.

## Install

Run in your terminal:
```bash
git clone https://github.com/ashrust/lets-start-skill.git ~/.claude/skills/lets-start
```

Or paste this prompt into Claude Code:
> Install the /lets-start skill: `git clone https://github.com/ashrust/lets-start-skill.git ~/.claude/skills/lets-start`

Then type `/lets-start` to kick off your first session.

## Uninstall

Paste this prompt into Claude Code:
> Uninstall /lets-start: remove `~/.claude/skills/lets-start`, remove the
> `# Session conventions` section from `~/.claude/CLAUDE.md`, and remove any
> `/lets-start` references from `~/.claude/CLAUDE.md`. Don't touch anything else.

Or do it manually:
```bash
rm -rf ~/.claude/skills/lets-start
```
Then edit `~/.claude/CLAUDE.md` and remove the `# Session conventions` section.

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