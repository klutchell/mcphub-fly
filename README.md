# MCPHub on Fly.io

Deploys [MCPHub](https://github.com/samanhappy/mcphub) to Fly.io,
exposing stdio MCP servers as Streamable HTTP endpoints
with OAuth 2.0 auth.

## Setup

```bash
fly launch --ha=false --vm-memory 1024

fly secrets set JWT_SECRET="$(openssl rand -hex 32)"

fly deploy
```

A random admin password is generated on first boot.
Retrieve it from the deploy logs:

```bash
fly logs
```

Log in at `https://<app>.fly.dev` with username `admin`
and the logged password. Change it from the admin panel.

## Adding MCP servers

Add servers from the dashboard, then connect clients to:

```text
https://<app>.fly.dev/mcp/<server>
```

### OAuth clients (Claude.ai, Notion, etc.)

Clients that support MCP OAuth will automatically discover
auth via `/.well-known/oauth-authorization-server`, run an
OAuth PKCE flow, and prompt you to log in.

### Claude Code

```bash
claude mcp add <server> https://<app>.fly.dev/mcp/<server> --transport http
```

### Claude Desktop

Add a new connector in the UI with the URL
`https://<app>.fly.dev/mcp/<server>`.

## Redeploy

```bash
fly deploy
```

## Verify

```bash
fly status
fly logs
```

## Architecture

MCPHub acts as both an OAuth authorization server and MCP
proxy. Clients discover auth endpoints via RFC 8414 metadata,
register dynamically (RFC 7591), and complete an OAuth PKCE
flow. All runtime state (users, OAuth clients, tokens, MCP
server configs) persists in a Fly volume at `/app/data`.

## Secrets

| Secret | Purpose |
| ------ | ------- |
| `JWT_SECRET` | MCPHub JWT signing |
