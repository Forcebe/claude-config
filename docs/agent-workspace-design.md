# Agent workspace: design note

## Why

The skills in this repo started as a fork of [mattpocock/skills](https://github.com/mattpocock/skills). That repo has moved on, and several of its additions are worth taking: a glossary and domain model woven into the grilling flow, a refined spec → slices → implement pipeline, a split between skills the model can reach and skills only a human can fire, a long-horizon planning flow (`wayfinder`), and a project tracking layer underneath all of it.

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

**Domain docs** — `config.md`, `tracker.md`, `domain.md`, `GLOSSARY.md`, `adr/` — live either in the repo at `.agents/workspace/` or in a sidecar outside it, depending on the storage mode. `cw` prints the right one.

**Run state** — the run graph, blocking edges, claims — always lives in the shared git directory, at `$(git rev-parse --git-common-dir)/agent-workspace`, which `cw --state` prints. Every worktree of a repo resolves to the same one, it is invisible to `git status`, it cannot be committed, and it needs no key derivation. If it followed the branch instead, two worktrees could not see each other's claims and the coordination below would not work.

**The sidecar**, at `~/.claude-workspace/<owner>--<repo>`, holds domain docs for repos in sidecar mode and nothing otherwise. `cw` derives the key from `git remote get-url origin`, which every worktree shares.

`cw`'s **flags resolve and never write**; its **verbs** (`status`, `frontier`, `claim`, `release`, `close`) act on the run graph. The split is deliberate: path resolution is used everywhere and must stay side-effect free.

### Storage mode

| Repository | Storage mode | Domain docs |
|---|---|---|
| `~/tmrw/*` | `sidecar` | Sidecar only. No git, no sync, never leaves the machine. |
| Personal repos | `in-repo` | Committed in the repo, as Matt does it. |
| Open source, or any opt-out | `sidecar` | Sidecar only. |

**The mode is not recorded as a value anywhere. It is implied by which `config.md` exists**, so writing that file to a directory is the act of choosing the mode:

- `.agents/workspace/config.md` in the working tree → `in-repo`, and the repo needs no sidecar at all.
- `config.md` in the sidecar → `sidecar`.
- Neither → `unconfigured`, which resolves as the sidecar, so a repo that has never been set up cannot be written into.
- Both → `sidecar` wins. The repo is the surface that must never be written to by accident, so ambiguity resolves away from it.

The nesting under `.agents/workspace/` is why the signal is safe. `tmrw-core-api` already tracks an `.agents/` directory holding team-committed skills, so `.agents/` is not ours to read: a team that later adopted `.agents/config.md` for its own purposes would, with a flatter layout, have silently put every un-set-up shared repo into `in-repo` mode and invited writes into its working tree. Only a config at our own nested path counts, and nothing the team puts in `.agents/` can redirect us.

An earlier draft kept a `storage:` pointer in the sidecar even for in-repo repos. That was worse in two ways: it split a single decision across two locations, and it meant an in-repo repo could not describe itself — cloned to another machine, it would read as unconfigured until a pointer was recreated. Implying the mode from the file's location makes in-repo configuration portable, which is the entire point of committing it.

Under `in-repo`, `.agents/workspace/` is tracked content, so it belongs to the branch being worked on: `cw` resolves to the *current worktree's* `.agents/workspace/`, and a glossary entry written while building a feature commits alongside that feature. Two consequences worth accepting knowingly. A glossary entry on a branch that never merges is lost with the branch, where a sidecar entry would persist. And `GLOSSARY.md` becomes a merge-conflict hotspot when several branches add terms at once, in the way a changelog does. One ADR per file avoids the second for decisions, and neither applies to `sidecar`, which is what every shared repo uses.

A third consequence is operational rather than a trade-off: a freshly created worktree reads as `unconfigured` until `.agents/workspace/` is committed, because an untracked file does not reach a new checkout.

Config is split into three files rather than one, along the boundaries of which skill reads what. `config.md` is small and read first. `tracker.md` holds the tracker operations, is the bulk of the content, and varies most between repositories. `domain.md` holds the documentation layout and the rules for consuming it. Triage label strings live in `tracker.md`, because they are tracker-specific.

### Which skills touch the domain docs

Only the ones that actively change the model, and they all reach it the same way: by calling the Skill tool with `domain-modeling`, which writes `GLOSSARY.md` and ADRs under `cw`.

- **`grill-with-docs`**, **`grill-issue`**, **`triage`** and **`wayfinder`** all call it, so any of them may add a term or an ADR as decisions land.
- **`grill-me`** does not, deliberately: it is the stateless one, for work with no repository under it.
- Everything else only **reads** the glossary for vocabulary, which is a one-line habit rather than a skill.

So `/grill-issue` leaves the same paper trail as `/grill-with-docs`. The difference between them is where the work comes from, not what they write.

### Two ways in

Work arrives two ways, and the pipeline needs an entrance for each.

**New ideas** go `/grill-with-docs` → `/to-spec` → `/to-slices`: the spec is written from the conversation, and the slices are sliced from the spec.

**Work that already exists** goes through `/grill-issue`. Most TMRW work arrives as a Linear issue with a Slite PRD and sometimes sub-issues the team already wrote, and the first version of this build had no route for it at all: `grill-issue` handed a decision log into plan mode, where it evaporated, and `implement` needs a run it had no way to produce.

It now writes the run. The PRD is **snapshotted** into `spec.md` with a pointer back to Slite rather than linked, because an implementer subagent runs AFK and may have no Slite access — a run that cannot be built without a browser is not a run. Existing sub-issues are mirrored as slices and then **reviewed**, because two things cannot be imported: Linear's MCP exposes no issue relations, so every `blocked-by` comes back empty and the frontier would offer the whole set at once; and a breakdown written for people is not always a set of vertical slices.

### Two tracking layers

Linear is the team's record: issues as the team understands them, with status, assignee, project, and cycle. It gets nothing else.

The **run graph** is the execution surface, under `$(cw --state)/runs/<slug>/` — the shared git directory, in both storage modes, for the reason given above. It holds the slices, their blocking edges, triage state, claims, agent briefs and branch bindings, as one markdown file per slice.

The two are bound by a pointer. Each run records the Linear issue it serves (`linear: TMRW-123`). A single comment back on the Linear issue is available for traceability, as an opt-in, never as a label.

The rule that keeps the boundary from blurring: **the run graph is always complete, and Linear receives only what I would have created by hand anyway.** Publishing to Linear is always a deliberate act.

Three things follow from this, beyond keeping Linear clean:

- Everything is local-first and Linear is a publish target, so `wayfinder`'s local map is not a special case.
- Frontier, blocking, and claim logic stop depending on Linear's relation semantics, so they work unchanged in personal repos and open source projects with no tracker at all.
- Triage states become local labels, which is what makes triage usable on slices I wrote myself without that process appearing on a team board.

This is a change to current behaviour: today's `to-spec` and `to-slices` apply a `ready-for-agent` label to Linear, and they will stop.

### Concurrency across worktrees

Because run state lives in the shared git directory, every worktree of a repo already resolves to the same one, which makes it the natural coordination point.

Each slice file records `status`, `blocked-by`, `branch` and `stack-parent`. A **claim is a directory**, not a field, because `mkdir` is atomic and a field is not: two worktrees racing both call `mkdir`, exactly one succeeds, and the winner writes a `holder` file naming its branch, worktree and session. A field would need read-modify-write, which has no atomic form in a shell script, and both racers would believe they had won. One file per slice means concurrent writes to different slices never collide. That is the whole mechanism; there is no lock manager.

`cw status` enumerates live worktrees, their branches, their tmux sessions, and their claimed slices. It is computed from `git worktree list`, `tmux has-session` and the claim directories rather than stored, so it cannot go stale. It skips worktrees git reports as `prunable`, which are registrations whose directory or `.git` file has gone; on a repo that has seen a few agent sessions those outnumber the live ones, and they are noise in a context window.

The format is specified in [run-graph.md](run-graph.md).

A `SessionStart` hook injects that summary into every new agent session in the repository, so an agent starts knowing what else is in flight and what is already claimed.

### Wayfinder labels: a decision that was superseded

An early answer chose personal-prefixed labels, `nick/wayfinder:map` and the like, so that maps could be queried on the board. The later instruction that Linear "should not have any indicators of this workflow" overrides it, and phase 4 implemented that as a flat rule. <!-- glossary-exempt -->

So a published map is a parent issue and sub-issues carrying no labels at all — exactly what would have been created by hand. The cost is that maps cannot be queried on the board; the local run graph is the index instead, and `cw` lists what exists. That is the right trade: a label naming this workflow is the precise thing the constraint forbids.

### Stacked pull requests

The run graph already holds what stacking needs, given two fields per slice: `branch` and `stack-parent`.

A linear chain of blocking edges is a stack, and `to-slices` marks chains as such. `wt-add <branch> <parent-branch>` already accepts a base override, which is the stack parent, so no change is needed there. `gh-stack` handles push, rebase, sync, and PR bodies. When a parent gets review changes and `gh-stack` restacks, the graph's edges identify which worktrees need rebasing.

`implement-spec` therefore has two modes rather than Matt's single integration branch: **stack** (one PR per slice, incrementally reviewable) and **integration** (everything onto one branch, one PR). It defaults to stack when the graph is a chain and integration when it is a wide fan-out, because a six-wide fan-out cannot be stacked.

### Invocation split

Matt's split between model-invoked and user-invoked skills rests on one invariant: **a user-invoked skill can never be called by another skill.** That invariant, plus the call graph, determines which side each skill lands on.

Skills that must stay model-invoked, because other skills call them via the Skill tool: `grilling`, `domain-modeling`, `codebase-design`, `tdd`, `prototype`, `research`, `implement`, `review-loop`, `code-review`, and the `tmrw-standards` plugin's `commit` and `create-pr`. `codebase-design` belongs here because `tdd` and `improve-codebase-architecture` both reach it that way, and `implement` because `implement-spec` dispatches each slice to it.

Skills that become user-invoked, with `disable-model-invocation: true`: `setup-workspace`, `grill-me`, `grill-issue`, `grill-with-docs`, `to-spec`, `to-slices`, `triage`, `implement-spec`, `wayfinder`, `handoff`, `improve-codebase-architecture`, `self-review`, `apply-review`, `retro`, `diagnosing-bugs`, `wizard`.

### The review contract exists twice

`self-review`'s `references/handoff-format.md` and the plugin's `review-loop/references/handoff-format.md` are two copies of one contract. On the work layer the writer half of the loop comes from this repo and the reviewer half from the plugin, so if they disagree the negotiation breaks mid-flow — each side reading a spec the other is not writing to.

They do not disagree today. The eight lines that differ are all about which skills do what: this repo's copy names `self-review`, `apply-review` and `review-loop`, while the plugin's names only `review-loop`, because it ships neither of the others. The format — headings, dispositions, the seed snippet, the thread file location — is identical.

`tests/review-contract.sh` holds it that way. It compares the structural parts and the thread path, and tolerates the prose that legitimately differs between the two packages. Two copies is still the real problem, and the fix is upstream: see slice 10.

### A conflict to resolve first

`code-review` and `review-loop` exist twice on a work-layer machine: in `~/.claude/skills` via this repo, and in the `tmrw-standards` plugin, whose copies are forks with cross-references rewritten to `tmrw-standards:`. The plugin is enabled only on the work layer, so the personal copies are the personal-layer fallback and cannot simply be deleted.

Fix: make `dev-env`'s `claude` run script layer-aware, so it skips linking the colliding entries when `layer=work`.

The collision is **two** skills, not four: `tmrw-standards` ships `code-review` and `review-loop`, but has no `self-review` or `apply-review`, so skipping all four would have deleted two working skills.

It is **skills only**. The plugin also ships nine `cr-*` agent files, but plugin agents surface under a `plugin:name` prefix and these never did: the bare `cr-*` types the review skills spawn come from this repo. Skipping them on the work layer broke those skills, so agents are linked on every layer.

A directory symlink cannot exclude entries, so `~/.claude/skills` and `~/.claude/agents` are now real directories of per-entry links, rebuilt on each run. The rebuild removes only links pointing into this repo, so anything else kept there survives, and a deleted skill or a layer switch leaves no orphan. It also moved where Claude Code writes `skills/synced/`: out of this repo, where it only lived because the whole directory was the link target, and into `~/.claude/skills/`.

## Skills

Added: `setup-workspace`, `grilling`, `domain-modeling`, `grill-with-docs`, `research`, `triage`, `implement`, `implement-spec`, `wayfinder`, `retro`, `diagnosing-bugs`, `codebase-design`, `wizard`. All built.

Changed: `to-spec` and `to-slices` move onto the run graph and stop writing labels to Linear; `grill-me` and `grill-issue` are rewired onto the extracted `grilling` primitive; `handoff` writes into the workspace instead of `mktemp`; the review skills gain the layer-aware deployment fix.

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

**All seven phases are complete.** Their automated criteria live in `tests/phase-1.sh` through `tests/phase-7.sh`, with `tests/glossary.sh` cutting across them; phase 1's tmux, worktree and shared-repo criteria are the manual checklist its script prints, and all have been run, the last against `tmrw-core-api`.

### Phase 1 — Foundation

`cw` resolver, `wt-add` integration and `--no-attach`, `setup-workspace`.

- `cw --sidecar`, `cw --state` and `cw --repo` print identical paths from the main checkout and from two different worktrees of the same repo. Bare `cw` does too under sidecar mode, but is per-worktree under `in-repo`.
- `cw --mode` reports `unconfigured` before setup, and `cw` resolves to the sidecar, so an unconfigured repo is never written into.
- A `config.md` in the repo's `.agents/workspace/` makes `cw --mode` report `in-repo`; one in the sidecar makes it report `sidecar`. A `config.md` directly in `.agents/`, which belongs to the repo's owners, is not our signal and leaves the mode `unconfigured`.
- With both present, `cw --mode` reports `sidecar`, because ambiguity must resolve away from the repo.
- Under `in-repo`, each worktree resolves `cw` to its own `.agents/workspace/`, and a worktree created before it was committed reports `unconfigured`.
- Under `sidecar`, every worktree resolves `cw` to the same path.
- `cw --state` resolves to the same path from the main checkout and every worktree, and files written there do not appear in `git status`.
- `cw` outside a git repository exits non-zero with a clear message.
- `wt-add <branch>` behaves exactly as it does today.
- `wt-add --no-attach <branch>` creates the worktree and tmux session while leaving the current client attached where it was.
- `setup-workspace` on this repo writes `.agents/workspace/config.md`, `tracker.md` and `domain.md`, and creates no sidecar.
- **[tmrw]** `setup-workspace` on a `~/tmrw` repo defaults to sidecar mode, writes nothing inside the repo, and leaves `git status` clean.

### Phase 2 — Run layer

Run graph format, claims, frontier, `cw status`, `SessionStart` hook.

- A run with three slices and a blocking chain exposes exactly one frontier slice.
- Claiming from worktree A succeeds; claiming the same slice from worktree B fails.
- Closing a blocker moves the next slice onto the frontier.
- `cw status` lists live worktrees, branches, sessions, and claims; killing a tmux session removes it from the output, which proves the output is computed rather than stored.
- `cw close` on a blocker releases its claim as well as marking it done.
- Opening a session in worktree B surfaces worktree A's branch and claimed slice in context.
- `handoff` writes into the workspace rather than `mktemp`, names the skills the next agent should call, and redacts secrets.
- A `prototype` run leaves its branch local and its pointer in the run graph, and pushes nothing.

### Phase 3 — Invocation split

- `grilling` and `domain-modeling` are reachable through the Skill tool from inside another skill.
- A user-invoked skill does not fire from a casual message that would previously have triggered it.
- A skill that calls `code-review` still resolves it.
- **[tmrw]** On the work layer, `code-review` and `review-loop` each resolve to exactly one definition.
- Deleting a skill from this repo removes it from `~/.claude/skills` on the next deploy, and switching layers does not leave orphans behind.
- No skill names a user-invoked skill to the Skill tool, and every skill it does name exists.
- Every `cr-*` agent is deployed on **both** layers, and every skill except the two the plugin replaces is deployed.
- No user-invoked skill keeps a model-facing trigger list in its description.

### Phase 4 — Spec pipeline

`to-spec`, `to-slices`, `triage` on the run graph.

- `to-slices` on a spec produces N slice files with correct edges and writes nothing to Linear.
- An explicit publish creates a Linear issue carrying no workflow labels.
- `triage` moves a slice through its states and writes an agent brief without touching Linear.
- `tdd` names the seams under test and asks for confirmation before writing a test, using the same seams `to-spec` sketched.
- `tdd` rejects a tautological test, one whose expected value is recomputed the way the code computes it.
- `to-spec` saves the spec into the run graph, not the repo root.
- `to-slices` sets `stack-parent` where the graph is a chain, and verifies its own edges with `cw frontier`.
- `to-spec` and `tdd` use the same words for seams, so the handoff between them is not a term the receiving end has never heard.
- **[tmrw]** After a full `to-spec` → `to-slices` → publish cycle, `git status` is clean and the TMRW Linear workspace has gained no workflow labels.

### Phase 5 — Implement

- `implement <slice>` claims the slice, creates a worktree through `wt-add`, builds, runs `review-loop`, commits, and releases the claim.
- A chain-shaped graph selects stack mode; a fan-out selects integration mode, decided by `cw shape` rather than by eye.
- `cw shape` reads the edges, not the progress: a partly-worked chain is still a chain.
- `implement` claims before it builds, and stops rather than working a slice another session holds.
- `implement-spec` warns that subagents need `cw` on the permission allowlist before it spawns any.
- **[tmrw]** `implement-spec` on a three-slice chain produces three stacked PRs with correct base branches.

### Phase 6 — Wayfinder

- A map and its slices are created, claimed, worked and closed with no tracker configured at all.
- A map is a run: it reuses the frontier, claims and blocking edges rather than inventing a parallel mechanism, and its `type:` key is one `cw` neither needs nor minds.
- Publishing produces a parent Linear issue and its sub-issues, carrying **no** labels.
- After publishing, the local map keeps the fog and the decision detail; Linear is canonical for what the team reads.
- A slice worked with a human cannot be resolved by the agent answering itself.

### Phase 7 — Health skills

`retro`, `diagnosing-bugs`, `codebase-design`, `wizard` ported and each invoked successfully once.

- `deep-modules.md`, `interface-design.md` and `refactoring.md` live in `codebase-design` and no longer in `tdd`, and `tdd` reaches them by calling the Skill tool.
- `improve-codebase-architecture` scopes its scan from `git log` hot spots before exploring, and applies the deletion test to each suspected shallow module.

### What is actually proven

A criterion written down is not a criterion met. The suites carry a lot of checks, but some criteria are not the kind a script can settle, and a few are simply not settled yet. Keeping the distinction visible is the point: the alternative is believing the suite covers more than it does. Run the suites for the current count rather than trusting a number written here.

**Proven by automated test.** Everything about `cw`'s resolution, storage mode, run graph, claims, frontier, `cw status`, the deploy's exclusions and orphan handling, and the invocation invariant. These re-run on every phase.

**Proven by hand, once, in the session that built it.** `wt-add` unchanged and `--no-attach` not moving the client; the run graph surviving `wt-rm`; `setup-workspace` on this repo and on `tmrw-core-api`. The last two were executed step by step rather than invoked as a skill, so the skill's own prose is unexercised.

**Proven in a real second worktree.** A worktree was created with `wt-add --no-attach`, a slice claimed from the main checkout, and a headless session started in the worktree. It named the other worktree, its branch, its session and the claimed slice from session-start context alone, and concluded on its own that the slice belonged to someone else. The behaviour the hook exists for, not just the mechanism. The same worktree confirmed that a handoff written under `cw --state` is visible from the main checkout, and that a `prototype/<name>` branch gets no upstream and never reaches `origin`.

**Not yet proven.**

- `grill-issue` has not been run since it was rewired onto `grilling`, and `review-loop` has not been run since it started resolving to the plugin's copy. Both need a `~/tmrw` repo and a live conversation.
- The `handoff` and `grill-*` skills' own invocation is unexercised: they are user-invoked, so no headless run can fire them. Their underlying mechanisms are proven; the slash command itself needs a human.
- "A skill that calls `code-review` still resolves it" is vacuous: nothing calls it until phase 5.
- Phase 4 is prose a model follows, so its suite checks the constraints that prose must satisfy — no workflow labels, writes into the run graph, one vocabulary for seams — not that a model obeyed it. A full `to-spec` → `to-slices` → publish cycle on a `~/tmrw` repo is still unrun.

### Almost nothing has actually been run

The machinery is tested: `cw`, the run graph, claims, the frontier, shape, the deploy, the invocation invariant and the vocabulary all have suites, and the hard constraint has been demonstrated end to end on `tmrw-core-api`.

The **skills** are a different matter. Of nineteen, one has been invoked (`domain-modeling`, to write the glossary) and one loaded (`codebase-design`). The rest have never run. Their suites check that their prose satisfies the constraints — no workflow labels, writes into the run graph, one vocabulary — not that a model follows it well.

That is the honest state going into first real use, and it is the right order: the machinery had to be right before the prose was worth testing. But the first genuine piece of work will find things no suite here can, and the expectation should be that it does.

### AFK agents need `cw` permitted

The headless session could not run `cw --state`, because the path it resolves is only known at runtime and the permission prompt had no one to answer it. Nothing in the design is wrong, but it is a real constraint on phase 5: implementer subagents run AFK and every skill that resolves a path through `cw` will stall the same way. `cw` has to be on the allowlist for those runs, and it is a safe thing to allow — its flags only print paths, and its verbs only touch the run graph inside `.git`.

### Project-level criteria

These are re-run at the end of every phase, not just at the end.

- **[tmrw]** A full cycle in a shared repo leaves `git status` clean and adds no workflow artifacts to its history.
- **[tmrw]** No `nick/*`, `wayfinder:*`, or `ready-for-agent` label exists in the TMRW Linear workspace at all.
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
4. Build phase 2, then seed the run graph with slices for phases 3 through 7. From there the work tracks itself.

Step 3 was skipped at the time, and the cost showed up exactly where it was predicted: three review passes each caught vocabulary drift — `existing seams` against `seams that already exist`, `PRD` against `spec`, `issues` against `slices`.

It has since been done, after phase 4 and before phase 5. Writing the glossary immediately surfaced two more: `task graph` used for the run graph in five places, and a **factual** error in both tracker templates putting the run graph under the docs root rather than in the run state. <!-- glossary-exempt --> `tests/glossary.sh` now enforces every rejected synonym, which turns a recurring manual review finding into a check.

One risk to hold onto: dogfooding a half-built system on the repository that *is* the system means a broken skill can block the work of fixing it. So phase 1's tooling stays simple and independently testable, and the run graph never becomes the only record of what is left to build. This note is the backstop.

## Settled decisions

- The Linear MCP server is the one in `tmrw-standards`, not the claude.ai connector. `tracker.md` names it.
- `cw` lives in this repo at `scripts/cw`, symlinked by `dev-env`'s `claude` run script, so the skills stay self-contained.
- The glossary has no promotion path into Slite for now. Revisit once there is a glossary worth promoting.
- `dev-env`'s `claude` run script skips symlinking the review skills and `agents/cr-*` when `layer=work`.
