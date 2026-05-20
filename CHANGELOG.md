# Changelog

All notable changes to this repo. Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [SemVer](https://semver.org/).

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
