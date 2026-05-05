---
name: code-review
description: Comprehensive multi-agent code review that spawns parallel specialist agents (architecture, security, correctness, testing, performance, readability) and consolidates findings into a prioritized review. Use when the user asks to "review my code", "review my branch", "review this PR", "code review", "check my changes", "look over my work", "what did I miss", or any request for feedback on code changes before merging. Also use when the user invokes /code-review. Even if the user doesn't say "review" explicitly, trigger this skill when they want a second opinion on changes they've made.
---

# Code Review

Six specialist subagents examine the same diff through different lenses, then findings are consolidated into a single prioritized review with file:line references for every issue.

## Subagents

This skill uses custom subagents defined in `~/.claude/agents/`. The review agents are read-only (Read, Grep, Glob only) and run on Sonnet for a balance of capability and cost. The explore agent runs on Haiku for speed.

| Agent | Purpose | Model |
|-------|---------|-------|
| `cr-explore` | Build shared context from changed files, deps, tests, docs | Haiku |
| `cr-review-architecture` | System design, repo conventions, observability | Sonnet |
| `cr-review-security` | Vulnerabilities, auth, data exposure | Sonnet |
| `cr-review-correctness` | Bugs, logic errors, edge cases, error handling | Sonnet |
| `cr-review-testing` | Test coverage, test quality, assertions | Sonnet |
| `cr-review-performance` | N+1 queries, algorithmic issues, hot paths | Sonnet |
| `cr-review-readability` | Naming, complexity, consistency | Sonnet |

## Arguments

- `--draft` — Create a pending GitHub PR review with inline comments instead of terminal output. Requires a PR to exist for the current branch.
- `--base <branch>` — Override the base branch for diff comparison. Default: auto-detect.

## Process

### 1. Gather Context (inline)

Do this in the main conversation — it needs access to MCP tools (Linear) and is fast enough to run inline.

**Detect review target:**
1. Check for a PR: `gh pr view --json number,title,body,baseRefName,headRefName,url,reviews,comments 2>/dev/null`
2. If PR exists: use the PR's base branch and diff
3. If no PR: diff the current branch against the auto-detected base branch
4. Base branch detection: check for `develop` first, fall back to `main`, then `master`. Respect `--base` override if provided.
5. Get the diff: `git diff <base>...HEAD` (for branch) or `gh pr diff` (for PR)
6. Get diff stats: `git diff <base>...HEAD --stat`

**Fetch external context (skip gracefully if unavailable):**

- **Linear issue**: Parse the branch name for issue identifiers (patterns like `PROJ-123`, `feat/PROJ-123-description`, `fix/PROJ-123`). If found, fetch via Linear MCP tools — include the issue title, description, and acceptance criteria. If Linear MCP is not available or the branch has no issue ID, skip silently.
- **PR metadata**: If a PR exists, extract the description body and any existing review comments. The review agents should not re-raise issues already flagged by reviewers.

### 2. Explore Codebase (subagent)

Spawn a single `cr-explore` agent. Pass it the list of changed file paths from the diff. It returns a structured context package containing:

1. Full content of all changed files
2. Dependency graph (imports in/out for each changed file)
3. Existing test files for changed modules
4. All discovered repo documentation (CLAUDE.md, READMEs, architecture docs, skills)

```
Use the Agent tool with:
  subagent_type: cr-explore
  prompt: <list of changed file paths from the diff>
```

### 3. Review (6 parallel subagents)

Spawn all six review agents in parallel — a single assistant message containing six `Agent` tool_use blocks, one per `subagent_type` below. Each receives the same context brief via the Agent tool's `prompt` parameter. The agents' system prompts (defined in their `.md` files) contain domain-specific mandates — you only need to pass the context.

The 6 required `subagent_type` values:

1. `cr-review-architecture`
2. `cr-review-security`
3. `cr-review-correctness`
4. `cr-review-testing`
5. `cr-review-performance`
6. `cr-review-readability`

Note: Claude Code's grouped agent panel may display fewer than 6 entries because finished agents drop off as new ones complete. This is a UI rendering quirk, not a sign that an agent failed to run. Confirm by checking that all 6 returned structured findings before consolidating — if any are genuinely missing, re-spawn the missing ones.

**The context brief includes:**
- The full diff
- Full content of all changed files (from cr-explore)
- Dependency graph (from cr-explore)
- Existing test files (from cr-explore)
- Repo documentation and conventions (from cr-explore)
- Linear issue context (from Step 1, if available)
- PR description and existing review comments (from Step 1, if available)

Each agent returns structured JSON with findings. An empty findings array is a valid, good outcome.

### 4. Consolidate (inline)

Do this in the main conversation — you have the full picture and can make judgment calls.

**Severity classification — apply these definitions strictly during consolidation:**
- **Critical**: Will cause user-facing impact on deploy, breaks the feature, introduces a security vulnerability that's exploitable now, or causes data loss/corruption. If it works today and would only become a problem at significantly higher scale, it's a warning, not a critical.
- **Warning**: Real issues that should be addressed — design concerns, scalability risks, missing validation, gaps that could bite later — but the feature works correctly as deployed.
- **Suggestion**: Minor improvements — readability, consistency, small optimizations. Take it or leave it.

**Consolidation steps:**

1. **Merge overlapping findings**: When multiple agents flag the same code location for related reasons, combine into one finding listing all relevant domains. Keep the highest severity.
2. **Apply severity definitions**: Re-classify each finding using the definitions above. Agents tend to over-classify — a scalability concern is a warning, not a critical. Be strict.
3. **Rank by severity**: Criticals first, then warnings, then suggestions.
4. **Preserve attribution**: Tag each finding with the domain(s) that raised it (e.g., `[Security, Architecture]`).
5. **Cap suggestions**: Keep at most 5 suggestions — pick the strongest. Criticals and warnings always survive regardless of count.
6. **Store structured findings**: Retain the structured finding data for potential draft PR review posting later in the conversation.

### 5. Output

#### Terminal (default)

Produce the formatted review **exactly once** in a single message. Do not emit a preview, partial draft, or example before the final version. Consolidation in Step 4 happens silently — no user-facing text until you write this output.

**Per-finding format** (used inside every severity section):

```
**[<Domain>, <Domain>] <title>**
`<file>:<line-start>-<line-end>`
<explanation>
**Recommendation:** <recommendation>
```

Findings within a section are separated by a `---` line.

**Top-level structure:**

```
## Code Review: <branch-name>

### Context
- Branch: <branch> vs <base>
- Linear: <issue-id> — <issue-title>       (omit if no issue)
- PR: #<number> — <title>                  (omit if no PR)
- Files changed: <n> | Additions: <n> | Deletions: <n>

### Critical (<count>)
<all critical findings, in per-finding format, separated by --->

### Warnings (<count>)
<all warning findings, in per-finding format, separated by --->

### Suggestions (<count>)
<all suggestions, in per-finding format, separated by --->
```

Omit any severity section that has zero findings. If every section is empty, output only:

```
### No issues found
Reviewed for architecture, security, correctness, testing, performance, and readability.
```

When a PR exists and `--draft` was not used, append at the very end:

```
> PR #<number> detected — say "post as draft review" to create a pending GitHub review with inline comments you can edit before submitting.
```

#### Draft PR Review

Triggered by `--draft` flag or by saying "post as draft review" after a terminal review.

Read [references/draft-review.md](references/draft-review.md) for the full guide on posting — it covers the API format, review body template, and how to write conversational inline comments.

Use the stored structured findings from Step 4 — do not re-run the review agents.
