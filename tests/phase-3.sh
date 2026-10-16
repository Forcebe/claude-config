#!/usr/bin/env bash
# Phase 3 acceptance criteria from docs/agent-workspace-design.md.
# Checks the invocation split structurally: the invariant it rests on is that
# a user-invoked skill can never be reached by another skill.
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

is_user_invoked() { grep -q '^disable-model-invocation: true' "$skills/$1/SKILL.md" 2>/dev/null; }
exists() { [[ -f "$skills/$1/SKILL.md" ]]; }

echo "the invariant"
# Every skill named to the Skill tool must be reachable by a model. A
# user-invoked one cannot be, so naming it is a dead instruction.
violations=""
while IFS= read -r called; do
	exists "$called" || continue
	is_user_invoked "$called" && violations+="$called "
done < <(grep -rhoE 'Skill tool [^.]*"[a-z-]+"' "$skills" | grep -oE '"[a-z-]+"' | tr -d '"' | sort -u)
check "no skill calls a user-invoked skill" "" "${violations% }"

# The other half: anything a skill calls must actually exist.
missing=""
while IFS= read -r called; do
	exists "$called" || missing+="$called "
done < <(grep -rhoE 'Skill tool [^.]*"[a-z-]+"' "$skills" | grep -oE '"[a-z-]+"' | tr -d '"' | sort -u)
check "every called skill exists" "" "${missing% }"

echo
echo "the primitives are reachable"
for s in grilling domain-modeling research tdd prototype; do
	check "$s is model-invoked" "model" \
		"$(exists "$s" && { is_user_invoked "$s" && echo user || echo model; } || echo MISSING)"
done

echo
echo "the entry points are not"
for s in grill-me grill-with-docs grill-issue to-spec to-tickets setup-workspace handoff; do
	check "$s is user-invoked" "user" \
		"$(exists "$s" && { is_user_invoked "$s" && echo user || echo model; } || echo MISSING)"
done

echo
echo "descriptions match their audience"
# A user-invoked description is read by a human browsing slash-commands, so the
# model-facing trigger lists are noise there.
triggery=""
for d in "$skills"/*/; do
	s=$(basename "$d")
	is_user_invoked "$s" || continue
	grep -qiE '^description:.*(use when|triggers on|this skill should be used)' "$d/SKILL.md" && triggery+="$s "
done
check "no user-invoked skill keeps a trigger list" "" "${triggery% }"

echo
echo "deployment"
deployed="$HOME/.claude/skills"
if [[ -d "$deployed" && ! -L "$deployed" ]]; then
	check "the skills dir is a directory of links" "yes" "yes"
	dupes=""
	plugin="$HOME/.claude/plugins/marketplaces/tmrw-tools/plugins/tmrw-standards/skills"
	if [[ -d "$plugin" ]]; then
		for p in "$plugin"/*/; do
			n=$(basename "$p")
			[[ -e "$deployed/$n" ]] && dupes+="$n "
		done
	fi
	check "no skill name resolves to two definitions" "" "${dupes% }"
else
	echo "  skip  ~/.claude/skills is not deployed as a directory"
fi

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
