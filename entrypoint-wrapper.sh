#!/bin/bash
set -euo pipefail
# shellcheck disable=SC2016
envsubst '${MCPHUB_BEARER_KEY}' < /app/mcp_settings.json.template > /app/mcp_settings.json
exec /usr/local/bin/entrypoint.sh "$@"
