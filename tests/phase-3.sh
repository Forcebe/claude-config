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

	# The review skills spawn these by bare name. Plugin agents surface under a
	# "plugin:name" prefix, so the plugin's copies are not substitutes: drop
	# these from the deploy and the review skills lose their subagents.
	agents="$HOME/.claude/agents"
	missing_agents=""
	for a in "$root"/agents/*.md; do
		n=$(basename "$a")
		[[ -e "$agents/$n" ]] || missing_agents+="$n "
	done
	check "every cr-* agent is deployed, on any layer" "" "${missing_agents% }"

	# Every skill in the repo that is not deliberately excluded should be there.
	undeployed=""
	for d in "$skills"/*/; do
		n=$(basename "$d")
		[[ "$n" == "code-review" || "$n" == "review-loop" ]] && continue
		[[ -e "$deployed/$n" ]] || undeployed+="$n "
	done
	check "every other skill is deployed" "" "${undeployed% }"
else
	echo "  skip  ~/.claude/skills is not deployed as a directory"
fi

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
