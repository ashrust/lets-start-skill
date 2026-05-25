# /lets-start

A Claude Code and Codex skill that starts every session in the right place.
`/lets-start` asks what you're building, installs [gstack](https://github.com/garrytan/gstack) if missing,
sets up an isolated feature branch and worktree, checks host-specific session
conventions, and routes you to the gstack or companion skill that fits the task.

The bundle also ships `/audit-tests`, `/tidy-code`, `/autoclean`,
`/parallelize`, and `/ship-then-deploy` for pre-release cleanup, test
coverage, parallel work, and release passes.

## Install

### Claude Code

Paste this prompt into Claude Code:

> Install the /lets-start skill for Claude Code: `git clone https://github.com/ashrust/lets-start-skill.git ~/.claude/skills/lets-start-skill && cd ~/.claude/skills/lets-start-skill && bash setup.sh --host claude`

Then type `/lets-start` to kick off your first session.

### Codex

Paste this prompt into Codex:

> Install the /lets-start skill for Codex: `git clone https://github.com/ashrust/lets-start-skill.git ~/.codex/skills/lets-start-skill && cd ~/.codex/skills/lets-start-skill && bash setup.sh --host codex`

Then start a new Codex session or reload skills if needed, and invoke
`/lets-start`.

`setup.sh --host claude` and `setup.sh --host codex` can also install from any
checkout. Cloning into the host skills root keeps auto-detection and
self-update paths simple.

## Upgrading from a single-skill install

Earlier versions cloned directly into `~/.claude/skills/lets-start`. If you have
that layout (a real git repo at that path, not a symlink), remove it before
installing the new layout. Codex users should do the same check for
`~/.codex/skills/lets-start`. If setup reports that `SKILL.md` is a real file,
move that legacy file aside after checking there is nothing custom you need.

Claude Code prompt:

> Check `~/.claude/skills/lets-start` for unpushed commits or uncommitted changes. If it is clean, or already a symlink, remove it with `rm -rf ~/.claude/skills/lets-start`. Then install the new layout: `git clone https://github.com/ashrust/lets-start-skill.git ~/.claude/skills/lets-start-skill && cd ~/.claude/skills/lets-start-skill && bash setup.sh --host claude`

Codex prompt:

> Check `~/.codex/skills/lets-start` for unpushed commits or uncommitted changes. If it is clean, or already a symlink, remove it with `rm -rf ~/.codex/skills/lets-start`. Then install the new layout: `git clone https://github.com/ashrust/lets-start-skill.git ~/.codex/skills/lets-start-skill && cd ~/.codex/skills/lets-start-skill && bash setup.sh --host codex`

## Skills included

| Skill | Description |
|-------|-------------|
| `/lets-start` | Session kickoff: workspace setup, project check, gstack routing |
| `/parallelize` | Split a gstack plan into concurrent sessions with isolated worktrees |
| `/audit-tests` | Audit a repo's test suite and write a comprehensive one if it is thin |
| `/tidy-code` | Behavior-preserving codebase cleanup in safe, reviewable passes |
| `/autoclean` | Sequential pre-release cleanup: /audit-tests -> /tidy-code -> /cso |
| `/ship-then-deploy` | Run gstack ship, configuring deploy if needed, then land-and-deploy |

## What it does

1. Asks what you're working on
2. Installs [gstack](https://github.com/garrytan/gstack) if it is missing for the current host
3. Adds session conventions to the right host file, with permission
4. Sets up your workspace with a feature branch and worktree at `.worktrees/`
5. Routes you to the right installed gstack or companion skill
6. Reports session status when you wrap up

## What it modifies

- **Claude Code conventions:** project `CLAUDE.md`, or `~/.claude/CLAUDE.md`
  when no project file exists.
- **Codex conventions:** project `AGENTS.md`, or `~/.codex/AGENTS.md` when no
  project file exists.
- **Project `.gitignore`:** appends `.worktrees/` during workspace setup if it
  is not already ignored.
- **Claude Code gstack:** installs or sets up gstack at
  `~/.claude/skills/gstack/`.
- **Codex gstack:** installs the gstack repo at `~/.gstack/repos/gstack/` and
  links Codex-ready skills into `~/.codex/skills/gstack*`.
- **Bundled skills:** installs `lets-start`, `parallelize`, `tidy-code`,
  `audit-tests`, `autoclean`, and `ship-then-deploy` under the selected host's
  skills directory.

It does not modify application source code.

## Uninstall

Claude Code prompt:

> Uninstall /lets-start from Claude Code: remove `~/.claude/skills/lets-start-skill`, `~/.claude/skills/lets-start`, `~/.claude/skills/parallelize`, `~/.claude/skills/tidy-code`, `~/.claude/skills/audit-tests`, `~/.claude/skills/autoclean`, and `~/.claude/skills/ship-then-deploy`. Remove the `# Session conventions` section from `~/.claude/CLAUDE.md` only if it was added by /lets-start. Do not touch anything else.

Codex prompt:

> Uninstall /lets-start from Codex: remove `~/.codex/skills/lets-start-skill`, `~/.codex/skills/lets-start`, `~/.codex/skills/parallelize`, `~/.codex/skills/tidy-code`, `~/.codex/skills/audit-tests`, `~/.codex/skills/autoclean`, and `~/.codex/skills/ship-then-deploy`. Remove the `# Session conventions` section from `~/.codex/AGENTS.md` only if it was added by /lets-start. Do not touch anything else.

## Update

Claude Code prompt:

> Update /lets-start for Claude Code: `cd ~/.claude/skills/lets-start-skill && git pull origin main && bash setup.sh --host claude`

Codex prompt:

> Update /lets-start for Codex: `cd ~/.codex/skills/lets-start-skill && git pull origin main && bash setup.sh --host codex`

## Changelog

See [CHANGELOG.md](CHANGELOG.md). Current version is in [VERSION](VERSION).

## License

MIT

## Author

[Ash Rust](https://github.com/ashrust)

## Acknowledgments

Built to work with [gstack](https://github.com/garrytan/gstack) by [Garry Tan](https://github.com/garrytan).
