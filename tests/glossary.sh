#!/usr/bin/env bash
# Glossary enforcement, which is cross-cutting rather than tied to a phase.
# it drifts: three separate review passes caught a synonym creeping back in.
# Each "Not:" line in the glossary is a rejected synonym, checked here.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
glossary="$root/.agents/workspace/GLOSSARY.md"

pass=0
fail=0
check() {
	local name="$1" expected="$2" actual="$3"
	if [[ "$expected" == "$actual" ]]; then
		printf '  ok    %s\n' "$name"
		pass=$((pass + 1))
	else
		printf '  FAIL  %s\n        expected: %s\n        actual:   %s\n' "$name" "$expected" "$actual"
		fail=$((fail + 1))
	fi
}

# Prose the agents read. The glossary itself is excluded: it has to name the
# rejected synonyms in order to reject them. A line carrying an inline
# <!-- glossary-exempt --> is skipped too, for the handful of places that
# record a term having been wrong. The marker is greppable on purpose.
corpus() {
	grep -rniE "$1" "$root/skills" "$root/docs" "$root/README.md" "$root/.agents" 2>/dev/null |
		grep -v 'GLOSSARY.md' |
		grep -v 'glossary-exempt' || true
}

echo "the glossary exists where cw says it should"
check "GLOSSARY.md is at the docs root" "yes" "$([[ -f "$glossary" ]] && echo yes || echo no)"
check "cw resolves to that directory" "$(dirname "$glossary")" "$(cd "$root" && ./scripts/cw)"

echo
echo "rejected synonyms stay rejected"
check "no \"task graph\"" "" "$(corpus '\btask graph\b' | head -3)"
check "no \"work item\"" "" "$(corpus '\bwork items?\b' | head -3)"
# "ticket" now means a Linear issue and nothing else. The local unit is a slice.
check "the local unit is never called a ticket" "" \
	"$(corpus 'slices?/|cw (claim|close|frontier)' | grep -i ticket | head -3)"
check "no \"workspace root\"" "" "$(corpus '\bworkspace root\b' | head -3)"

# "issue" is legitimate for Linear issues, and "PRD" for the team's Slite doc.
# What must not happen is either standing in for a slice or a spec. Only the
# structural words are checked: "issue id" is a perfectly good Linear id, so a
# looser pattern would cry wolf and teach us to ignore this suite.
check "no slice called an issue" "" \
	"$(corpus 'issue (file|header|slug)|issues/ |per issue\b|issue'"'"'s blocking' | head -3)"
check "no spec called a PRD" "" \
	"$(corpus 'from the PRD|the PRD (template|file)|write the PRD' | head -3)"

echo
echo "the run graph is only ever said to live in one place"
check "nothing puts it under the docs root" "" \
	"$(corpus 'run graph under the docs root' | head -3)"

# One term, one definition. codebase-design is a vocabulary reference and
# restates several terms; only "seam" is also in the glossary, so that is the
# one that can drift apart from it.
echo
echo "overlapping terms have one definition"
flat() { tr '\n' ' ' <"$1"; }
check "seam reads the same in both" "1" \
	"$(flat "$glossary" | grep -c 'observed or altered without editing in that place')"
check "codebase-design points at the glossary for it" "1" \
	"$(flat "$root/skills/codebase-design/SKILL.md" | grep -c 'canonically defined in .GLOSSARY.md')"

echo
echo "every defined term is actually used"
unused=""
while IFS= read -r term; do
	[[ -z "$term" ]] && continue
	corpus "\\b${term}\\b" | grep -q . || unused+="$term; "
done < <(grep -E '^## ' "$glossary" | sed 's/^## //' | grep -v '/')
check "no term defined but never used" "" "${unused%; }"

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
