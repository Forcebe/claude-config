#!/usr/bin/env bash
# Phase 5 acceptance criteria from docs/agent-workspace-design.md.
# cw shape is real logic and is tested against known graphs; the skills are
# prose, so those checks are that the prose says what the constraints require.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
cw="$root/scripts/cw"
skills="$root/skills"
scratch=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/cw5-XXXXXX")" && pwd -P)

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

cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT

repo="$scratch/repo"
mkdir -p "$repo"
git -C "$repo" init --quiet
git -C "$repo" remote add origin git@github.com:acme/widget.git
git -C "$repo" commit --quiet --allow-empty -m init
state="$repo/.git/agent-workspace/runs"

mkrun() { mkdir -p "$state/$1/tickets"; }
tk() { printf -- '---\nstatus: %s\nblocked-by: %s\n---\n\n# %s\n' "${3:-open}" "$2" "$1" >"$state/$run/tickets/$1.md"; }
shape() { (cd "$repo" && "$cw" shape "$1"); }

echo "shape"
run="chain"; mkrun $run; tk 01-a ""; tk 02-b "01-a"; tk 03-c "02-b"
check "a single path is a chain" "chain" "$(shape chain)"
run="one"; mkrun $run; tk 01-a ""
check "a lone ticket is a chain" "chain" "$(shape one)"
run="split"; mkrun $run; tk 01-a ""; tk 02-b "01-a"; tk 03-c "01-a"
check "one ticket gating two is a fan-out" "fan-out" "$(shape split)"
run="merge"; mkrun $run; tk 01-a ""; tk 02-b ""; tk 03-c "01-a 02-b"
check "two tickets gating one is a fan-out" "fan-out" "$(shape merge)"
run="roots"; mkrun $run; tk 01-a ""; tk 02-b ""
check "two independent tickets are a fan-out" "fan-out" "$(shape roots)"
# A chain that has been partly worked is still a chain: shape is about the
# edges, not about progress.
run="part"; mkrun $run; tk 01-a "" "done"; tk 02-b "01-a"; tk 03-c "02-b"
check "progress does not change the shape" "chain" "$(shape part)"

echo
echo "implement claims before it builds"
check "claims first" "yes" "$(has implement 'claim before anything else')"
check "stops when the claim fails" "yes" "$(has implement 'another session holds it')"
check "builds through tdd" "yes" "$(has implement 'skill tool with "tdd"')"
check "uses the spec's seams" "yes" "$(has implement 'seams the spec already sketched')"
check "reviews through review-loop" "yes" "$(has implement 'skill tool with "review-loop"')"
check "closes, which releases" "yes" "$(has implement 'cw close')"
check "records the branch on the ticket" "yes" "$(has implement 'branch:. header')"
check "passes the stack parent to wt-add" "yes" "$(has implement 'wt-add <branch> <stack-parent-branch>')"

echo
echo "implement-spec picks its mode from the graph"
check "asks cw shape" "yes" "$(has implement-spec 'cw shape')"
check "chain means stack mode" "yes" "$(has implement-spec 'chain.*stack mode')"
check "fan-out means integration mode" "yes" "$(has implement-spec 'fan-out.*integration mode')"
check "does not switch modes silently" "yes" "$(has implement-spec 'do not override silently')"
check "works the frontier in a loop" "yes" "$(has implement-spec 'cw frontier <run>. is empty')"
check "reviews the whole thing at the end" "yes" "$(has implement-spec 'skill tool with "code-review"')"
check "cleans up its worktrees" "yes" "$(has implement-spec 'wt-rm')"
# The finding from phase 3's worktree test: an AFK agent cannot answer a prompt.
check "warns that subagents need cw permitted" "yes" "$(has implement-spec 'permission allowlist')"

echo
echo "neither leaks to Linear"
check "implement-spec keeps publishing deliberate" "yes" "$(has implement-spec 'separate, deliberate act')"
check "implement does not assume a PR" "yes" "$(has implement 'offer it, do not assume')"

echo
echo "invocation"
check "implement-spec is user-invoked" "yes" \
	"$(grep -q '^disable-model-invocation: true' "$skills/implement-spec/SKILL.md" && echo yes || echo no)"
# Forced by the invariant, not chosen: implement-spec dispatches each ticket to
# implement through the Skill tool, and a user-invoked skill cannot be reached
# that way.
check "implement is model-invoked, because implement-spec calls it" "no" \
	"$(grep -q '^disable-model-invocation: true' "$skills/implement/SKILL.md" && echo yes || echo no)"

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
