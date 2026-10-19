# Issue tracker: Linear

Team-facing issues for this repo live in Linear, reached through the `tmrw-standards` MCP server. Tools are prefixed `mcp__plugin_tmrw-standards_linear__`.

Use this server, not the claude.ai Linear connector. Both point at the same Linear endpoint, so either would work, but one of them has to be chosen or sessions drift between them.

## What Linear is for

Linear is the **team's record**: issues as the team understands them, with status, assignee, project and cycle.

It is **not** the execution surface. The **run graph** — slices, blocking edges, triage state, claims, branch bindings — lives in the run state that `cw --state` prints, and Linear never sees any of it.

Three rules follow:

- **No workflow labels.** No `ready-for-agent`, no `wayfinder:*`, no agent metadata of any kind.
- **No synthetic sub-issues.** An implementation slice that exists only to sequence agent work stays in the run graph.
- **Publishing is deliberate.** Linear receives only what would have been created by hand anyway, and only when asked.

A run binds to Linear with a pointer, `linear: TMRW-123`, recorded in the run, not with anything written onto the issue.

## Operations

| Need | Tool |
|---|---|
| Read one issue | `get_issue` |
| Find issues | `list_issues` |
| Create or update an issue | `save_issue` (creates when given no id, updates when given one) |
| Read comments | `list_comments` |
| Comment | `save_comment` |
| Resolve a status name to its id | `list_issue_statuses` |
| Resolve a team or project | `list_teams`, `list_projects` |
| Resolve a person | `list_users`, `get_user` |

Confirm parameter names against the tool schema before the first call in a session rather than assuming them.

The Linear MCP does not expose issue **relations**, so a blocking edge cannot be written to Linear even deliberately. Blocking lives in the run graph, which is where it belongs anyway.

## Slice ids

Branches carry the Linear id (`TMRW-123`, `feat/TMRW-123-description`). `wt-add` derives the worktree directory from it, so the id is recoverable from any worktree path.

## When a skill says "publish to the issue tracker"

Create a Linear issue with `save_issue`, with no labels beyond what the team already uses. Report the URL.

## When a skill says "fetch the relevant slice"

Resolve the id from the branch name, then `get_issue` plus `list_comments`.
