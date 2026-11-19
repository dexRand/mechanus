#!/usr/bin/env bash
# new-lxc.sh — provision the MECHANUS machine from scratch.
#
# Target: Ubuntu LXC on Proxmox, privileged, Features: nesting=1.
# Sizing (VMID, RAM, swap, rootfs, vCPU) is up to you.
#
# Host-side (Proxmox, once): static IP + DNS + AppArmor + reboot — see README.
#
# Run this INSIDE the fresh LXC as root.
set -euo pipefail

# --- 1. Base tools -----------------------------------------------------------
apt-get update -qq
apt-get install -y -qq curl git ca-certificates gnupg lsb-release gh   # gh: bin/loop.sh waits for CI with it

# --- 2. Docker (for the safe, memory-capped unit tests) ----------------------
curl -fsSL https://get.docker.com | sh

# AppArmor fix: the prebuilt docker-default profile can't load inside the LXC.
# lxc.apparmor.profile=unconfined (host-side) is NOT enough by itself.
mv /usr/sbin/apparmor_parser /usr/sbin/apparmor_parser.disabled 2>/dev/null || true
systemctl restart docker

# --- 3. opencode (OpenCode 2) ------------------------------------------------
curl -fsSL https://opencode.ai/install | bash
opencode upgrade --major
ln -sf /root/.opencode/bin/opencode /usr/local/bin/opencode

# --- 4. Mesh VPN (e.g. NetBird) so the machine is reachable remotely ----------
# Setup keys are ONE-TIME: get a fresh one from the VPN dashboard.
#   curl -fsSL https://pkgs.netbird.io/install.sh | sh
#   netbird up --setup-key <SETUP_KEY>
#   netbird status

# NetBird rewrites /etc/resolv.conf to its own IP -> pin a working resolver.
printf "nameserver <GATEWAY_IP>\nnameserver 1.1.1.1\n" > /etc/resolv.conf
chattr +i /etc/resolv.conf 2>/dev/null || true

# --- 5. Workspace ------------------------------------------------------------
mkdir -p /workspace
cd /workspace
git clone https://github.com/dexRand/mechanus.git mechanus
# Clone the project repos (public clone as-is; private need the GitHub token first).

# --- 6. Global agents (so MONOLITH/ASU/ARBITER/RECON work from any repo) ------
# Copy the repo's opencode.json (single source: models, `steps` caps, `edit`
# denied to ARBITER and RECON). A copy, not a link: the provider key goes into
# the global config (README §3) and must never land in the repo file.
mkdir -p /root/.config/opencode
cp /workspace/mechanus/opencode.json /root/.config/opencode/opencode.json

# --- 7. Web UI (opencode serve) as a service ---------------------------------
PASS="${OPENCODE_WEB_PASSWORD:-$(openssl rand -hex 10)}"
cat > /etc/systemd/system/opencode-web.service <<UNIT
[Unit]
Description=OpenCode Web UI
After=network.target

[Service]
Type=simple
User=root
Environment=PATH=/root/.opencode/bin:/usr/local/bin:/usr/bin:/bin
Environment=OPENCODE_SERVER_PASSWORD=${PASS}
Environment=OPENCODE_SERVER_USERNAME=opencode
ExecStart=/root/.opencode/bin/opencode serve --hostname 0.0.0.0 --port 4096
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now opencode-web
echo "Web UI password: ${PASS}"

# --- 8. Secrets (never in git) ----------------------------------------------
#   DeepSeek API key  ->  opencode auth login
#   GitHub token      ->  fine-grained PAT; then:
#       git config --global credential.helper store
#       printf 'https://<user>:<PAT>@github.com\n' > /root/.git-credentials
#       git config --global user.name "..." ; git config --global user.email "..."

echo "MECHANUS provisioned. Set secrets, clone private repos, fix AGENTS.md index."
