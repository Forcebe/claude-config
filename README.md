# claude-config

Custom [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills. Symlinked into `~/.claude/skills`.

## Skills

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

## Setup

```sh
ln -s ~/personal/claude-config/skills ~/.claude/skills
```
