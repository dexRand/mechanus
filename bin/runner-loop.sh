#!/usr/bin/env bash
# runner-loop.sh — one ephemeral GitHub Actions runner, forever (started by gh-runner@.service).
#
# Usage: runner-loop.sh <owner>--<repo>--<n>     e.g. dexRand--myapp--1
# Needs GH_PAT in the environment (root-only /etc/gh-runner.env). Runs as root only to read the
# token and mint registration tokens; the job itself runs as the unprivileged user `runner`.
set -euo pipefail

inst="${1:?usage: runner-loop.sh <owner>--<repo>--<n>}"
owner="${inst%%--*}"; rest="${inst#*--}"; repo="${rest%--*}"
: "${GH_PAT:?GH_PAT missing (put it in /etc/gh-runner.env)}"
dir="/opt/runners/$inst"
api="https://api.github.com/repos/$owner/$repo/actions/runners/registration-token"

# Fresh directory every time: no leftovers from the previous job.
rm -rf "$dir"
mkdir -p "$dir"
cp -a /opt/actions-runner-dist/. "$dir/"
chown -R runner:runner "$dir"

token=$(curl -fsSL -X POST -H "Authorization: Bearer $GH_PAT" -H "Accept: application/vnd.github+json" "$api" | jq -r .token)
[ -n "$token" ] && [ "$token" != null ] || { echo "no registration token for $owner/$repo" >&2; exit 1; }

cd "$dir"
sudo -u runner ./config.sh --unattended --ephemeral --replace \
  --url "https://github.com/$owner/$repo" --token "$token" \
  --name "$(hostname)-$inst" --labels gate --work _work
unset token GH_PAT

# Runs exactly one job, then exits; systemd restarts this script for the next one.
exec sudo -u runner ./run.sh
