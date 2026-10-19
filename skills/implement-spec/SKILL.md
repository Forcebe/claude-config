---
name: implement-spec
description: Build a whole run: work its frontier until the graph is empty, as a stack of pull requests or on one integration branch.
disable-model-invocation: true
---

# Implement Spec

A whole run, orchestrated. For a single slice, use `/implement`.

The slices are **not a list of steps**. They are a graph with blocking edges, so there is always a **frontier** of slices that can be started, and more than one may be takeable at once.

## 1. Read the run

Read `spec.md` and the run graph. Communicate with subagents through **context pointers** — the spec, a slice, a commit — not by restating what those already say.

## 2. Pick the mode

```sh
cw shape <run>
```

- **`chain`** → **stack mode**. Each slice's branch is based on its `stack-parent`'s branch, and each becomes its own pull request. Reviewable one slice at a time, which is what makes a long sequence bearable for whoever reviews it.
- **`empty`** → there are no slices. Stop and say so; `/to-slices` has not run, or the run is already finished.
- **`fan-out`** → **integration mode**. One integration branch, every slice merged into it, one pull request at the end. A six-wide fan-out cannot be stacked; forcing it produces a tangle of rebases.

Say which mode you picked and why. The user can override — a small fan-out is sometimes worth stacking anyway — but do not override silently.

## 3. Work the frontier

Loop until `cw frontier <run>` is empty:

1. Take the frontier. In stack mode that is always one slice; in integration mode it may be several.
2. For each, spawn an **implementer subagent** that calls the Skill tool with "implement". Each gets its own worktree via `wt-add`, and in stack mode passes the stack-parent's branch as the base ref.
3. In integration mode, run them in the background for concurrency, and merge each completed slice into the integration branch with a **merger subagent** before the next frontier is computed.
4. Recompute the frontier. Closing a slice moves whatever it blocked onto it.

Each implementer claims its own slice, so two of them cannot collide even if the orchestration is wrong. Let the claim be the guard rather than tracking assignment yourself.

### Subagents need `cw` permitted

An implementer runs AFK, and `cw` resolves paths only known at runtime. Without `cw` on the permission allowlist a subagent will stall on a prompt nobody can answer, having done nothing. Confirm it is allowed **before** spawning the first one; this has already bitten once.

## 4. Review the whole thing

Once the graph is empty, call the Skill tool with "code-review" over the stack or the integration branch. Fix what it raises in a single subagent rather than one per finding.

## 5. Close out

- **Stack mode**: call the Skill tool with "gh-stack" to push the branches and open the pull requests, bases already correct from the stack parents. When a parent changes in review, `gh-stack` restacks the children, and the run graph says which worktrees need rebasing.
- **Integration mode**: open one pull request from the integration branch.

Then clean up every implementer worktree with `wt-rm`, and report what landed, the branches, and anything left open.

Publishing to Linear is a separate, deliberate act. The run graph records `linear:` if an issue already covers this work; nothing about the slices, claims or edges goes there.
