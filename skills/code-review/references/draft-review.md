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

Write comments like a thoughtful colleague, not a linter. They should be conversational and to the point — the kind of comment you'd actually leave in a PR review. Do NOT copy the structured terminal output verbatim. Instead, rewrite each finding naturally.

**Bad (robotic):**
```
**[Warning] [Performance] Repository queries fetch all columns including large JSONB metadata**

`db.select()` retrieves all columns — the `metadata` JSONB column can contain large encrypted payloads...

**Recommendation:** Project only needed columns...
```

**Good (human):**
```
This fetches all columns including the `metadata` JSONB, which can be pretty hefty — but we only use `status`, `provider`, `updatedAt`, and a quick check on `metadata.formulationDetails`. Worth projecting just the columns we need, similar to how `getArtifactMetadataByClientIds` does it.
```

The severity and domain info can go in a small tag at the start if helpful (e.g., `*[warning — performance]*`), but the body should read naturally. Keep each comment focused on one thing and short enough that the reviewer doesn't have to scroll.

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
