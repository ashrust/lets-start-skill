# /lets-start

A Claude Code skill that starts every session in the right place. `/lets-start` asks what you're building, sets up an isolated feature branch + worktree, installs [gstack](https://github.com/garrytan/gstack) if missing, adds session conventions to your global `CLAUDE.md`, and routes you to the gstack skill that fits the task. Ships with `/audit-tests`, `/tidy-code`, `/autoclean`, and `/parallelize` for pre-release and parallel-work passes.

## Install

Paste this prompt into Claude Code:

> Install the /lets-start skill: `git clone https://github.com/ashrust/lets-start-skill.git ~/.claude/skills/lets-start-skill && cd ~/.claude/skills/lets-start-skill && bash setup.sh`

Then type `/lets-start` to kick off your first session.

## Upgrading from a single-skill install

Earlier versions of this skill cloned directly into `~/.claude/skills/lets-start`.
If you have that layout (a real git repo at that path, not a symlink), remove it
before installing the new layout — `setup.sh` will refuse to clobber it.

Paste this prompt into Claude Code:

> Check `~/.claude/skills/lets-start` for unpushed commits or uncommitted changes. If it's clean (or it's already a symlink), remove it with `rm -rf ~/.claude/skills/lets-start`. Then install the new layout: `git clone https://github.com/ashrust/lets-start-skill.git ~/.claude/skills/lets-start-skill && cd ~/.claude/skills/lets-start-skill && bash setup.sh`

## Skills included

| Skill | Description |
|-------|-------------|
| `/lets-start` | Session kickoff — workspace setup, project check, gstack routing |
| `/parallelize` | Split a gstack plan into concurrent sessions with isolated worktrees |
| `/audit-tests` | Audit a repo's test suite against a rubric and write a comprehensive one (golden path + error paths, with CI hook) if it's thin |
| `/tidy-code` | Behavior-preserving codebase cleanup in safe, reviewable passes |
| `/autoclean` | Sequential pre-release cleanup: /audit-tests → /tidy-code → /cso, gated between phases |

## What it does

1. Asks what you're working on
2. Installs [gstack](https://github.com/garrytan/gstack) if it's missing
3. Adds session conventions to `~/.claude/CLAUDE.md` (asks permission first)
4. Sets up your workspace: creates a feature branch + worktree at `.worktrees/` inside your repo
5. Routes you to the right gstack skill for the task
6. Reports session status (uncommitted, unpushed) when you wrap up

## What it modifies

- **`~/.claude/CLAUDE.md`** — adds a `# Session conventions` section (communication style + custom skill trigger). Only on first run, only with your permission.
- **`.gitignore`** — appends `.worktrees/` if not already present.
- **`~/.claude/skills/gstack/`** — installs gstack if missing.
- **`~/.claude/skills/lets-start/`**, **`~/.claude/skills/parallelize/`**, **`~/.claude/skills/tidy-code/`**, **`~/.claude/skills/audit-tests/`**, and **`~/.claude/skills/autoclean/`** — directories containing a symlinked `SKILL.md` (and, for multi-file skills, symlinked `references/` and `scripts/`) that points back to this repo.

It does not modify any source code.

## Uninstall

Paste this prompt into Claude Code:

> Uninstall /lets-start: remove `~/.claude/skills/lets-start-skill`, `~/.claude/skills/lets-start`,
> `~/.claude/skills/parallelize`, `~/.claude/skills/tidy-code`, `~/.claude/skills/audit-tests`,
> and `~/.claude/skills/autoclean`.
> Remove the `# Session conventions` section from `~/.claude/CLAUDE.md`. Don't touch anything else.

## Update

Paste this prompt into Claude Code:

> Update /lets-start: `cd ~/.claude/skills/lets-start-skill && git pull origin main && bash setup.sh`

Also auto-updates each time you run `/lets-start`.

## Changelog

See [CHANGELOG.md](CHANGELOG.md). Current version is in [VERSION](VERSION).

## License

MIT

## Author

[Ash Rust](https://github.com/ashrust)

## Acknowledgments

Built to work with [gstack](https://github.com/garrytan/gstack) by [Garry Tan](https://github.com/garrytan).
