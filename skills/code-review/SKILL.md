---
name: code-review
description: Reviews code someone else wrote — a teammate's PR, a branch you did not author, or your own work in a session that did not write it. Spawns parallel specialist agents (architecture, security, correctness, testing, performance, readability), proves or refutes their falsifiable findings by running tests and API calls, and consolidates what survives into a ranked punch list. It reports; it does not change code. Use when the user asks to "review this PR", "review <someone>'s branch", "review PR 123", "look over this diff", or wants a second opinion on code they are not responsible for. Also use when the user invokes /code-review. Do NOT use for the user's own finished work in the chat that wrote it — use review-loop, which fixes what it finds.
---

# Code Review

**This reviews work you are not responsible for** — someone else's PR, a branch you didn't author, or your own work from a session that isn't this one. It reports and never edits. For your own finished work in the chat that wrote it, `review-loop` reviews and fixes in one pass.

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
1. **If the user named a PR** (a number or URL), resolve that one directly: `gh pr view <number> --json number,title,body,baseRefName,headRefName,headRefOid,url,reviews,comments`. Then confirm the working tree actually holds that PR's code, which the branch name alone does not establish:

   - `git rev-parse HEAD` must equal the PR's `headRefOid`. A local branch of the same name can sit behind the remote, or carry an unpushed commit.
   - `git status --porcelain` must be empty. Uncommitted work means the tree differs from the PR whatever the commit says.

   If either check fails, stop and say which one. Don't review anyway: `gh pr diff` would supply the remote change while the review agents and `cr-verify` read different local contents, so a finding could be refuted against code the PR doesn't contain. If the PR simply isn't checked out, offer `gh pr checkout <number>` and wait — it changes the user's working directory and can fail on a dirty tree.
2. **Otherwise**, resolve the PR for the current branch: `gh pr view --json number,title,body,baseRefName,headRefName,headRefOid,url,reviews,comments 2>/dev/null`

   Run the same two snapshot checks. A mismatch here means something different from step 1, though: unpushed commits and uncommitted work are the ordinary state of a branch someone is about to review, so don't stop. Keep the PR's metadata — the description and existing review comments are still worth having — but take the diff from the working tree rather than from `gh pr diff`, and record that in the Context block. The tree is what the agents read, so the tree is what they should be reviewing.
3. If a PR was found: use its base branch and diff
4. If no PR: diff the current branch against the auto-detected base branch
5. Base branch detection: check for `develop` first, fall back to `main`, then `master`. Respect `--base` override if provided.
6. Get the diff. Everything downstream — the stats, and the file list `cr-explore` and the reviewers receive — must come from this one source, because the diff and the agents have to describe the same code. A finding refuted against code the reviewer never read is worse than no verification at all.

   - **PR found and its snapshot matched:** `gh pr diff`.
   - **Otherwise:** `BASE=$(git merge-base <base> HEAD)`, then `git diff $BASE`. Two dots against the working tree, not `git diff <base>...HEAD` — the three-dot form shows committed changes only, which omits exactly the uncommitted work you fell back to review.
   - **Untracked files appear in no `git diff`.** List them with `git ls-files --others --exclude-standard` and treat each as an addition. If there are more than a handful, they're usually scaffolding rather than part of the change: name them in the Context block and include only the ones the change actually touches.
7. Get diff stats from that same source: `gh pr diff --patch | diffstat`-style counts, or `git diff $BASE --stat` plus the untracked additions.
8. **Write the diff to disk, one file per changed file.** `mkdir -p .claude/review-diffs`, create `.claude/review-diffs/.gitignore` containing a single `*` if it isn't there, then for each changed path run `git diff "$BASE" -- <path>` (or `gh pr diff` filtered to that path) into `.claude/review-diffs/<path with / replaced by ->.diff`. Render an untracked file with `git diff --no-index /dev/null <path>`.

   Do this with shell redirection so the diff never passes through your own output. The six reviewer prompts are written in a single message, and a diff inlined into each one is emitted six times from the same response — a moderately large PR exceeds the output limit partway through, so some reviewers never start and the rest have to be sent again. Paths cost a few tokens; the diff costs thousands, six times over.

   One file per changed file also keeps each under the `Read` limit and lets a reviewer skip what its domain doesn't care about. Delete the directory's contents once the review is written.

**Fetch external context (skip gracefully if unavailable):**

- **Linear issue**: Parse the branch name for issue identifiers (patterns like `PROJ-123`, `feat/PROJ-123-description`, `fix/PROJ-123`). If found, fetch via Linear MCP tools — include the issue title, description, and acceptance criteria. If Linear MCP is not available or the branch has no issue ID, skip silently.
- **PR metadata**: If a PR exists, extract the description body and any existing review comments. The review agents should not re-raise issues already flagged by reviewers.

### 2. Explore Codebase (subagent)

Spawn a single `cr-explore` agent. Pass it the list of changed file paths from the diff. It returns a structured context package containing:

1. Paths of all changed files, each with a one-line note on what it is
2. Dependency graph (imports in/out for each changed file)
3. Paths of existing test files for changed modules
4. Repo conventions that bear on the changed files, extracted from CLAUDE.md, READMEs and architecture docs, plus the paths those came from

It returns paths and structure, not file contents. The brief below is pasted into six prompts, so anything inlined here is paid for six times — and each reviewer has `Read` and only needs the files its own domain cares about.

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
- The path to each per-file diff under `.claude/review-diffs/`, paired with the file it describes. Reviewers `Read` the ones their domain cares about. Never inline the diff itself.
- Changed file paths and the dependency graph (from cr-explore)
- Test file paths for the changed modules (from cr-explore)
- The repo conventions digest and the doc paths behind it (from cr-explore)
- Linear issue context (from Step 1, if available)
- PR description and existing review comments (from Step 1, if available)

Reviewers read what they need themselves — both the source files and the diffs. Nothing bulky is inlined here: this brief is written once per reviewer into a single message, so anything it carries is emitted six times from one response, and a large enough brief truncates that message before all six agents have been started.

Each agent returns structured JSON with findings. An empty findings array is a valid, good outcome.

### 4. Merge and Queue (inline)

Do this in the main conversation — you have the full picture and can make judgment calls.

**Severity classification — apply these definitions strictly:**
- **Critical**: Will cause user-facing impact on deploy, breaks the feature, introduces a security vulnerability that's exploitable now, or causes data loss/corruption. If it works today and would only become a problem at significantly higher scale, it's a warning, not a critical.
- **Warning**: Real issues that should be addressed — design concerns, scalability risks, missing validation, gaps that could bite later — but the feature works correctly as deployed.
- **Suggestion**: Minor improvements — readability, consistency, small optimizations. Take it or leave it.

**Priority tier — a second label, from the team's shared punch-list vocabulary:**

| Tier | Meaning |
|------|---------|
| `P0` | Correctness, data loss or security. Wrong behaviour shipped, missing auth, a crash on the golden path. |
| `P1` | Functional bugs in edge cases. Wrong error handling, recoverable-but-broken UX, a type cast hiding a wrong type. |
| `P2` | A documented project convention violated — one the repo actually states, not a preference. |
| `P3` | Wasteful but working. N+1 queries, over-broad invalidation, unnecessary re-renders. |
| `P4` | Polish. Duplicate copy, naming, a missing note on a non-obvious pattern. |

Severity and tier measure different things — consequence versus kind — so they can disagree. **Severity wins.** Apply these floors after picking the tier from the table:

- A `Critical` finding is always `P0`, whatever its kind. An N+1 that times out on today's data breaks on deploy; it is not a P3.
- A `Suggestion` is never above `P3`.
- A `Warning` sits wherever the table puts it, `P1` to `P3`.

If applying a floor moves a finding, the tier was wrong, not the severity.

1. **Merge overlapping findings**: When multiple agents flag the same code location for related reasons, combine into one finding listing all relevant domains. Keep the highest severity, the clearest `problem`/`fix` pair, and the most concrete `verification` block of the ones merged — a single well-specified repro beats two vague ones.
2. **Apply severity definitions**: Re-classify each finding using the definitions above. Agents tend to over-classify — a scalability concern is a warning, not a critical. Be strict.
3. **Assign a priority tier**: Pick it from the table, then apply the floors. Merged findings take the strongest tier of the ones merged.
4. **Assign stable ids**: Number the surviving findings `#1`, `#2`, … ordered by priority tier, then by blast radius — the same key step 6 ranks by, so an id never disagrees with where its finding appears. These ids are what the verifier, the output and the review thread all refer to.
5. **Build the verification queue**: Every finding whose `verification.falsifiable` is true. If `--no-verify` was passed, or the queue is empty, skip the Verify step and treat every finding as `N/A`.

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
2. **Rank**: By priority tier, `P0` first, and within a tier by blast radius: how much breaks, how many callers, how likely it is to be hit. The floors mean this also orders by severity, so one ordered list falls out — not three groups.
3. **Preserve attribution**: Note the domain(s) that raised each finding. It renders after the tier and severity, e.g. `[P0 · Critical · Security, Architecture]`.
4. **Apply the cap**: Keep the top 10. **Criticals are exempt** — if twelve things break on deploy, show all twelve. Refuted findings don't count toward the cap. Anything cut is gone: report the count, never the titles. A list of cut titles rebuilds the wall the cap exists to remove. Skip this step entirely under `--all`.
5. **Check the limits**: The agents now write final-shape prose, so this is a check, not a rewrite. Confirm each `summary` is one line, each `problem` is at most two sentences leading with the symptom, and each `fix` is one imperative sentence naming a concrete thing. Fix any that overrun, and write fresh prose for findings you merged in step 1 — a merged finding has no author. [references/comment-style.md](references/comment-style.md) defines the voice. Leave verification evidence alone: it's raw output and its value is being verbatim.
6. **Store structured findings**: Retain the structured finding data, including verdicts and evidence, for potential draft PR review posting later in the conversation.

### 7. Output

#### Terminal (default)

Produce the formatted review **exactly once** in a single message. Do not emit a preview, partial draft, or example before the final version. Merging, verification and consolidation happen silently — no user-facing text until you write this output.

Every `problem` and `fix` below must satisfy [references/comment-style.md](references/comment-style.md): plain, short, pitched at a competent engineer new to this repo.

**Per-finding format:**

```
**#<id>. <summary>** [<P-tier> · <Severity> · <Domain>, <Domain>]
`<file>:<line-start>-<line-end>`
<problem>
**Fix:** <fix>
**Proven:** <command> → <one-line observation>        (CONFIRMED only)
**Unverified:** <why it couldn't be checked>          (UNVERIFIED only)
```

Findings carry their stable id, which is also their rank order, and are separated by a `---` line. Use the id — never a second, positional numbering — so that a reference anywhere else, in the Refuted block or in the review thread, points at the same finding. Ids may skip where a finding was refuted or cut; that's expected, and the header accounts for both. A `N/A` finding carries neither verification line — that's the normal state for judgement findings, and annotating it would imply something failed.

Where a `CONFIRMED` finding has a repro test attached, put it under the `**Proven:**` line as a fenced block. It's pasteable straight into the fix, which is most of its value.

**Top-level structure:**

```
## Code Review: <branch-name>

### Context
- Branch: <branch> vs <base>
- Linear: <issue-id> — <issue-title>       (omit if no issue)
- PR: #<number> — <title>                  (omit if no PR)
- Files changed: <n> | Additions: <n> | Deletions: <n>
- Diff source: working tree — <why it differs from the PR>   (omit when they match)
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
