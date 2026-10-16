# The run graph

The execution surface: the task graph a piece of work is actually built through. It lives under `$(cw --state)/runs/`, which resolves inside the repo's shared git directory, so every worktree sees the same graph, nothing is ever committed, and nothing appears in `git status`.

Linear is a separate layer and holds none of this. See `tracker.md` in the workspace.

## Layout

```
$(cw --state)/runs/<run-slug>/
├── run.md
├── tickets/
│   ├── 01-add-resolver.md
│   └── 02-wire-frontier.md
└── claims/
    └── 01-add-resolver/        ← the lock; its existence is the claim
        └── holder
```

A ticket's **id** is its filename without `.md`. Ids sort, and the numeric prefix puts blockers before the work they gate, so reading `tickets/` in order reads the intended sequence.

## run.md

```markdown
# <run title>

linear: TMRW-123
spec: <path or URL, if there is one>

<what this run delivers, in a line or two>
```

`linear:` is a pointer and nothing more. Nothing about the run graph is written back to Linear unless publishing is asked for.

## A ticket

```markdown
---
status: open
blocked-by: 01-add-resolver 02-wire-frontier
branch: nick/TMRW-123-add-resolver
stack-parent: 01-add-resolver
---

# Add the resolver

What this slice makes work, end to end, from the user's point of view.

## Acceptance criteria

- [ ] ...
```

The header is flat `key: value` lines, never nested, so it stays greppable and needs no YAML parser. **Only the block between the two `---` fences is read**, so prose in the body that happens to start with `status:` or `blocked-by:` is just prose.

A ticket id is its filename stem and must match `[A-Za-z0-9._-]+`. Operations that delete reject anything else rather than letting a path escape the run directory.

- **status**: `open` or `done`.
- **blocked-by**: space-separated ticket ids, or empty. A ticket is unblocked when every blocker is `done`.
- **branch**: the branch the work lands on, once one exists.
- **stack-parent**: the ticket whose branch this one stacks on, when the graph is a chain. `wt-add <branch> <parent-branch>` takes it as the base ref.

## Claims

A claim is a **directory**, not a field, because `mkdir` is atomic and a field in a file is not. Two worktrees racing for the same ticket both call `mkdir`; exactly one succeeds. The winner then writes `holder` with its branch, worktree, tmux session and timestamp.

A field would need read-modify-write, which has no atomic form in a shell script, and both racers would believe they had won.

Claims are deliberately **not** recorded in the ticket file: the ticket is the work, the claim is transient state about who is doing it, and keeping them apart means a claim can never conflict with an edit to the ticket's body.

## Operations

```sh
cw frontier <run>              # open, unblocked, unclaimed — what can be started
cw claim <run> <ticket>        # atomic; non-zero exit if already held
cw release <run> <ticket>
cw close <run> <ticket>        # mark done, and release
cw status                      # every worktree, its branch, session and claims
```

`cw status` is computed from `git worktree list`, `tmux has-session` and the claim directories every time it runs. Nothing caches it, so a killed session or a removed worktree disappears on its own and there is no stale state to clean up.

It lists only **live** worktrees. Git keeps registrations for worktrees whose directory or `.git` file has gone — a cleaned-up scratchpad leaves one behind — and marks them `prunable`. Those are dead, so they are filtered out rather than reported with an unreadable branch. `git worktree prune` clears the registrations themselves, and only ever touches dead ones.

## Working a run

1. `cw frontier <run>` for what is takeable.
2. `cw claim <run> <ticket>` **before** any work. A non-zero exit means another session got there first: take the next one.
3. Build it. `wt-add <branch>` for a worktree, passing `stack-parent`'s branch as the base ref when there is one.
4. `cw close <run> <ticket>`, which releases the claim and moves whatever it was blocking onto the frontier.

A session that dies mid-ticket leaves its claim behind. That is deliberate: a stale claim is visible in `cw status` next to a worktree with no live session, which is a human's cue to `cw release` it rather than something to time out automatically.
