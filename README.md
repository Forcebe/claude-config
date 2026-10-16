# claude-config

Custom [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills. Symlinked into `~/.claude/skills`.

## Skills

Skills split on one axis: **who can reach them.** A user-invoked skill is reachable only by typing its name, and — the invariant everything else rests on — can never be called by another skill. Model-invoked skills are the ones skills call via the Skill tool, so anything another skill depends on has to stay model-invoked.

### User-invoked

Entry points. Type them; nothing else can.

- **setup-workspace** — Configure a repo's agent workspace: storage mode, issue tracker, domain doc layout. Run once per repo.
- **grill-with-docs** — Stress-test a plan by interview, building the glossary and ADRs as decisions land. The one to use in a repository.
- **grill-me** — The same interview, stateless. For when there is no repo under the work.
- **grill-issue** — The same, anchored to the Linear issue on the current branch and its PRD.
- **to-spec** — Synthesize a spec from the conversation, codebase exploration, and test-seam design, saved into the run graph.
- **to-tickets** — Break a spec into tracer-bullet tickets in the run graph, each declaring its blocking edges.
- **triage** — Take a ticket from raw to agent-ready: verify the claim, grill it into shape, write the brief. States stay local.
- **implement-spec** — Build a whole run: work its frontier until the graph is empty, as a stack of PRs or on one integration branch.
- **improve-codebase-architecture** — Explore a codebase for module-deepening refactors.
- **handoff** — Compact the conversation into a handoff document for another agent to pick up.
- **self-review** — Reviewer side of a writer↔reviewer thread on your own branch.
- **apply-review** — Writer side of that thread: fix, dispute, or mark stale, then hand back.

### Model-invoked

Primitives and references. Skills call these; so can you.

- **grilling** — The interview technique itself: a design tree worked in rounds, recommended answer on every question, facts found rather than asked.
- **domain-modeling** — Build and sharpen the project's domain model, writing `GLOSSARY.md` and ADRs as terms and decisions resolve.
- **research** — Delegate reading to a background agent, which cites primary sources and leaves a Markdown file in the workspace.
- **tdd** — Test-driven development with the red-green-refactor loop.
- **prototype** — Build a throwaway prototype to answer a design question.
- **implement** — Build one ticket: claim, worktree, TDD, review, close. Model-invoked because `implement-spec` dispatches each ticket to it.
- **gh-stack** — Manage stacked branches and PRs with the gh-stack CLI extension.
- **code-review** — Multi-agent review over a diff, proving or refuting findings by running tests and API calls.
- **review-loop** — The whole writer↔reviewer negotiation, in the chat that wrote the code.

On the work layer `code-review` and `review-loop` come from the `tmrw-standards` plugin instead, and this repo's copies are not deployed; see Setup.

## Agents

`agents/` holds the internal subagents the review skills spawn: `cr-explore`, six `cr-review-*` specialists, `cr-verify` (the only one with execution rights), and `cr-adjudicate`, which rules on the writer's responses without having seen the conversation that produced them.

## Scripts

`scripts/cw` resolves where a repository's agent files live. It is a pure resolver: it prints paths and creates nothing.

```sh
cw            # domain docs: .agents/workspace/ in-repo, or the sidecar
cw --state    # run state, in the shared git dir — same from every worktree
cw --mode     # "in-repo", "sidecar", or "unconfigured"

cw status                 # every worktree, its branch, tmux session and claims
cw frontier <run>         # tickets that are open, unblocked and unclaimed
cw shape <run>            # "chain" (stackable) or "fan-out" (needs integration)
cw claim <run> <ticket>   # atomic; non-zero exit if someone already holds it
cw close <run> <ticket>   # mark done, and release
```

Flags resolve paths and never write; verbs act on the run graph, whose format is in `docs/run-graph.md`. `scripts/session-context` is the `SessionStart` hook that tells a new session what other worktrees are holding.

The storage mode is not recorded anywhere. It is implied by which `config.md` exists: one in the repo's `.agents/workspace/` means in-repo, one in the sidecar means sidecar, and a sidecar config wins if both exist. `.agents/` itself belongs to whoever owns the repo, so a config sitting directly in it is not our signal; only the nested one is. An in-repo repo therefore needs no sidecar and describes itself wherever it is cloned.

Domain docs follow that mode, which under in-repo makes them tracked files belonging to the branch being worked on. Run state is always repo-wide, so concurrent worktrees can see each other's claims.

The sidecar lives at `~/.claude-workspace`, overridable with `CLAUDE_WORKSPACE_ROOT`.

## Design

`docs/agent-workspace-design.md` is the design note for the in-progress workspace build: its constraints, phases, and acceptance criteria. `docs/run-graph.md` specifies the ticket format. `tests/phase-N.sh` holds each phase's criteria as a runnable script, re-run at the end of every later phase, and `tests/glossary.sh` enforces the vocabulary in `.agents/workspace/GLOSSARY.md`.

## Setup

`dev-env`'s `claude` run script does all of this; run `./run claude` there.

`~/.claude/skills` and `~/.claude/agents` are **directories of per-entry symlinks**, not directory symlinks, rebuilt on each deploy. A directory symlink cannot exclude entries, and on the work layer two of these skills have to be excluded because `tmrw-standards` ships its own:

- **skills**: every one except `code-review` and `review-loop` on the work layer, which come from the plugin instead. `self-review` and `apply-review` have no plugin equivalent and are deployed on both layers.
- **agents**: all of them, on both layers. The plugin ships `cr-*` files too, but plugin agents surface under a `plugin:name` prefix, so they are not substitutes for the bare types the review skills spawn.
- **scripts**: `cw` and `session-context` into `~/.local/bin`, which `dev-env` does not wipe.

The rebuild removes only links pointing into this repo, so anything else kept in those directories survives, and a deleted skill leaves no orphan. `skills/synced/` is written by Claude Code into `~/.claude/skills/`, not here.
