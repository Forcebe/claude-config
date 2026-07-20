# claude-config

Custom [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills. Symlinked into `~/.claude/skills`.

## Skills

- **tdd** — Test-driven development with red-green-refactor loop
- **grill-me** — Interview the user relentlessly about a plan or design until reaching shared understanding
- **to-spec** — Synthesize a spec/PRD from the conversation, codebase exploration, and test-seam design
- **to-tickets** — Break a spec/PRD into independently-grabbable Linear issues as tracer-bullet vertical slices
- **improve-codebase-architecture** — Explore a codebase for architectural improvements, focusing on deepening shallow modules

## Setup

```sh
ln -s ~/personal/claude-config/skills ~/.claude/skills
```
