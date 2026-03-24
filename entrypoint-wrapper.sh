#!/bin/bash
set -euo pipefail

export BASE_URL="https://${FLY_APP_NAME}.fly.dev"
export MCPHUB_SETTING_PATH="/app/data/mcp_settings.json"

if [ ! -f "${MCPHUB_SETTING_PATH}" ]; then
  mkdir -p /app/data

  # shellcheck disable=SC2016
  envsubst '${BASE_URL}' < /app/mcp_settings.json.template > "${MCPHUB_SETTING_PATH}"

  # Generate a random admin password and seed it into the config
  ADMIN_PASSWORD="$(openssl rand -hex 16)"
  HASHED=$(node -e "
    const bcrypt = require('bcryptjs');
    bcrypt.hash(process.argv[1], 10).then(h => process.stdout.write(h));
  " "$ADMIN_PASSWORD")

  node -e "
    const fs = require('fs');
    const cfg = JSON.parse(fs.readFileSync(process.env.MCPHUB_SETTING_PATH, 'utf8'));
    cfg.users = [{ username: 'admin', password: process.argv[1], isAdmin: true }];
    fs.writeFileSync(process.env.MCPHUB_SETTING_PATH, JSON.stringify(cfg, null, 2));
  " "$HASHED"

  echo "==> Generated admin password: ${ADMIN_PASSWORD}"
  echo "==> Change it from the admin panel at ${BASE_URL}"
fi

exec /usr/local/bin/entrypoint.sh "$@"
