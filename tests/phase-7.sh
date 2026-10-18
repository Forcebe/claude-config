#!/usr/bin/env bash
# Phase 7 acceptance criteria from docs/agent-workspace-design.md.
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

echo "the four skills exist"
for s in retro diagnosing-bugs codebase-design wizard; do
	check "$s" "yes" "$([[ -f "$skills/$s/SKILL.md" ]] && echo yes || echo no)"
done

echo
echo "the references moved out of tdd"
for f in deep-modules interface-design refactoring; do
	check "$f.md is in codebase-design" "yes" \
		"$([[ -f "$skills/codebase-design/$f.md" ]] && echo yes || echo no)"
	check "$f.md is gone from tdd" "no" \
		"$([[ -f "$skills/tdd/$f.md" ]] && echo yes || echo no)"
done
check "tdd reaches them through the Skill tool" "yes" "$(has tdd 'skill tool with "codebase-design"')"
check "tdd has no dangling links to them" "0" \
	"$(grep -cE '\]\((deep-modules|interface-design|refactoring)\.md\)' "$skills/tdd/SKILL.md")"
check "codebase-design links all three" "3" \
	"$(grep -cE '\]\((deep-modules|interface-design|refactoring)\.md\)' "$skills/codebase-design/SKILL.md")"

echo
echo "improve-codebase-architecture scopes before it scans"
check "walks git log for hot spots" "yes" "$(has improve-codebase-architecture 'git log')"
check "scoping comes before exploring" "yes" \
	"$(awk '/^### 1\./{s=NR} /^### 2\. Explore/{e=NR} END{print (s && e && s < e) ? "yes" : "no"}' "$skills/improve-codebase-architecture/SKILL.md")"
check "applies the deletion test" "yes" "$(has improve-codebase-architecture 'deletion test')"
check "uses the codebase-design vocabulary" "yes" "$(has improve-codebase-architecture 'skill tool with "codebase-design"')"
check "step numbering is sequential" "1 2 3 4 5 6 7 8" \
	"$(grep -oE '^### [0-9]+\.' "$skills/improve-codebase-architecture/SKILL.md" | grep -oE '[0-9]+' | tr '\n' ' ' | sed 's/ $//')"

echo
echo "diagnosing-bugs refuses to theorise first"
check "demands a red loop before anything" "yes" "$(has diagnosing-bugs 'do not theorise until')"
check "stops rather than guessing when it cannot build one" "yes" "$(has diagnosing-bugs 'cannot build a loop')"
check "ends with a regression test" "yes" "$(has diagnosing-bugs 'regression test')"
# retro is user-invoked, so this has to be an instruction to the human.
check "hands retro to the user rather than calling it" "yes" "$(has diagnosing-bugs 'tell the user to run .?/retro')"
check "does not call retro through the Skill tool" "no" "$(has diagnosing-bugs 'skill tool with "retro"')"

echo
echo "retro changes the environment, not the code"
check "says so" "yes" "$(has retro 'environment')"
check "proposes rather than applies" "yes" "$(has retro 'a retro proposes')"
check "prefers a check to a written rule" "yes" "$(has retro 'deterministic check, full stop')"
check "puts standards on the reviewer" "yes" "$(has retro 'standards belong on the reviewer')"

echo
echo "wizard is only for what a human must do"
check "says the agent should do what it can" "yes" "$(has wizard 'if the agent could do it')"
check "refuses to invent UI steps" "yes" "$(has wizard 'never invent steps')"
check "does not run it end to end" "yes" "$(has wizard 'do not run it end to end')"

echo
echo "invocation"
check "codebase-design is model-invoked" "no" \
	"$(grep -q '^disable-model-invocation: true' "$skills/codebase-design/SKILL.md" && echo yes || echo no)"
for s in retro diagnosing-bugs wizard; do
	check "$s is user-invoked" "yes" \
		"$(grep -q '^disable-model-invocation: true' "$skills/$s/SKILL.md" && echo yes || echo no)"
done

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
