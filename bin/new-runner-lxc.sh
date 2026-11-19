#!/usr/bin/env bash
# new-runner-lxc.sh — provision a GitHub Actions runner LXC for the L2 gate of PRIVATE repos.
#
# Target: a fresh Ubuntu LXC on Proxmox, SEPARATE from the MECHANUS LXC (that one holds the
# provider keys and the GitHub token; test code must never see them). Unprivileged is fine
# unless the tests need Docker (then: nesting=1, and know that docker group = root on the box).
# RAM/CPU: what the heaviest gate needs, times the shards you run in parallel, plus margin.
#
# Run INSIDE the LXC as root:
#   bin/new-runner-lxc.sh                        # once: deps, user, runner binaries, unit
#   echo 'GH_PAT=github_pat_...' > /etc/gh-runner.env && chmod 600 /etc/gh-runner.env
#   systemctl enable --now gh-runner@<owner>--<repo>--1   # one instance per parallel shard
#   systemctl enable --now gh-runner@<owner>--<repo>--2
#
# GH_PAT: fine-grained token limited to the private repos that use the gate, permission
# "Administration: Read and write" (needed to mint runner registration tokens). It stays in a
# root-only file; jobs run as the unprivileged user `runner` and cannot read it.
#
# Each instance registers as an EPHEMERAL runner (one job, then it unregisters), wipes its
# workspace, and registers again: every job starts clean.
set -euo pipefail

# --- 1. Base tools (add here what your gates need: node, php, python, …) ------
apt-get update -qq
apt-get install -y -qq curl jq git ca-certificates tar sudo

# --- 2. Unprivileged user for the jobs -----------------------------------------
id runner >/dev/null 2>&1 || useradd --create-home --shell /bin/bash runner

# --- 3. Runner binaries (one copy, each instance gets its own directory) -------
dist=/opt/actions-runner-dist
if [ ! -x "$dist/config.sh" ]; then
  ver=$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/^v//')
  mkdir -p "$dist"
  curl -fsSL "https://github.com/actions/runner/releases/download/v${ver}/actions-runner-linux-x64-${ver}.tar.gz" | tar -xz -C "$dist"
  "$dist/bin/installdependencies.sh"
fi

# --- 4. Wrapper + systemd template unit ----------------------------------------
install -m 755 "$(dirname "$0")/runner-loop.sh" /usr/local/bin/runner-loop.sh

cat > /etc/systemd/system/gh-runner@.service <<'UNIT'
[Unit]
Description=GitHub Actions ephemeral runner %i
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=/etc/gh-runner.env
ExecStart=/usr/local/bin/runner-loop.sh %i
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload

echo "Done. Now: put GH_PAT in /etc/gh-runner.env (chmod 600) and enable gh-runner@<owner>--<repo>--<n>."
