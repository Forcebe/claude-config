#!/usr/bin/env bash
# The review handoff contract exists twice: here, as the personal-layer copy,
# and in the tmrw-standards plugin, which supersedes it on the work layer.
# Both live at review-loop/references/handoff-format.md, and review-loop is the
# only skill that reads it, so there is nothing package-specific left in it and
# the two should be identical rather than merely compatible.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
ours="$root/skills/review-loop/references/handoff-format.md"
theirs=$(find "$HOME/.claude/plugins" -path '*tmrw-standards*/review-loop/references/handoff-format.md' 2>/dev/null | head -1)

pass=0
fail=0
check() {
	local name="$1" expected="$2" actual="$3"
	if [[ "$expected" == "$actual" ]]; then
		printf '  ok    %s\n' "$name"; pass=$((pass + 1))
	else
		printf '  FAIL  %s\n        expected: %s\n        actual:   %s\n' "$name" "$expected" "$actual"
		fail=$((fail + 1))
	fi
}

check "the contract sits beside the skill that reads it" "yes" \
	"$([[ -f "$ours" ]] && echo yes || echo no)"
# A cross-skill ../ reference is what made the two layouts differ in the first
# place, and it broke the moment the skill it pointed into was deleted.
check "review-loop does not reach into another skill" "0" \
	"$(grep -c '\.\./[a-z-]*/references' "$root/skills/review-loop/SKILL.md")"
check "nothing references the superseded skills" "0" \
	"$(grep -rl 'self-review\|apply-review' "$root/skills" "$root/agents" 2>/dev/null | wc -l | tr -d ' ')"

if [[ -z "$theirs" ]]; then
	echo "  skip  the plugin is not installed, so there is nothing to diverge from"
else
	check "the two copies are identical" "" "$(diff "$ours" "$theirs" | head -4)"
fi

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
