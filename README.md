# /lets-start

A Claude Code skill that makes it easy to get started. At the start of every session: asks what you're building, sets up a worktree, checks your project config, and routes you to the right [gstack](https://github.com/garrytan/gstack) skill.

## Install

```bash
git clone https://github.com/ashrust/lets-start-skill.git ~/.claude/skills/lets-start-skill
cd ~/.claude/skills/lets-start-skill && bash setup.sh
```

Or paste this prompt into Claude Code:

> Install the /lets-start skill: `git clone https://github.com/ashrust/lets-start-skill.git ~/.claude/skills/lets-start-skill && cd ~/.claude/skills/lets-start-skill && bash setup.sh`

Then type `/lets-start` to kick off your first session.

## Upgrading from a single-skill install

Earlier versions of this skill cloned directly into `~/.claude/skills/lets-start`.
If you have that layout (a real git repo at that path, not a symlink), remove it
before running the new install — `setup.sh` will refuse to clobber it:

```bash
rm -rf ~/.claude/skills/lets-start
git clone https://github.com/ashrust/lets-start-skill.git ~/.claude/skills/lets-start-skill
cd ~/.claude/skills/lets-start-skill && bash setup.sh
```

## Skills included

| Skill | Description |
|-------|-------------|
| `/lets-start` | Session kickoff — workspace setup, project check, gstack routing |
| `/parallelize` | Split a gstack plan into concurrent sessions with isolated worktrees |

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
- **`~/.claude/skills/lets-start/`** and **`~/.claude/skills/parallelize/`** — symlinked directories pointing back to this repo.

It does not modify any source code.

## Uninstall

Paste this prompt into Claude Code:

> Uninstall /lets-start: remove `~/.claude/skills/lets-start-skill`, `~/.claude/skills/lets-start`,
> and `~/.claude/skills/parallelize`. Remove the `# Session conventions` section from
> `~/.claude/CLAUDE.md`. Don't touch anything else.

Or do it manually:

```bash
rm -rf ~/.claude/skills/lets-start-skill ~/.claude/skills/lets-start ~/.claude/skills/parallelize
```

Then edit `~/.claude/CLAUDE.md` and remove the `# Session conventions` section.

## Update

```bash
cd ~/.claude/skills/lets-start-skill && git pull origin main && bash setup.sh
```

Also auto-updates at the start of each session.

## License

MIT

## Author

[Ash Rust](https://github.com/ashrust)

## Acknowledgments

Built to work with [gstack](https://github.com/garrytan/gstack) by [Garry Tan](https://github.com/garrytan).
