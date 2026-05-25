# Changelog

All notable changes to this repo. Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [SemVer](https://semver.org/).

## [0.2.0] - 2026-05-25

### Added

- **Codex-first install path** - `setup.sh` now supports `--host codex` and installs the bundled skills under `~/.codex/skills/<name>/` when the repo is cloned to `~/.codex/skills/lets-start-skill`.
- **Cross-host `/lets-start` workflow** - the kickoff skill now branches between Claude Code and Codex paths, conventions files, question styles, routing mechanics, and gstack install commands.
- **Codex gstack bootstrap** - `/lets-start` now installs gstack for Codex via `~/.gstack/repos/gstack` plus `./setup --host codex --prefix`, so routed Codex skills are available as `gstack-*`.
- **`/setup-then-deploy`** — new release wrapper that checks whether `CLAUDE.md` already has gstack deploy configuration, runs `/gstack-setup-deploy` when that config is missing, then hands off to `/gstack-ship` and `/gstack-land-and-deploy` in sequence. The wrapper does not reimplement deploy logic; it reads the installed gstack child skills and stops cleanly if any child skill needs user input or hits a safety gate.
- **Setup smoke tests** - `tests/setup-smoke.sh` verifies Claude Code installs, Codex installs, host auto-detection, clear failure when auto-detection cannot infer a host, and `/setup-then-deploy` installation for both hosts.

### Changed

- **Installer host detection** - `setup.sh` infers Claude Code vs. Codex from the repo location, supports explicit `--host` installs from any checkout, and rejects unknown host values.
- **README install docs** - split install, update, uninstall, and migration instructions into Claude Code and Codex sections, with host-specific files and gstack paths.
- **README skill inventory and uninstall instructions** — added `/setup-then-deploy` everywhere the bundled skills are listed.
- **`/lets-start` routing hints** — combined release requests such as "ship and deploy" now route to `/setup-then-deploy` first.

## [0.1.3] - 2026-05-22

### Changed

- **`/audit-tests` row in the skills table** — trimmed from 124 chars to 66 to match the length of sibling rows. Now reads "Audit a repo's test suite — write a comprehensive one if it's thin." The "write" verb (vs. "scaffold") still signals the skill actually generates tests, which was the point of the v0.1.1 change.

## [0.1.2] - 2026-05-22

### Changed

- **README "Upgrading from a single-skill install" and "Update" sections** — converted the remaining bash blocks to Claude Code prompts so install / upgrade / update / uninstall are now consistent across the README. Earlier passes only converted install and uninstall.
- **README "Changelog" section** — dropped the inline `Current version: 0.1.0` reference (which was already stale at v0.1.1) and points to the `VERSION` file instead. One less thing to forget on each bump.

## [0.1.1] - 2026-05-22

### Added

- **`/lets-start` writes a fourth global convention** — first-run setup now adds a `## Verify before assert` subsection to `~/.claude/CLAUDE.md` alongside Communication, Custom skills, and Skill invocation. The rule: any CLI command, flag, file path, API endpoint, or config key written in a response must be verified in the current session (via `--help`, source/doc on the current system, or canonical URL) — install banners and prior-session memory are not sufficient. Sessions that don't verify must label commands as `(unverified)`. SKILL.md Step 3 also now adds missing subsections in place instead of rewriting the section.

### Changed

- **README description, install, and uninstall** — rewrote the lead-in to be specific about what the skill does and the cleanup skills it ships with. Install and Uninstall sections now show only the Claude Code prompt (the bash equivalent was redundant — the prompt asks Claude to run it).
- **`/audit-tests` row in skills table** — now reflects what the skill actually does: writes a comprehensive suite (golden path + error paths, with CI hook), not just framework scaffolding. The "scaffold" framing understated the iteration loop in Step 4.
- **"What it does" section in README** — reordered to match the actual SKILL.md step order (gstack install → conventions → workspace → routing → wrapup) and dropped the "summarizes your current stack" claim, which the skill doesn't do.

### Removed

- **Legacy `/tidy` migration note** — the standalone `/tidy` install was never released, so the README no longer carries instructions for migrating away from it.

## [0.1.0] - 2026-05-20

Initial versioned release. The repo went from a single-skill `/lets-start` install to a multi-skill bundle with four sibling skills sharing one `setup.sh`.

### Added

- **Multi-skill repo layout** — restructured from a single skill into a top-level repo that ships several skills side by side, with one shared `setup.sh` that symlinks each skill into `~/.claude/skills/<name>/`. ([27cc98f](https://github.com/ashrust/lets-start-skill/commit/27cc98f), [c587636](https://github.com/ashrust/lets-start-skill/commit/c587636))
- **`/parallelize`** — splits a gstack plan into concurrent tasks across isolated worktrees, framing the original session as the manager session and the children as numbered lanes. ([27cc98f](https://github.com/ashrust/lets-start-skill/commit/27cc98f), [354a4f5](https://github.com/ashrust/lets-start-skill/commit/354a4f5))
- **`/audit-tests`** — audits a repo's test suite against a rubric, presents a scored verdict, and (with consent) scaffolds a comprehensive suite plus CI hook. ([b17c692](https://github.com/ashrust/lets-start-skill/commit/b17c692), [31d5435](https://github.com/ashrust/lets-start-skill/commit/31d5435))
- **`/tidy-code`** — behavior-preserving cleanup in safe, reviewable passes (dead code, duplication, defensive cruft, comments/docstrings), with a semgrep + DRY handoff documented in `references/dimensions.md`. ([51e6e17](https://github.com/ashrust/lets-start-skill/commit/51e6e17), [cfb67f8](https://github.com/ashrust/lets-start-skill/pull/8))
- **`/autoclean`** — sequential pre-release pipeline that runs `/audit-tests` → `/tidy-code` → `/cso` with a gate between phases so you can review, skip, or stop. ([fce1a0c](https://github.com/ashrust/lets-start-skill/pull/5))
- **`VERSION` + `CHANGELOG.md`** — this release introduces versioning.

### Changed

- **`setup.sh` supports multi-file skills** — also symlinks sibling files/dirs (`references/`, `scripts/`, etc.) so multi-file skills work after install, with a safety rule that refuses to clobber real (non-symlink) files. ([09ab45c](https://github.com/ashrust/lets-start-skill/commit/09ab45c))
- **`/audit-tests` commits per phase** — matches `/autoclean`'s contract so the pipeline can attribute and roll back each phase cleanly. ([efe8b31](https://github.com/ashrust/lets-start-skill/pull/7))
- **Install / uninstall hardening** — applied pre-landing review fixes across skills and install paths. ([d26914b](https://github.com/ashrust/lets-start-skill/commit/d26914b))
