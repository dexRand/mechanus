#!/usr/bin/env bash
# loop.sh — drive MONOLITH-00 through a list of issues, then wait for CI with no model.
#
# Usage:
#   bin/loop.sh <repo-path> <issue> [<issue> ...]
#   bin/loop.sh /workspace/ctf-docker 42 43 44
#
# Phase 1: MONOLITH-00 works each issue (ASU build -> ARBITER review, L0/L1 only), pushes and
#          opens a PR on a branch named <type>/<issue>-<slug>, without waiting for CI.
# Phase 2: this script waits for every PR's CI (`gh pr checks --watch`: zero tokens; all PRs'
#          CI runs at the same time). On failure it hands MONOLITH only the log tail, so it can
#          send the fix to ASU. At most MAX_CI_ROUNDS fix rounds per issue, then it stops and
#          reports. Green PRs are listed, never merged here.
#
# Env: MODEL (default deepseek/deepseek-v4-pro), MAX_CI_ROUNDS (default 2), LOG_LINES (default 150).
# Needs: opencode, gh (authenticated), git.
set -euo pipefail

repo="${1:?usage: loop.sh <repo-path> <issue>...}"; shift
[ $# -ge 1 ] || { echo "usage: loop.sh <repo-path> <issue>..." >&2; exit 2; }
model="${MODEL:-deepseek/deepseek-v4-pro}"
max_rounds="${MAX_CI_ROUNDS:-2}"
log_lines="${LOG_LINES:-150}"
cd "$repo"

monolith() { opencode run --auto --archived --agent MONOLITH-00 --model "$model" "$1"; }

# PR number for an issue, from the branch naming convention <type>/<issue>-<slug>.
pr_for() {
  gh pr list --state open --json number,headRefName \
    --jq ".[] | select(.headRefName | test(\"/$1-\")) | .number" | head -n1
}

# Tail of the failed CI logs of a PR (only the failing steps).
ci_log_tail() {
  local branch run
  branch=$(gh pr view "$1" --json headRefName --jq .headRefName)
  run=$(gh run list --branch "$branch" --limit 1 --json databaseId --jq '.[0].databaseId')
  gh run view "$run" --log-failed 2>/dev/null | tail -n "$log_lines"
}

# Phase 1: build + review, one issue at a time (MONOLITH does not wait for CI).
for issue in "$@"; do
  echo "=== MONOLITH-00 -> issue #$issue ==="
  monolith "Work issue #$issue with the mechanus skill: brief, ASU-001 build (L0/L1 only), ARBITER review (max 2 rejections, then stop and report), push and open the PR with 'Closes #$issue' on a branch named <type>/$issue-<slug>. Do NOT wait for CI." \
    || { echo "MONOLITH stopped hard on issue #$issue — aborting loop." >&2; exit 1; }
done

# Phase 2: wait for CI (no model), fix rounds on failure.
green=(); stuck=()
for issue in "$@"; do
  pr=$(pr_for "$issue")
  [ -n "$pr" ] || { echo "issue #$issue: no open PR found (stopped or no PR?)"; stuck+=("#$issue"); continue; }
  round=0
  while :; do
    echo "=== CI for issue #$issue (PR #$pr) ==="
    # Right after a push the checks may not exist yet: wait up to 5 minutes for them to appear.
    for _ in $(seq 1 30); do gh pr checks "$pr" 2>&1 | grep -q "no checks reported" || break; sleep 10; done
    if gh pr checks "$pr" 2>&1 | grep -q "no checks reported"; then green+=("#$issue→PR#$pr (no CI configured)"); break; fi
    if gh pr checks "$pr" --watch --fail-fast >/dev/null; then green+=("#$issue→PR#$pr"); break; fi
    round=$((round + 1))
    if [ "$round" -gt "$max_rounds" ]; then stuck+=("#$issue→PR#$pr (CI red after $max_rounds fix rounds)"); break; fi
    tail_log=$(ci_log_tail "$pr")
    monolith "CI failed on PR #$pr for issue #$issue (fix round $round of $max_rounds). Send ASU-001 only what is needed to fix it on the same branch (L0/L1 only), push, do NOT wait for CI. Log tail of the failing steps:
$tail_log" || { stuck+=("#$issue→PR#$pr (MONOLITH stopped)"); break; }
  done
done

echo "Green, ready to merge: ${green[*]:-none}"
echo "Need you: ${stuck[*]:-none}"
