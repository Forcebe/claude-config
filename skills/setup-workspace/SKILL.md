---
name: setup-workspace
description: Configure this repository's agent workspace — storage mode, issue tracker, and domain doc layout. Use when a repo reports an unconfigured workspace, or when another skill needs it set up before it can continue.
---

# Setup Workspace

Scaffold the per-repository configuration the engineering skills assume:

- **Storage mode**: whether this repo's glossary, ADRs and run graph are committed to it or kept in the sidecar
- **Issue tracker**: where team-facing issues live, and how to talk to it
- **Domain docs**: where `GLOSSARY.md` and ADRs live, and the rules for consuming them

This is prompt-driven, not a script. Explore, present what you found, confirm, then write.

The hard constraint is that a shared repository gains nothing. In sidecar mode, not one byte is written inside the working tree.

## Process

### 1. Explore

Read the repo's actual state; assume nothing.

- `cw --repo`, `cw --key`, and `git remote -v`: which repo is this, and who owns it?
- `cw --mode`: has this repo been set up already? An unconfigured repo reports `unconfigured`.
- Does `GLOSSARY.md`, `docs/adr/`, or `.agents/workspace/` already exist? An `.agents/` holding anything else belongs to the repo's owners; leave it alone.
- `git log --oneline -20 --format='%an'`: is this a solo repo or a shared one?
- Does the branch naming or recent history show Linear ticket ids (`TMRW-123`)?

### 2. Present findings and ask

Summarise what is present and what is missing, then take the sections in order, one answer at a time. Lead each with the recommended answer so it can be accepted in a word.

**Section A: Storage mode.**

> The storage mode decides where this repo's config, glossary and ADRs live. `in-repo` commits them alongside the code. `sidecar` keeps them outside the working tree entirely, so the repo never gains a file. Run state is unaffected: it always lives in the shared git directory.

Recommend by owner:

- Repo under `~/tmrw`, or any remote owned by an organisation rather than the user → **sidecar**. Do not offer `in-repo`; the constraint forbids it.
- A repo the user owns outright → **in-repo**, so the glossary is versioned with the code it describes.
- An open source repo the user contributes to → **sidecar**.

**Section B: Issue tracker.** This is the team-facing record only. The execution layer is separate and is not configured here.

- A `tmrw-health` remote, or Linear ticket ids in the branch history → **Linear**, via the `tmrw-standards` MCP server.
- Anything else → **none**. A repo with no team-facing tracker is normal and needs no configuration.

**Section C: Domain docs.** Default to single-context: one `GLOSSARY.md` and one `adr/` directory under the docs root. Offer multi-context only if exploration found a monorepo (a `pnpm-workspace.yaml`, a `workspaces` field, or a populated `packages/*` with its own `src/`).

### 3. Confirm

Show a draft of all three files and let the user edit before anything is written.

### 4. Write

**The mode is not recorded anywhere. It is implied by where `config.md` lands**, so writing the file to the right directory is the act of choosing the mode:

- **in-repo** → `.agents/workspace/` in the working tree. Create no sidecar.
- **sidecar** → `mkdir -p "$(cw --sidecar)"` and write there.

Write all three files to that one directory:

- `config.md` from [templates/config.md](templates/config.md)
- `tracker.md` from [templates/tracker-linear.md](templates/tracker-linear.md) or [templates/tracker-none.md](templates/tracker-none.md)
- `domain.md` from [templates/domain.md](templates/domain.md)

### 5. Verify

Run `cw --mode` and confirm it reports what was intended. If it reports `sidecar` when `in-repo` was chosen, a stale sidecar config is shadowing the repo one — a sidecar config always wins — so remove it and check again.

In **sidecar** mode, also run `git status --porcelain` and confirm it is empty. If it is not, something was written into the repo: remove it and say so. This check is the whole point of the mode, so never skip it.

In **in-repo** mode, show the user the files to commit, and say that a new worktree will read as `unconfigured` until they are committed, because `.agents/workspace/` is tracked content.

### 6. Done

Say which skills now read these files, and that all three can be edited directly. Re-running this skill is only needed to change the storage mode or the tracker.
