# MCPHub on Fly.io

Deploys [MCPHub](https://github.com/samanhappy/mcphub) to Fly.io,
exposing stdio MCP servers as Streamable HTTP endpoints
with bearer token auth.

## First-time setup

```bash
# Create Fly app (no deploy yet)
fly launch --yes --no-deploy --internal-port 3000 \
  --ha=false --vm-memory 1024 --name your-app-name

# Set secrets
fly secrets set \
  JWT_SECRET="$(openssl rand -hex 32)" \
  MCPHUB_BEARER_KEY="your-bearer-token" \
  ZULIP_EMAIL="bot@example.zulipchat.com" \
  ZULIP_API_KEY="your-zulip-api-key" \
  ZULIP_SITE="https://example.zulipchat.com"

# Initial deploy
fly deploy
```

## Redeploy

```bash
fly deploy
```

## Usage

MCP endpoint: `https://<app>.fly.dev/mcp/zulipchat`

Connect from any MCP client that supports Streamable HTTP:

```json
{
  "mcpServers": {
    "zulipchat": {
      "type": "streamable-http",
      "url": "https://<app>.fly.dev/mcp/zulipchat",
      "headers": {
        "Authorization": "Bearer your-bearer-token"
      }
    }
  }
}
```

## Verify

```bash
fly status
fly logs
curl -H "Authorization: Bearer $MCPHUB_BEARER_KEY" https://<app>.fly.dev/mcp/zulipchat
```

## Architecture

MCPHub uses `${VAR}` substitution in MCP server `env`/`args`
fields at runtime, but not in `bearerKeys`. The entrypoint wrapper
uses `envsubst` to expand only `MCPHUB_BEARER_KEY` into the config
at startup, leaving `ZULIP_*` placeholders for MCPHub's runtime
expansion.

## Secrets

| Secret | Purpose |
| ------ | ------- |
| `JWT_SECRET` | MCPHub JWT signing |
| `MCPHUB_BEARER_KEY` | Bearer token for client auth (expanded by entrypoint) |
| `ZULIP_EMAIL` | Zulip bot email (expanded by MCPHub runtime) |
| `ZULIP_API_KEY` | Zulip API key (expanded by MCPHub runtime) |
| `ZULIP_SITE` | Zulip instance URL (expanded by MCPHub runtime) |
