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

**5 warnings, 5 suggestions** — no critical issues.

### Key themes
- The in-memory enrichment pattern works now but will need a DB-layer follow-up as member counts grow
- New sorting/filtering/search logic has no test coverage yet
- A few type safety gaps where validated values are re-cast or raw JSONB is accessed untyped

### Additional notes
(Include here any findings that don't attach to a specific line in the diff)
```

## Inline Comment Tone

Write each comment in the voice defined in [comment-style.md](comment-style.md): plain, short, one point per comment, pitched at a competent engineer new to this repo. Do NOT copy the structured terminal output verbatim — rewrite each finding as flowing prose. An inline comment is already attached to a line, so drop the `file:line` reference and the `**Recommendation:**` label; fold the fix into the same sentences.

**From this terminal finding:**
```
**[Performance] Repository queries fetch all columns including large JSONB metadata**
`db/artifacts.ts:42`
This selects every column, including the `metadata` JSONB which can be large...
**Recommendation:** Select only `status`, `provider`, and `updatedAt`...
```

**To this inline comment:**
```
This selects every column, including the `metadata` JSONB which can be large. The code only reads `status`, `provider`, and `updatedAt`, so selecting just those avoids loading data we never use. `getArtifactMetadataByClientIds` already does it this way.
```

The severity and domain can go in a small tag at the start if helpful (e.g., `*[warning — performance]*`), but the body should read as prose.

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
