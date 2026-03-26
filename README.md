# claude-config

Custom [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills. Symlinked into `~/.claude/skills`.

## Skills

- **tdd** — Test-driven development with red-green-refactor loop
- **grill-me** — Interview the user relentlessly about a plan or design until reaching shared understanding
- **write-a-prd** — Create a PRD through user interview, codebase exploration, and module design
- **prd-to-issues** — Break a PRD into independently-grabbable Linear issues using vertical slices
- **improve-codebase-architecture** — Explore a codebase for architectural improvements, focusing on deepening shallow modules

## Setup

```sh
ln -s ~/personal/claude-config/skills ~/.claude/skills
```
