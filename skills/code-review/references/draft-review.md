# Draft PR Review Guide

Instructions for posting review findings as a pending GitHub PR review with inline comments.

## API Details

1. **Build a single JSON file** containing the full request body — do NOT mix `--field` and `--input` with `gh api`.
2. **Omit the `event` field entirely** — this creates a pending/draft review. Do NOT use `event: "PENDING"` (invalid value for the REST API).
3. **Inline comments** must reference lines that exist in the diff. Use `side: "RIGHT"` for lines in the new version.
4. **Findings that don't map to a specific diff line** (e.g., missing index suggestions, test coverage gaps) go in the review body instead of as inline comments.

## Review Body

The `body` field is the top-level review summary that appears above all inline comments. Write it as a brief, human-readable overview:

```markdown
## Code Review

Reviewed across architecture, security, correctness, testing, performance, and readability.

**5 warnings, 5 suggestions** — no critical issues. (Add `· 3 cut for length` when the cap trimmed anything.)

### Key themes
- The in-memory enrichment pattern works now but will need a DB-layer follow-up as member counts grow
- New sorting/filtering/search logic has no test coverage yet
- A few type safety gaps where validated values are re-cast or raw JSONB is accessed untyped

### Additional notes
(Include here any findings that don't attach to a specific line in the diff)
```

## Inline Comment Tone

Write each comment in the voice defined in [comment-style.md](comment-style.md): plain, short, one point per comment, pitched at a competent engineer new to this repo. An inline comment is already attached to a line, so drop the `summary`, the `file:line` reference and the `**Fix:**` label — run the `problem` and `fix` together as flowing prose. They're already one or two sentences each, so this is mostly joining them, not rewriting.

The 10-item cap applies here too: post exactly the findings the terminal review showed, so the PR never carries a comment you didn't read. Under `--all`, post everything.

**From this terminal finding:**
```
**3. Query loads a large JSONB nobody reads** [Warning · Performance]
`db/artifacts.ts:42-47`
This selects every column, including the large `metadata` JSONB, but the code only reads `status`, `provider` and `updatedAt`.
**Fix:** Select just those three — `getArtifactMetadataByClientIds` already does it this way.
```

**To this inline comment:**
```
This selects every column, including the large `metadata` JSONB, but the code only reads `status`, `provider` and `updatedAt`. Select just those three — `getArtifactMetadataByClientIds` already does it this way.
```

The severity and domain can go in a small tag at the start if helpful (e.g., `*[Warning · Performance]*`), but the body should read as prose.

## Posting

```bash
# 1. Build the review JSON
cat > /tmp/cr-review.json << 'EOF'
{
  "body": "<review summary>",
  "comments": [
    {
      "path": "src/path/to/file.ts",
      "line": 65,
      "side": "RIGHT",
      "body": "<conversational comment>"
    }
  ]
}
EOF

# 2. Post it
gh api repos/{owner}/{repo}/pulls/{pull_number}/reviews \
  --method POST \
  --input /tmp/cr-review.json
```

When posting after a terminal review, use the stored structured findings but rewrite them in the conversational tone described above. Do not re-run the review agents.

After posting, confirm with the PR URL:
```
Draft review created on PR #<number> with <n> inline comments. Open the PR in GitHub to review and submit:
<pr-url>
```
