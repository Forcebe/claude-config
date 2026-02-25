# claude-config

Custom [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills and agents. Symlinked into `~/.claude/skills` and `~/.claude/agents`.

## Skills

- **visual-explainer** — Generate self-contained HTML pages for technical diagrams, visualizations, and data tables
- **diff-review** — Visual HTML diff review with before/after architecture comparison and code review analysis
- **plan-review** — Visual HTML plan review comparing current codebase against a proposed implementation plan
- **project-recap** — Visual HTML project recap for rebuilding mental model of a project's current state
- **fact-check** — Verify factual accuracy of a document against the actual codebase, correct in place
- **tdd** — Test-driven development with red-green-refactor loop

## Agents

- **visual-generator** — Subagent with visual-explainer preloaded; used by diff-review, plan-review, and project-recap via `context: fork`

## Setup

```sh
ln -s ~/.claude-config/skills ~/.claude/skills
ln -s ~/.claude-config/agents ~/.claude/agents
```
