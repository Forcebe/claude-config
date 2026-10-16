# claude-config

Custom [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills. Symlinked into `~/.claude/skills`.

## Skills

### Workspace

- **setup-workspace** — Configure a repo's agent workspace: storage mode, issue tracker, domain doc layout. Run once per repo.

### Review

- **code-review** — Multi-agent review that runs specialist agents over a diff, then proves or refutes their falsifiable findings by running tests and API calls
- **self-review** — Reviewer side of a writer↔reviewer negotiation thread on your own branch
- **apply-review** — Writer side of that thread: fix, dispute, or mark stale, then hand back
- **review-loop** — Runs the whole writer↔reviewer negotiation automatically in the chat that wrote the code, then reports what changed

### Planning

- **grill-me** — Interview the user relentlessly about a plan or design until reaching shared understanding
- **grill-issue** — The same, anchored to the Linear issue on the current branch
- **to-spec** — Synthesize a spec/PRD from the conversation, codebase exploration, and test-seam design
- **to-tickets** — Break a spec/PRD into independently-grabbable Linear issues as tracer-bullet vertical slices
- **prototype** — Build a throwaway prototype to flesh out a design before committing to it

### Building

- **tdd** — Test-driven development with red-green-refactor loop
- **improve-codebase-architecture** — Explore a codebase for architectural improvements, focusing on deepening shallow modules
- **gh-stack** — Manage stacked branches and PRs with the gh-stack CLI extension
- **handoff** — Compact the conversation into a handoff document for another agent to pick up

## Agents

`agents/` holds the internal subagents the review skills spawn: `cr-explore`, six `cr-review-*` specialists, `cr-verify` (the only one with execution rights), and `cr-adjudicate`, which rules on the writer's responses without having seen the conversation that produced them.

## Scripts

`scripts/cw` resolves where a repository's agent files live. It is a pure resolver: it prints paths and creates nothing.

```sh
cw            # domain docs: .agents/ in-repo, or the sidecar
cw --state    # run state, in the shared git dir — same from every worktree
cw --mode     # "in-repo", "sidecar", or "unconfigured"
```

The storage mode is not recorded anywhere. It is implied by which `config.md` exists: one in the repo's `.agents/` means in-repo, one in the sidecar means sidecar, and a sidecar config wins if both exist. So an in-repo repo needs no sidecar and describes itself wherever it is cloned.

Domain docs follow that mode, which under in-repo makes them tracked files belonging to the branch being worked on. Run state is always repo-wide, so concurrent worktrees can see each other's claims.

The sidecar lives at `~/.claude-workspace`, overridable with `CLAUDE_WORKSPACE_ROOT`.

## Design

`docs/agent-workspace-design.md` is the design note for the in-progress workspace build: its constraints, phases, and acceptance criteria. `tests/phase-N.sh` holds the criteria for each phase as a runnable script, re-run at the end of every later phase.

## Setup

```sh
ln -s ~/personal/claude-config/skills ~/.claude/skills
ln -s ~/personal/claude-config/agents ~/.claude/agents
ln -s ~/personal/claude-config/scripts/cw ~/.local/scripts/cw
```

`dev-env`'s `claude` run script does all three.
