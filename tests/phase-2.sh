#!/usr/bin/env bash
# Phase 2 acceptance criteria from docs/agent-workspace-design.md.
# Builds a throwaway repo, so results never depend on this one's state.
set -uo pipefail

cw="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)/scripts/cw"
scratch=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/cw2-XXXXXX")" && pwd -P)

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

cleanup() {
	tmux kill-session -t "$sess" 2>/dev/null
	rm -rf "$scratch"
}
trap cleanup EXIT

repo="$scratch/repo"
mkdir -p "$repo"
git -C "$repo" init --quiet
git -C "$repo" remote add origin git@github.com:acme/widget.git
git -C "$repo" commit --quiet --allow-empty -m init
git -C "$repo" worktree add --quiet -b feature-a "$scratch/wt-a" 2>/dev/null
git -C "$repo" worktree add --quiet -b feature-b "$scratch/wt-b" 2>/dev/null
sess=$(basename "$scratch/wt-a" | tr ".,: " "____")

in_repo() { (cd "$repo" && "$cw" "$@"); }
in_a() { (cd "$scratch/wt-a" && "$cw" "$@"); }
in_b() { (cd "$scratch/wt-b" && "$cw" "$@"); }

run="$(in_repo --state)/runs/demo"
mkdir -p "$run/tickets"
ticket() {
	cat >"$run/tickets/$1.md" <<EOF
---
status: $2
blocked-by: $3
---

# $1
EOF
}
ticket 01-first open ""
ticket 02-second open "01-first"
ticket 03-third open "02-second"

echo "frontier"
check "a chain exposes exactly one frontier ticket" "01-first" "$(in_repo frontier demo)"

echo
echo "claims"
check "claiming from worktree A succeeds" "01-first" "$(in_a claim demo 01-first)"
in_b claim demo 01-first >/dev/null 2>&1
check "claiming the same ticket from worktree B fails" "1" "$?"
check "a claimed ticket leaves the frontier" "" "$(in_repo frontier demo)"
check "the holder records the claiming worktree" "worktree: $scratch/wt-a" \
	"$(grep '^worktree:' "$run/claims/01-first/holder")"
in_a release demo 01-first
check "releasing puts it back on the frontier" "01-first" "$(in_repo frontier demo)"

echo
echo "progress"
in_a claim demo 01-first >/dev/null
in_a close demo 01-first
check "closing a blocker moves the next ticket up" "02-second" "$(in_repo frontier demo)"
check "done releases the claim too" "no" "$([[ -d "$run/claims/01-first" ]] && echo yes || echo no)"
check "a done ticket is not on the frontier" "02-second" "$(in_repo frontier demo)"

echo
echo "status"
in_b claim demo 02-second >/dev/null
check "lists every live worktree" "3" "$(in_repo status | tail -n +2 | wc -l | tr -d ' ')"
check "shows the worktree's branch" "feature-b" \
	"$(in_repo status | awk '$1 ~ /wt-b/ {print $2}')"
check "shows the claim against its worktree" "demo/02-second" \
	"$(in_repo status | awk '$1 ~ /wt-b/ {print $4}')"
check "shows no claim for an unclaimed worktree" "-" \
	"$(in_repo status | awk '$1 ~ /wt-a/ {print $4}')"

if command -v tmux >/dev/null 2>&1; then
	check "a worktree with no session reads as -" "-" \
		"$(in_repo status | awk '$1 ~ /wt-a/ {print $3}')"
	tmux new-session -ds "$sess" -c "$scratch/wt-a" 2>/dev/null
	check "a running session reads as live" "live" \
		"$(in_repo status | awk '$1 ~ /wt-a/ {print $3}')"
	# Proves the column is derived at read time rather than stored.
	tmux kill-session -t "$sess" 2>/dev/null
	check "killing the session removes it from the output" "-" \
		"$(in_repo status | awk '$1 ~ /wt-a/ {print $3}')"
else
	echo "  skip  tmux not available"
fi

echo
echo "session context hook"
ctx=$(cd "$scratch/wt-a" && "$(dirname "$cw")/session-context")
check "names the other worktree's branch" "yes" \
	"$(grep -q 'feature-b' <<<"$ctx" && echo yes || echo no)"
check "names what that worktree holds" "yes" \
	"$(grep -q 'demo/02-second' <<<"$ctx" && echo yes || echo no)"
check "emits valid JSON" "yes" \
	"$(python3 -c 'import json,sys; json.load(sys.stdin)' <<<"$ctx" 2>/dev/null && echo yes || echo no)"
check "says nothing outside a git repo" "" \
	"$(cd "${TMPDIR:-/tmp}" && "$(dirname "$cw")/session-context" 2>/dev/null)"

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
