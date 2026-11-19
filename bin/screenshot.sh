#!/usr/bin/env bash
# screenshot.sh — take a screenshot of a page for RECON, with headless
# Playwright in Docker (no Node on the host).
#
# Usage:
#   bin/screenshot.sh <url> <out.png> [width,height]
#   bin/screenshot.sh http://localhost:3000/login /tmp/login.png 1280,800
#
# Host network: "localhost" in the URL is the host's localhost (native Docker,
# as on the LXC; with Docker Desktop it is the Docker VM's, not yours).
set -euo pipefail

url="${1:?usage: screenshot.sh <url> <out.png> [width,height]}"
out="${2:?usage: screenshot.sh <url> <out.png> [width,height]}"
size="${3:-1280,800}"
PW=1.55.0   # image tag and npm package must match (same browsers)

dir="$(cd "$(dirname "$out")" && pwd)"
name="$(basename "$out")"

docker run --rm --network host --ipc host \
  --user "$(id -u):$(id -g)" -e HOME=/tmp -e NPM_CONFIG_UPDATE_NOTIFIER=false \
  -v "$dir":/out \
  "mcr.microsoft.com/playwright:v${PW}-noble" \
  npx -y "playwright@${PW}" screenshot --full-page --viewport-size "$size" \
    "$url" "/out/$name" >/dev/null

echo "$dir/$name"
