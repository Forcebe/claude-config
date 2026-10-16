#!/usr/bin/env bash
# Phase 4 acceptance criteria from docs/agent-workspace-design.md.
#
# The spec pipeline is prose a model follows, so most of this checks that the
# instructions say the right thing and contradict neither each other nor the
# constraints. The run-graph mechanics they rely on are covered by phase 2.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
skills="$root/skills"

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
has() { grep -qiE "$2" "$skills/$1/SKILL.md" && echo yes || echo no; }

echo "nothing leaks to Linear"
# The constraint that matters most: no skill may apply a workflow label, and
# every one that can touch Linear must say publishing is deliberate.
labelled=""
for s in to-spec to-tickets triage; do
	grep -qE '^[^>]*[Aa]pply the .*(ready-for-agent|triage) label' "$skills/$s/SKILL.md" && labelled+="$s "
done
check "no skill applies a workflow label" "" "${labelled% }"
check "to-spec says publishing is a separate act" "yes" "$(has to-spec 'separate, deliberate act')"
check "to-tickets writes nothing to Linear" "yes" "$(has to-tickets 'write nothing to linear')"
check "triage keeps its states local" "yes" "$(has triage 'nothing about triage is written to linear')"

echo
echo "the pipeline writes to the run graph"
check "to-spec saves the spec under the run" "yes" "$(has to-spec 'cw --state.*/runs/')"
check "to-spec does not save to the repo root" "yes" "$(has to-spec 'not the repo root')"
check "to-tickets writes one file per ticket" "yes" "$(has to-tickets 'runs/<slug>/tickets/')"
check "to-tickets verifies its own edges" "yes" "$(has to-tickets 'cw frontier')"
check "to-tickets sets stack-parent for a chain" "yes" "$(has to-tickets 'stack-parent')"

echo
echo "tdd speaks the seam vocabulary"
check "tdd defines a seam" "yes" "$(has tdd 'a \*\*seam\*\* is')"
check "tdd requires pre-agreed seams" "yes" "$(has tdd 'pre-agreed seams')"
check "tdd defers to the spec's seams" "yes" "$(has tdd 'to-spec. already sketches the seams')"
check "tdd covers tautological tests" "yes" "$(has tdd 'tautological')"
check "tests.md has a worked tautological example" "yes" \
	"$(grep -qi 'tautological' "$skills/tdd/tests.md" && echo yes || echo no)"
check "the per-cycle checklist gates the seam" "yes" "$(has tdd 'seam is one the user agreed to')"

# to-spec sketches seams and tdd consumes them; if they drifted apart the
# handoff between the two would be a word nobody on the receiving end knows.
echo
echo "the two ends of the handoff agree"
for term in 'existing seams' 'highest seam'; do
	check "both use \"$term\"" "yes" \
		"$(grep -qi "$term" "$skills/to-spec/SKILL.md" && grep -qi "$term" "$skills/tdd/SKILL.md" && echo yes || echo no)"
done

echo
echo "invocation"
for s in to-spec to-tickets triage; do
	check "$s is user-invoked" "yes" \
		"$(grep -q '^disable-model-invocation: true' "$skills/$s/SKILL.md" && echo yes || echo no)"
done
check "triage reaches grilling through the Skill tool" "yes" "$(has triage 'skill tool twice')"

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
