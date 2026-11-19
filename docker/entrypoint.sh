#!/usr/bin/env bash
set -euo pipefail

# Inject every *_API_KEY env var into the global provider config as a direct key.
# (OpenCode 2 does not resolve {env:...} for the actual API call, so we bake the
#  real value here. Global config + project config are deep-merged by opencode.)

CONFIG_DIR="${OPENCODE_GLOBAL_CONFIG:-/root/.config/opencode}"
mkdir -p "$CONFIG_DIR"

providers='{}'
for varname in $(compgen -e); do
  case "$varname" in
    *_API_KEY) ;;
    *) continue ;;
  esac
  key="${!varname:-}"
  [ -n "$key" ] || continue
  provider="$(printf '%s' "${varname%_API_KEY}" | tr '[:upper:]' '[:lower:]')"
  providers="$(jq -n --arg p "$provider" --arg k "$key" --argjson prev "$providers" \
    '$prev * {provider: {($p): {options: {apiKey: $k}}}}')"
done

printf '%s\n' "$providers" > "$CONFIG_DIR/opencode.json"

exec "$@"
