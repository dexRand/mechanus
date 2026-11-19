#!/usr/bin/env bash
# install-claude.sh — link the MECHANUS skill and agents into Claude Code (user level).
#
# Usage: bin/install-claude.sh
# Links (does not copy), so a `git pull` here updates Claude Code too.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p ~/.claude/skills ~/.claude/agents

ln -sfn "$repo/skills/mechanus" ~/.claude/skills/mechanus
for f in "$repo"/claude/agents/*.md; do
  ln -sf "$f" ~/.claude/agents/"$(basename "$f")"
done

echo "MECHANUS linked: skill 'mechanus', agents 'builder' (sonnet) and 'arbiter' (opus)."
