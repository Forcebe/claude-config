#!/usr/bin/env bash
# Phase 6 acceptance criteria from docs/agent-workspace-design.md.
#
# A map is a run, so the mechanics are already covered by phase 2. What is
# checked here is that a map really does reuse that machinery rather than
# inventing a parallel one, and that publishing stays deliberate and unlabelled.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
cw="$root/scripts/cw"
skills="$root/skills"
scratch=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/cw6-XXXXXX")" && pwd -P)

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
has() { grep -qiE "$1" "$skills/wayfinder/SKILL.md" && echo yes || echo no; }

cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT

repo="$scratch/repo"
mkdir -p "$repo"
git -C "$repo" init --quiet
git -C "$repo" remote add origin git@github.com:acme/widget.git
git -C "$repo" commit --quiet --allow-empty -m init
map="$repo/.git/agent-workspace/runs/fog"
mkdir -p "$map/tickets"

# A map with no tracker configured at all: the repo has no sidecar config and
# no .agents/, so cw reports unconfigured. Charting must still work.
cat >"$map/run.md" <<'EOF'
# Find the way

kind: wayfinder
linear:

## Destination

A spec worth building from.

## Decisions so far

## Not yet specified

- how billing interacts with this
EOF
tk() { printf -- '---\nstatus: %s\nblocked-by: %s\ntype: %s\n---\n\n# %s\n' "${4:-open}" "$2" "$3" "$1" >"$map/tickets/$1.md"; }
tk 01-what-counts "" grilling
tk 02-which-api "" research
tk 03-shape-it "01-what-counts 02-which-api" prototype

in_repo() { (cd "$repo" && "$cw" "$@"); }

echo "a map is a run, with no tracker present"
check "the repo really is unconfigured" "unconfigured" "$(in_repo --mode)"
check "the map's frontier works anyway" "01-what-counts 02-which-api" \
	"$(in_repo frontier fog | tr '\n' ' ' | sed 's/ $//')"
check "a map is a fan-out when it starts broad" "fan-out" "$(in_repo shape fog)"
check "claiming a decision ticket works" "01-what-counts" "$(in_repo claim fog 01-what-counts)"
check "a claimed ticket leaves the frontier" "02-which-api" "$(in_repo frontier fog)"
in_repo close fog 01-what-counts
check "closing unblocks nothing until its sibling closes" "02-which-api" "$(in_repo frontier fog)"
in_repo close fog 02-which-api
check "closing both opens the blocked ticket" "03-shape-it" "$(in_repo frontier fog)"
# type is just another header key; cw must neither need nor mind it.
check "the type key survives a close" "grilling" \
	"$(sed -n '4s/^type: //p' "$map/tickets/01-what-counts.md")"

echo
echo "the map stays local until it is published"
check "says a map is local" "yes" "$(has 'a map is local')"
check "publishing is deliberate" "yes" "$(has 'publish deliberately')"
check "publishes no labels" "yes" "$(has 'no labels')"
check "names the wayfinder label as the thing forbidden" "yes" "$(has 'wayfinder:\*.? label would be')"
check "records the issue id back on the run" "yes" "$(has 'record the issue id in .run.md')"

echo
echo "it reuses the run graph rather than inventing one"
check "a map is a run" "yes" "$(has 'a map is a run')"
check "uses cw frontier for open tickets" "yes" "$(has 'cw frontier <slug>')"
check "uses cw close to resolve" "yes" "$(has 'cw close <slug>')"
check "claims before working" "yes" "$(has 'claim it.* before any work')"

echo
echo "it decides rather than delivers"
check "says so explicitly" "yes" "$(has 'decisions, not deliverables')"
check "hands off to to-spec" "yes" "$(has 'to-spec')"
check "one ticket per session, research excepted" "yes" "$(has 'never resolve more than one ticket per session')"
check "human-in-the-loop types cannot be self-answered" "yes" "$(has 'answers its own grilling questions')"

echo
echo "fog"
check "distinguishes fog from a ticket by sharpness" "yes" "$(has 'state the question .*precisely now')"
check "graduated fog lives in exactly one place" "yes" "$(has 'deletes? that patch from|delete that patch')"
check "out of scope is a scoping act, not a step" "yes" "$(has 'scoping act')"

echo
echo "invocation"
check "wayfinder is user-invoked" "yes" \
	"$(grep -q '^disable-model-invocation: true' "$skills/wayfinder/SKILL.md" && echo yes || echo no)"
for s in research prototype grilling domain-modeling; do
	check "$s is reachable from it" "no" \
		"$(grep -q '^disable-model-invocation: true' "$skills/$s/SKILL.md" && echo yes || echo no)"
done

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
