# Agent workspace

Read this first. It says where everything else lives.

- **Storage mode**: `in-repo`
- **Docs root**: resolve with `cw`, never hardcode it. Run state is `cw --state`.
- **Issue tracker**: none. See `tracker.md`.
- **Domain docs**: single-context. See `domain.md`.

## Repo notes

This repo *is* the skill set. Its skills and agents are symlinked into `~/.claude/`, so an edit here is live in every session on this machine immediately, including the one making the edit.

- `scripts/cw` is a hard dependency of most skills. Changing it can break the session changing it, so run every `tests/phase-*.sh` after touching it, not just the phase you are working on.
- `~/.claude/skills` and `~/.claude/agents` are directories of per-entry symlinks deployed by `dev-env`'s `claude` run script. Adding or deleting a skill here needs `./run claude` in dev-env before it takes effect.
- `docs/agent-workspace-design.md` is the design note for the in-progress workspace build. Its phases and acceptance criteria are the plan of record; `tests/phase-N.sh` holds the criteria as runnable checks.
- `skills/synced/` is written by Claude Code, not by hand, and is gitignored.
