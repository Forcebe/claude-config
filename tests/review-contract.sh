#!/usr/bin/env bash
# The writer↔reviewer contract exists twice: here, and in the tmrw-standards
# plugin. On the work layer the writer half (self-review, apply-review) comes
# from this repo and the reviewer half (review-loop) from the plugin, so the
# two copies have to agree or the loop breaks mid-negotiation.
#
# They are allowed to differ in prose — the plugin does not ship self-review or
# apply-review, so it cannot name them. They may not differ in FORMAT.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
ours="$root/skills/self-review/references/handoff-format.md"
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

check "our copy exists" "yes" "$([[ -f "$ours" ]] && echo yes || echo no)"

if [[ -z "$theirs" ]]; then
	echo "  skip  the plugin is not installed, so there is nothing to diverge from"
else
	# Headings, state tokens and field names are the format. Prose is not.
	# shellcheck disable=SC2016  # the backticks are literal, not substitutions
	structure() { grep -oE '^#{1,4} .*|^\*\*[A-Z]+\*\*|^- `[A-Z_]+`|\b[A-Z]{4,}\b' "$1" | sort -u; }
	check "the two copies share one format" "" "$(diff <(structure "$ours") <(structure "$theirs") | grep '^[<>]' | head -4)"

	# The thread file location is the one thing that silently breaks the loop:
	# the halves would read and write different files and never see each other.
	# shellcheck disable=SC2016  # ditto
	loc() { sed -n '/^## Location/,/^##/p' "$1" | grep -oE '`\.claude/reviews/[^`]*`' | head -1; }
	check "both resolve the thread to the same path" "$(loc "$ours")" "$(loc "$theirs")"
fi

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
