# Agent workspace: design note

## Why

The skills in this repo started as a fork of [mattpocock/skills](https://github.com/mattpocock/skills). That repo has moved on, and several of its additions are worth taking: a glossary and domain model woven into the grilling flow, a refined spec → tickets → implement pipeline, a split between skills the model can reach and skills only a human can fire, a long-horizon planning flow (`wayfinder`), and a project tracking layer underneath all of it.

Adopting them directly does not work, for two reasons.

**Shared repos.** Matt stores every artifact as tracked files in the repo being worked on: `GLOSSARY.md`, `docs/adr/`, `docs/agents/*.md`, `.scratch/`, `.out-of-scope/`, and an `## Agent skills` block in `CLAUDE.md`. Most of my work happens in shared TMRW repos where none of that may be committed.

**Audience.** Matt's skills are written for a broad audience. These need to integrate with the tools I actually use: Linear, Slite, the `tmrw-standards` plugin, the `code-review` / `review-loop` skills, `gh-stack`, and the worktree and tmux workflow in `dev-env` (`wt-add`, `wt-rm`, `tmux-init`, `.ready-tmux`).

## Goals

1. Import the parts of Matt's system named above, adapted rather than copied.
2. Write nothing into a shared repo's tracked files, and put no trace of this workflow onto Linear unless I deliberately publish it.
3. Work correctly across several simultaneous worktrees of the same repo, since that is how I work.
4. Reuse `wt-add`, `gh-stack`, `review-loop`, and the `tmrw-standards` plugin rather than reimplementing them.

## Constraints

These are the hard rules. Every design decision below follows from one of them.

- **Nothing personal in a shared repo.** After any flow completes in a `~/tmrw` repo, `git status` is clean.
- **Nothing workflow-shaped on Linear.** Linear is a team-facing reporting surface. No workflow labels, no agent metadata, no synthetic sub-issue per implementation slice.
- **Worktree-safe.** Run state is keyed by repository, not by working directory, so all worktrees of a repo share it and it survives `wt-rm`. Domain docs follow the storage mode instead; see below.
- **No regressions.** `wt-add`, `grill-issue`, `review-loop`, and the rest of today's workflow keep working at every phase.

## Architecture

### Three places, and the resolver that finds them

Agent files live in one of three places, and `cw` is the only thing that needs to know which.

**Domain docs** — `config.md`, `tracker.md`, `domain.md`, `GLOSSARY.md`, `adr/` — live either in the repo at `.agents/` or in a sidecar outside it, depending on the storage mode. `cw` prints the right one.

**Run state** — the run graph, blocking edges, claims — always lives in the shared git directory, at `$(git rev-parse --git-common-dir)/agent-workspace`, which `cw --state` prints. Every worktree of a repo resolves to the same one, it is invisible to `git status`, it cannot be committed, and it needs no key derivation. If it followed the branch instead, two worktrees could not see each other's claims and the coordination below would not work.

**The sidecar**, at `~/.claude-workspace/<owner>--<repo>`, holds domain docs for repos in sidecar mode and nothing otherwise. `cw` derives the key from `git remote get-url origin`, which every worktree shares.

`cw` is a pure resolver: it prints paths and creates nothing.

### Storage mode

| Repository | Storage mode | Domain docs |
|---|---|---|
| `~/tmrw/*` | `sidecar` | Sidecar only. No git, no sync, never leaves the machine. |
| Personal repos | `in-repo` | Committed in the repo, as Matt does it. |
| Open source, or any opt-out | `sidecar` | Sidecar only. |

**The mode is not recorded as a value anywhere. It is implied by which `config.md` exists**, so writing that file to a directory is the act of choosing the mode:

- `.agents/config.md` in the working tree → `in-repo`, and the repo needs no sidecar at all.
- `config.md` in the sidecar → `sidecar`.
- Neither → `unconfigured`, which resolves as the sidecar, so a repo that has never been set up cannot be written into.
- Both → `sidecar` wins. The repo is the surface that must never be written to by accident, so ambiguity resolves away from it.

An earlier draft kept a `storage:` pointer in the sidecar even for in-repo repos. That was worse in two ways: it split a single decision across two locations, and it meant an in-repo repo could not describe itself — cloned to another machine, it would read as unconfigured until a pointer was recreated. Implying the mode from the file's location makes in-repo configuration portable, which is the entire point of committing it.

Under `in-repo`, `.agents/` is tracked content, so it belongs to the branch being worked on: `cw` resolves to the *current worktree's* `.agents/`, and a glossary entry written while building a feature commits alongside that feature. Two consequences worth accepting knowingly. A glossary entry on a branch that never merges is lost with the branch, where a sidecar entry would persist. And `GLOSSARY.md` becomes a merge-conflict hotspot when several branches add terms at once, in the way a changelog does. One ADR per file avoids the second for decisions, and neither applies to `sidecar`, which is what every shared repo uses.

A third consequence is operational rather than a trade-off: a freshly created worktree reads as `unconfigured` until `.agents/` is committed, because an untracked file does not reach a new checkout.

Config is split into three files rather than one, along the boundaries of which skill reads what. `config.md` is small and read first. `tracker.md` holds the tracker operations, is the bulk of the content, and varies most between repositories. `domain.md` holds the documentation layout and the rules for consuming it. Triage label strings live in `tracker.md`, because they are tracker-specific.

### Two tracking layers

Linear is the team's record: issues as the team understands them, with status, assignee, project, and cycle. It gets nothing else.

The **run graph** is the execution surface, under `$(cw --state)/runs/<slug>/` — the shared git directory, in both storage modes, for the reason given above. It holds the full task graph — tickets, blocking edges, triage state, claims, agent briefs, branch bindings — as one markdown file per ticket.

The two are bound by a pointer. Each run records the Linear issue it serves (`linear: TMRW-123`). A single comment back on the Linear issue is available for traceability, as an opt-in, never as a label.

The rule that keeps the boundary from blurring: **the run graph is always complete, and Linear receives only what I would have created by hand anyway.** Publishing to Linear is always a deliberate act.

Three things follow from this, beyond keeping Linear clean:

- Everything is local-first and Linear is a publish target, so `wayfinder`'s local map is not a special case.
- Frontier, blocking, and claim logic stop depending on Linear's relation semantics, so they work unchanged in personal repos and open source projects with no tracker at all.
- Triage states become local labels, which is what makes triage usable on tickets I wrote myself without that process appearing on a team board.

This is a change to current behaviour: today's `to-spec` and `to-tickets` apply a `ready-for-agent` label to Linear, and they will stop.

### Concurrency across worktrees

Because run state lives in the shared git directory, every worktree of a repo already resolves to the same one, which makes it the natural coordination point.

Each ticket file records `status`, `blocked-by`, and `claim` — branch, worktree path, and tmux session. Claims are write-once using an atomic `mkdir` lock, so the first writer wins and a ticket claimed by another worktree is visibly claimed. One file per ticket means concurrent writes to different tickets never collide. That is the whole concurrency mechanism; there is no lock manager.

`cw --status` enumerates live worktrees, their branches, their tmux sessions, and their claimed tickets. It is computed from `git worktree list`, `tmux list-sessions`, and the claim fields rather than stored, so it cannot go stale.

A `SessionStart` hook injects that summary into every new agent session in the repository, so an agent starts knowing what else is in flight and what is already claimed.

### Stacked pull requests

The run graph already holds what stacking needs, given two fields per ticket: `branch` and `stack-parent`.

A linear chain of blocking edges is a stack, and `to-tickets` marks chains as such. `wt-add <branch> <parent-branch>` already accepts a base override, which is the stack parent, so no change is needed there. `gh-stack` handles push, rebase, sync, and PR bodies. When a parent gets review changes and `gh-stack` restacks, the graph's edges identify which worktrees need rebasing.

`implement-spec` therefore has two modes rather than Matt's single integration branch: **stack** (one PR per ticket, incrementally reviewable) and **integration** (everything onto one branch, one PR). It defaults to stack when the graph is a chain and integration when it is a wide fan-out, because a six-wide fan-out cannot be stacked.

### Invocation split

Matt's split between model-invoked and user-invoked skills rests on one invariant: **a user-invoked skill can never be called by another skill.** That invariant, plus the call graph, determines which side each skill lands on.

Skills that must stay model-invoked, because other skills call them via the Skill tool: `grilling`, `domain-modeling`, `tdd`, `prototype`, `research`, `review-loop`, `code-review`, and the `tmrw-standards` plugin's `commit` and `create-pr`.

Skills that become user-invoked, with `disable-model-invocation: true`: `setup-workspace`, `grill-me`, `grill-issue`, `grill-with-docs`, `to-spec`, `to-tickets`, `triage`, `implement`, `implement-spec`, `wayfinder`, `handoff`, `improve-codebase-architecture`, `self-review`, `apply-review`, `retro`, `diagnosing-bugs`, `wizard`.

### A conflict to resolve first

`code-review` and `review-loop` exist twice on a work-layer machine: in `~/.claude/skills` via this repo, and in the `tmrw-standards` plugin, whose copies are forks with cross-references rewritten to `tmrw-standards:`. The plugin is enabled only on the work layer, so the personal copies are the personal-layer fallback and cannot simply be deleted.

Fix: make `dev-env`'s `claude` run script layer-aware, so it skips symlinking the four review skills and the `agents/cr-*` files when `layer=work`.

## Skills

Added: `setup-workspace`, `grilling`, `domain-modeling`, `grill-with-docs`, `research`, `triage`, `implement`, `implement-spec`, `wayfinder`, `retro`, `diagnosing-bugs`, `codebase-design`, `wizard`.

Changed: `to-spec` and `to-tickets` move onto the run graph and stop writing labels to Linear; `grill-me` and `grill-issue` are rewired onto the extracted `grilling` primitive; `handoff` writes into the workspace instead of `mktemp`; the review skills gain the layer-aware deployment fix.

Not adopted: `teach`, and a router skill over the other skills.

This is a large surface. Phases 1 through 5 are the spine and stand on their own; 6 and 7 are additive, and stopping after any phase leaves a working system.

### Refreshing the skills that already exist

Matt's versions of skills this repo already has have moved on. The changes worth taking are selective, and each one is scheduled into the phase that gives it something to attach to rather than done as a separate pass.

**`tdd`** gains two things. The **seams** section — name the seams under test and confirm them with the user before writing any test — matters beyond `tdd` itself, because `to-spec` already sketches test seams and `implement` is meant to call `tdd` at those pre-agreed seams. Without it the pipeline hands off a concept the receiving skill does not speak. The **tautological test** anti-pattern, where the assertion recomputes the expected value the way the code does so it passes by construction, is missing here and belongs in both `SKILL.md` and `tests.md`. The existing workflow section stays: Matt compressed it, which is a style change rather than an improvement.

`tdd`'s `deep-modules.md`, `interface-design.md` and `refactoring.md` **move into** `codebase-design` when that skill lands, rather than being duplicated across the two.

**`improve-codebase-architecture`** gains YAGNI scoping — walk `git log` for the hot spots and look there first, because deepening only pays off where change actually lands — and the **deletion test**, which asks whether deleting a suspected shallow module would concentrate complexity or merely move it. Its existing `REFERENCE.md` stays; Matt dropped the four dependency categories and they are worth keeping. Matt also replaced the conversational candidate list with a generated Tailwind and Mermaid HTML report opened in a browser. That is a taste call rather than a clear improvement, so it is deferred until there is one to look at.

**`prototype`** takes Matt's revised logic branch, which produces a single shareable HTML file rather than a terminal app so that a non-developer can drive it. His capture rule, which commits the prototype to a pushed throwaway branch, conflicts with the constraints above; the branch stays local and the pointer lives in the run graph.

**`handoff`** takes the explicit "suggested skills" section, which names the skills the next agent should call the Skill tool for, and the instruction to redact secrets.

### The PR skill is not adopted here

Matt has a `pr` skill, credited to Dex Horthy's `show-me`, covering how to make a PR body legible: pick the smallest visual that makes the point (pseudocode, call tree, component tree, file tree, Mermaid, or a diff sketch), show before and after evidence, and call whether the change is a one-way or two-way door with its blast radius.

It does not compete with `tmrw-standards`' `create-pr`, which owns the team conventions: title format, `develop` as the base branch, and the What / Why / How / Testing structure. They cover different halves.

Adding it as a personal skill would recreate the duplicate-name and conflicting-guidance problem being fixed for `code-review`, and parts of it push against the PR rules in this repo's `CLAUDE.md`. The technique is worth having, but its home is `tmrw-standards`: the smallest-visual menu belongs in `create-pr`'s What and How sections, and the door and blast-radius call belongs in Testing. That is a pull request to the team plugin, carrying the original attribution, not a skill here.

## Phases and acceptance criteria

Criteria marked **[tmrw]** cannot be validated in this repository and need a `~/tmrw` repo.

### Phase 1 — Foundation

`cw` resolver, `wt-add` integration and `--no-attach`, `setup-workspace`.

- `cw` prints an identical path from the main checkout and from two different worktrees of the same repo.
- `cw` creates the workspace when absent; a second run prints the same path and changes nothing.
- `cw --mode` reports `unconfigured` before setup, and `cw` resolves to the sidecar, so an unconfigured repo is never written into.
- A `config.md` in the repo's `.agents/` makes `cw --mode` report `in-repo`; one in the sidecar makes it report `sidecar`.
- With both present, `cw --mode` reports `sidecar`, because ambiguity must resolve away from the repo.
- Under `in-repo`, each worktree resolves `cw` to its own `.agents/`, and a worktree created before `.agents/` was committed reports `unconfigured`.
- Under `sidecar`, every worktree resolves `cw` to the same path.
- `cw --state` resolves to the same path from the main checkout and every worktree, and files written there do not appear in `git status`.
- `cw` outside a git repository exits non-zero with a clear message.
- `wt-add <branch>` behaves exactly as it does today, and the workspace exists afterwards.
- `wt-add --no-attach <branch>` creates the worktree and tmux session while leaving the current client attached where it was.
- `setup-workspace` on this repo writes `.agents/config.md`, `.agents/tracker.md` and `.agents/domain.md`, and creates no sidecar.
- **[tmrw]** `setup-workspace` on a `~/tmrw` repo defaults to sidecar mode, writes nothing inside the repo, and leaves `git status` clean.

### Phase 2 — Run layer

Task graph format, claims, frontier, `cw --status`, `SessionStart` hook.

- A run with three tickets and a blocking chain exposes exactly one frontier ticket.
- Claiming from worktree A succeeds; claiming the same ticket from worktree B fails.
- Closing a blocker moves the next ticket onto the frontier.
- `cw --status` lists live worktrees, branches, sessions, and claims; killing a tmux session removes it from the output, which proves the output is computed rather than stored.
- Opening a session in worktree B surfaces worktree A's branch and claimed ticket in context.
- `handoff` writes into the workspace rather than `mktemp`, names the skills the next agent should call, and redacts secrets.
- A `prototype` run leaves its branch local and its pointer in the run graph, and pushes nothing.

### Phase 3 — Invocation split

- `grilling` and `domain-modeling` are reachable through the Skill tool from inside another skill.
- A user-invoked skill does not fire from a casual message that would previously have triggered it.
- A skill that calls `code-review` still resolves it.
- **[tmrw]** On the work layer, `code-review` and `review-loop` each resolve to exactly one definition.

### Phase 4 — Spec pipeline

`to-spec`, `to-tickets`, `triage` on the run graph.

- `to-tickets` on a spec produces N ticket files with correct edges and writes nothing to Linear.
- An explicit publish creates a Linear issue carrying no workflow labels.
- `triage` moves a ticket through its states and writes an agent brief without touching Linear.
- `tdd` names the seams under test and asks for confirmation before writing a test, using the same seams `to-spec` sketched.
- `tdd` rejects a tautological test, one whose expected value is recomputed the way the code computes it.
- **[tmrw]** After a full `to-spec` → `to-tickets` → publish cycle, `git status` is clean and the TMRW Linear workspace has gained no workflow labels.

### Phase 5 — Implement

- `implement <ticket>` claims the ticket, creates a worktree through `wt-add`, builds, runs `review-loop`, commits, and releases the claim.
- A chain-shaped graph selects stack mode; a fan-out selects integration mode.
- **[tmrw]** `implement-spec` on a three-ticket chain produces three stacked PRs with correct base branches.

### Phase 6 — Wayfinder

- A map and its tickets are created locally with no tracker present.
- Publishing produces a parent Linear issue and its sub-issues.
- After publishing, the local map is a pointer rather than a duplicate.

### Phase 7 — Health skills

`retro`, `diagnosing-bugs`, `codebase-design`, `wizard` ported and each invoked successfully once.

- `deep-modules.md`, `interface-design.md` and `refactoring.md` live in `codebase-design` and no longer in `tdd`, and `tdd` reaches them by calling the Skill tool.
- `improve-codebase-architecture` scopes its scan from `git log` hot spots before exploring, and applies the deletion test to each suspected shallow module.

### Project-level criteria

These are re-run at the end of every phase, not just at the end.

- **[tmrw]** A full cycle in a shared repo leaves `git status` clean and adds no workflow artifacts to its history.
- **[tmrw]** No `nick/*`, `wayfinder:*`, or `ready-for-agent` label exists in the TMRW Linear workspace except where deliberately published.
- A worktree created, worked, and removed with `wt-rm` leaves the run graph intact, and leaves sidecar-mode domain docs intact. Under `in-repo`, domain docs are tracked files, so they survive by being committed and uncommitted ones die with the worktree like any other uncommitted work.
- Today's `wt-add`, `grill-issue`, and `review-loop` workflows still work.

## Dogfooding

This repo is the test subject, with limits worth stating up front.

It exercises the core well: it is a personal repo, so in-repo mode applies and artifacts are committed; it has no Linear, so the run graph is the only tracker, which is the case phase 2 must handle anyway; and it has a real domain to model, since the vocabulary in this note is all invented.

It cannot exercise the Linear publish bridge, `gh-stack` stacking, `wt-add`'s `npm install` and `env:pull` paths, or genuine parallel worktrees. Those are the **[tmrw]** criteria above.

Bootstrap order, since phase 1 cannot track itself:

1. Build phase 1 by hand, with ordinary commits.
2. Run `setup-workspace` on this repo, as the first real use.
3. Run a grilling and domain-modeling pass over the design conversation to produce `GLOSSARY.md`, pinning the vocabulary before phases 3 through 7 drift from it.
4. Build phase 2, then seed the run graph with tickets for phases 3 through 7. From there the work tracks itself.

One risk to hold onto: dogfooding a half-built system on the repository that *is* the system means a broken skill can block the work of fixing it. So phase 1's tooling stays simple and independently testable, and the run graph never becomes the only record of what is left to build. This note is the backstop.

## Settled decisions

- The Linear MCP server is the one in `tmrw-standards`, not the claude.ai connector. `tracker.md` names it.
- `cw` lives in this repo at `scripts/cw`, symlinked by `dev-env`'s `claude` run script, so the skills stay self-contained.
- The glossary has no promotion path into Slite for now. Revisit once there is a glossary worth promoting.
- `dev-env`'s `claude` run script skips symlinking the review skills and `agents/cr-*` when `layer=work`.
