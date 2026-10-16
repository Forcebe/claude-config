#!/usr/bin/env bash
# Phase 1 acceptance criteria from docs/agent-workspace-design.md.
# Re-run at the end of every later phase, not just this one.
#
# Builds a throwaway repo rather than testing against this one, so the results
# never depend on how this repo happens to be configured.
set -uo pipefail

cw="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)/scripts/cw"

# Canonicalised, because macOS hands back /var paths that git reports as
# /private/var, and $TMPDIR carries a trailing slash.
export CLAUDE_WORKSPACE_ROOT
CLAUDE_WORKSPACE_ROOT=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/cw-test-XXXXXX")" && pwd -P)
scratch=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/cw-repo-XXXXXX")" && pwd -P)

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

cleanup() { rm -rf "$scratch" "$CLAUDE_WORKSPACE_ROOT"; }
trap cleanup EXIT

repo="$scratch/repo"
mkdir -p "$repo"
git -C "$repo" init --quiet
git -C "$repo" remote add origin git@github.com:acme/widget.git
git -C "$repo" commit --quiet --allow-empty -m "init"
git -C "$repo" worktree add --quiet --detach "$scratch/wt-a" HEAD 2>/dev/null

in_repo() { (cd "$repo" && "$cw" "$@"); }
in_wt() { (cd "$scratch/wt-a" && "$cw" "$@"); }

sidecar="$CLAUDE_WORKSPACE_ROOT/acme--widget"

echo "identity"
check "derives the key from origin" "acme--widget" "$(in_repo --key)"
check "same key from a worktree" "acme--widget" "$(in_wt --key)"
check "same repo root from a worktree" "$repo" "$(in_wt --repo)"
check "same sidecar from a worktree" "$sidecar" "$(in_wt --sidecar)"

echo
echo "run state"
check "lives in the shared git dir" "$repo/.git/agent-workspace" "$(in_repo --state)"
check "identical from a worktree" "$repo/.git/agent-workspace" "$(in_wt --state)"
mkdir -p "$(in_repo --state)" && touch "$(in_repo --state)/probe"
check "is invisible to git status" "" "$(git -C "$repo" status --porcelain)"

echo
echo "storage mode"
check "unconfigured before setup" "unconfigured" "$(in_repo --mode)"
check "unconfigured resolves to the sidecar" "$sidecar" "$(in_repo)"

mkdir -p "$sidecar" && echo "# config" >"$sidecar/config.md"
check "a sidecar config means sidecar mode" "sidecar" "$(in_repo --mode)"
check "sidecar mode resolves to the sidecar" "$sidecar" "$(in_repo)"
check "sidecar docs are shared across worktrees" "$sidecar" "$(in_wt)"

rm "$sidecar/config.md"
mkdir -p "$repo/.agents" && echo "# config" >"$repo/.agents/config.md"
check "a repo config means in-repo mode" "in-repo" "$(in_repo --mode)"
check "in-repo mode resolves to .agents" "$repo/.agents" "$(in_repo)"

# .agents is tracked content, so a worktree only sees it once it is committed.
check "an uncommitted .agents does not reach a worktree" "unconfigured" "$(in_wt --mode)"
git -C "$repo" add -A .agents && git -C "$repo" commit --quiet -m "agents"
git -C "$repo" worktree add --quiet --detach "$scratch/wt-b" HEAD 2>/dev/null
check "a committed .agents does reach a worktree" "in-repo" "$(cd "$scratch/wt-b" && "$cw" --mode)"
check "in-repo docs are per-worktree" "$scratch/wt-b/.agents" "$(cd "$scratch/wt-b" && "$cw")"

# The repo is the surface we must never write to by accident, so ambiguity
# has to resolve away from it.
echo "# config" >"$sidecar/config.md"
check "a sidecar config wins over a repo one" "sidecar" "$(in_repo --mode)"

echo
echo "errors"
(cd "${TMPDIR:-/tmp}" && "$cw" >/dev/null 2>&1)
check "exits non-zero outside a git repository" "1" "$?"
in_repo --bogus >/dev/null 2>&1
check "rejects an unknown option" "1" "$?"

echo
echo "wt-add (manual — needs tmux and a real worktree)"
cat <<'EOF'
  Note the attached client's session first (tmux list-clients -F
  '#{client_session}') and compare after each step. Run plain wt-add as
  `env -u TMUX wt-add ...`: with TMUX set it calls switch-client and moves
  your view, and without it the attach fails harmlessly on the missing tty
  once everything else has already happened.

  [ ] wt-add --help lists --no-attach
  [ ] wt-add --no-attach <branch> creates the worktree and the session,
      and leaves the attached client where it was
  [ ] cw --state from inside the new worktree resolves to the main
      checkout's .git/agent-workspace
  [ ] cw --mode in a new worktree reports unconfigured until .agents/
      is committed
  [ ] env -u TMUX wt-add <branch> does the same, failing only at the attach
  [ ] wt-rm removes both worktrees and sessions, and a file written under
      cw --state survives
EOF

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
