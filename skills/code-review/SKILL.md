---
name: code-review
description: Comprehensive multi-agent code review that spawns parallel specialist agents (architecture, security, correctness, testing, performance, readability), proves or refutes their falsifiable findings by running tests and API calls, and consolidates what survives into a prioritized review. Use when the user asks to "review my code", "review my branch", "review this PR", "code review", "check my changes", "look over my work", "what did I miss", or any request for feedback on code changes before merging. Also use when the user invokes /code-review. Even if the user doesn't say "review" explicitly, trigger this skill when they want a second opinion on changes they've made. Do NOT use when they want the findings fixed as well as raised — use review-loop for that.
---

# Code Review

Six specialist subagents examine the same diff through different lenses. Findings that make a falsifiable claim about runtime behaviour are then executed — a verifier runs the test or hits the endpoint — so each one reaches you proven, refuted, or explicitly unverified. What survives is consolidated into a single prioritized review with file:line references for every issue.

## Subagents

This skill uses custom subagents defined in `~/.claude/agents/`. The review agents are read-only (Read, Grep, Glob only) and run on Sonnet for a balance of capability and cost. The explore agent runs on Haiku for speed.

`cr-verify` is the only agent with execution rights. It runs alone, after the review agents have finished — never alongside them — because it owns the test runner, dev server and database while it works.

| Agent | Purpose | Model |
|-------|---------|-------|
| `cr-explore` | Build shared context from changed files, deps, tests, docs | Haiku |
| `cr-review-architecture` | System design, repo conventions, observability | Sonnet |
| `cr-review-security` | Vulnerabilities, auth, data exposure | Sonnet |
| `cr-review-correctness` | Bugs, logic errors, edge cases, error handling | Sonnet |
| `cr-review-testing` | Test coverage, test quality, assertions | Sonnet |
| `cr-review-performance` | N+1 queries, algorithmic issues, hot paths | Sonnet |
| `cr-review-readability` | Naming, complexity, consistency | Sonnet |
| `cr-verify` | Prove or refute falsifiable findings by running them | Sonnet |

## Arguments

- `--draft` — Create a pending GitHub PR review with inline comments instead of terminal output. Requires a PR to exist for the current branch.
- `--base <branch>` — Override the base branch for diff comparison. Default: auto-detect.
- `--no-verify` — Skip the verification pass. Every finding is reported as the agents raised it.
- `--all` — Report every surviving finding instead of the top 10. Applies to terminal and draft output alike.

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

### 4. Merge and Queue (inline)

Do this in the main conversation — you have the full picture and can make judgment calls.

**Severity classification — apply these definitions strictly:**
- **Critical**: Will cause user-facing impact on deploy, breaks the feature, introduces a security vulnerability that's exploitable now, or causes data loss/corruption. If it works today and would only become a problem at significantly higher scale, it's a warning, not a critical.
- **Warning**: Real issues that should be addressed — design concerns, scalability risks, missing validation, gaps that could bite later — but the feature works correctly as deployed.
- **Suggestion**: Minor improvements — readability, consistency, small optimizations. Take it or leave it.

1. **Merge overlapping findings**: When multiple agents flag the same code location for related reasons, combine into one finding listing all relevant domains. Keep the highest severity, the clearest `problem`/`fix` pair, and the most concrete `verification` block of the ones merged — a single well-specified repro beats two vague ones.
2. **Apply severity definitions**: Re-classify each finding using the definitions above. Agents tend to over-classify — a scalability concern is a warning, not a critical. Be strict.
3. **Assign stable ids**: Number the surviving findings `#1`, `#2`, … ordered by severity. These ids appear in the output and are what the verifier reports against.
4. **Build the verification queue**: Every finding whose `verification.falsifiable` is true. If `--no-verify` was passed, or the queue is empty, skip step 5 and treat every finding as `N/A`.

Do not rank, cap, or rewrite prose yet — verification may still remove findings, and polishing something that's about to be refuted is wasted work.

### 5. Verify (subagent)

Spawn a single `cr-verify` agent and wait for it. Never run it alongside the review agents — it executes code, and the review agents' assumptions about the working tree must hold while they read.

```
Use the Agent tool with:
  subagent_type: cr-verify
  prompt: <the verification queue: id, title, file:line, claim, and the
           verification block (method, repro, expected) for each finding>
```

Also pass anything Step 1 already established that saves it work: the repo root, and any verification commands you saw in `CLAUDE.md`.

If the agent fails outright or returns unparseable output, do not retry it and do not guess: treat every queued finding as `UNVERIFIED` with the reason `verifier failed`, and say so in the output. A review that reports honestly on what it couldn't check is fine; one that implies checks happened is not.

It returns a verdict per id — `CONFIRMED`, `REFUTED`, `UNVERIFIED` or `N/A` — each with the command it ran and the output it saw. If it reports `unexpected_changes` in its teardown, surface that at the top of your output before anything else: it means the working tree moved during review and the human needs to check `git status` before committing.

### 6. Consolidate (inline)

1. **Apply the verdicts**:
   - `CONFIRMED` — keep the finding where it is, and attach the evidence as a `**Proven:**` line.
   - `REFUTED` — remove it from its severity section and move it to the Refuted block in the output. Never delete it silently.
   - `UNVERIFIED` — keep the finding at its severity, and attach the reason as an `**Unverified:**` line so the human knows it's unproven rather than proven.
   - `N/A` — no annotation. Most architecture and readability findings land here and that's expected; don't mark them as anything.
2. **Rank**: By severity first — criticals, then warnings, then suggestions — and within a severity by blast radius: how much breaks, how many callers, how likely it is to be hit. The result is one ordered list, not three groups.
3. **Preserve attribution**: Note the domain(s) that raised each finding. It renders alongside the severity, e.g. `[Critical · Security, Architecture]`.
4. **Apply the cap**: Keep the top 10. **Criticals are exempt** — if twelve things break on deploy, show all twelve. Refuted findings don't count toward the cap. Anything cut is gone: report the count, never the titles. A list of cut titles rebuilds the wall the cap exists to remove. Skip this step entirely under `--all`.
5. **Check the limits**: The agents now write final-shape prose, so this is a check, not a rewrite. Confirm each `summary` is one line, each `problem` is at most two sentences leading with the symptom, and each `fix` is one imperative sentence naming a concrete thing. Fix any that overrun, and write fresh prose for findings you merged in step 1 — a merged finding has no author. [references/comment-style.md](references/comment-style.md) defines the voice. Leave verification evidence alone: it's raw output and its value is being verbatim.
6. **Store structured findings**: Retain the structured finding data, including verdicts and evidence, for potential draft PR review posting later in the conversation.

### 7. Output

#### Terminal (default)

Produce the formatted review **exactly once** in a single message. Do not emit a preview, partial draft, or example before the final version. Merging, verification and consolidation happen silently — no user-facing text until you write this output.

Every `problem` and `fix` below must satisfy [references/comment-style.md](references/comment-style.md): plain, short, pitched at a competent engineer new to this repo.

**Per-finding format:**

```
**<n>. <summary>** [<Severity> · <Domain>, <Domain>]
`<file>:<line-start>-<line-end>`
<problem>
**Fix:** <fix>
**Proven:** <command> → <one-line observation>        (CONFIRMED only)
**Unverified:** <why it couldn't be checked>          (UNVERIFIED only)
```

Findings are numbered in rank order and separated by a `---` line. A `N/A` finding carries neither verification line — that's the normal state for judgement findings, and annotating it would imply something failed.

Where a `CONFIRMED` finding has a repro test attached, put it under the `**Proven:**` line as a fenced block. It's pasteable straight into the fix, which is most of its value.

**Top-level structure:**

```
## Code Review: <branch-name>

### Context
- Branch: <branch> vs <base>
- Linear: <issue-id> — <issue-title>       (omit if no issue)
- PR: #<number> — <title>                  (omit if no PR)
- Files changed: <n> | Additions: <n> | Deletions: <n>
- Verified: <n> confirmed · <n> refuted · <n> unverified   (omit if --no-verify)

### Findings (<n> shown, <n> cut)
<all findings, ranked, in per-finding format, separated by --->

### Refuted by verification (<count>)
- #<id> "<summary>" — <file>:<line>
    → <command> → <what was observed instead>
```

Write `<n> shown` alone when nothing was cut. Never list what was cut — the count is the whole disclosure, and you can re-run with `--all`.

Omit the Refuted block when nothing was refuted, but never omit it to shorten the output — a refutation that turns out to be wrong is how a real bug disappears, and this block is the only place you'd catch it.

**Landing under the cap is the good outcome.** Ten is a ceiling, not a target. A diff with three real problems gets three findings; padding it to ten with things that cleared the bar by a whisker trains you to skim, and a skimmed review is worth nothing. If the branch is clean, say so and stop.

If there are no findings at all, output only:

```
### No issues found
Reviewed for architecture, security, correctness, testing, performance, and readability.
<verification line, as in Context, if anything was verified>
```

When a PR exists and `--draft` was not used, append at the very end:

```
> PR #<number> detected — say "post as draft review" to create a pending GitHub review with inline comments you can edit before submitting.
```

#### Draft PR Review

Triggered by `--draft` flag or by saying "post as draft review" after a terminal review.

Read [references/draft-review.md](references/draft-review.md) for the full guide on posting — it covers the API format, review body template, and how to write conversational inline comments.

Use the stored structured findings from Step 6 — do not re-run the review agents.
