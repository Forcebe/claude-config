# Agent workspace

Read this first. It says where everything else lives.

This file's own location is what puts the repo in `<in-repo|sidecar>` mode; nothing records the mode as a value. Resolve paths with `cw` and `cw --state`, never hardcode them.

- **Issue tracker**: `<Linear|none>`. See `tracker.md`.
- **Domain docs**: `<single-context|multi-context>`. See `domain.md`.

<!-- In sidecar mode, keep this line and delete it in in-repo mode: -->

Nothing in this repository's working tree may record this workflow. Config, glossary and ADRs live beside this file; run state lives in the shared git directory, which `cw --state` prints.

## Repo notes

<Standing facts an agent should know before working here: the default branch, how tests are run, any area that is off-limits. Keep it short; this is read on every session, and anything already in CLAUDE.md belongs there instead.>
