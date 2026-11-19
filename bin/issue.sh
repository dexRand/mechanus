#!/usr/bin/env bash
# issue.sh — run MONOLITH-00 on one issue.
#
# Usage:
#   bin/issue.sh <repo-path> <issue>
#   bin/issue.sh /workspace/ctf-docker "fix the sqlite pragma escape"
#
set -euo pipefail

repo="${1:?usage: issue.sh <repo-path> <issue>}"; shift
issue="$*"

cd "$repo"
exec opencode run --auto --archived --agent MONOLITH-00 --model deepseek/deepseek-v4-pro \
  "Work this issue with the mechanus skill: $issue"
