# MCPHub on Fly.io

Deploys [MCPHub](https://github.com/samanhappy/mcphub) to Fly.io, exposing stdio
MCP servers as Streamable HTTP endpoints with OAuth 2.0 auth.

The upstream image runs unmodified, so this repo is just a `fly.toml`. MCPHub now
handles everything it used to need a wrapper for: it generates a random admin
password on first boot, applies the OAuth server defaults when no settings file
exists, and derives its base URL from the request.

## Setup

`fly.toml` has no `app` or `primary_region` so it stays portable, which means
passing `-a` to each command and picking the region when you create the volume.

```bash
APP=mcphub

fly apps create "$APP"
fly volumes create mcphub_data -a "$APP" -r yyz -s 1
fly secrets set -a "$APP" JWT_SECRET="$(openssl rand -hex 32)"
fly deploy -a "$APP"
```

`JWT_SECRET` isn't optional. Without it MCPHub generates a new secret on every
boot, so every session breaks each time the machine resumes from suspend.

## First login

MCPHub prints a generated admin password once, on first boot:

```bash
fly logs -a "$APP" | grep 'Generated admin password'
```

Log in at `https://<app>.fly.dev` as `admin`, then change it from the admin panel.
To pick the password yourself instead, set `ADMIN_PASSWORD` as a secret before the
first deploy.

## Adding MCP servers

Add servers from the dashboard, then connect clients to:

```text
https://<app>.fly.dev/mcp/<server>
```

### OAuth clients (Claude.ai, Notion, etc.)

Clients that support MCP OAuth discover auth via
`/.well-known/oauth-authorization-server`, register dynamically, run a PKCE flow,
and prompt you to log in.

### Claude Code

```bash
claude mcp add <server> https://<app>.fly.dev/mcp/<server> --transport http
```

### Claude Desktop

Add a connector with the URL `https://<app>.fly.dev/mcp/<server>`.

## Upgrading

Check the [release notes](https://github.com/samanhappy/mcphub/releases), snapshot
the volume, then bump the `image` tag in `fly.toml` and redeploy.

```bash
fly volumes list -a "$APP"
fly volumes snapshots create <volume-id>
fly deploy -a "$APP"
```

Settings live on the volume, not in the image, so rolling back is putting the old
tag back and deploying again.

Watch for security releases. MCPHub is an internet-facing auth server and has
shipped several advisories, including a critical SSE impersonation bug fixed in
0.12.15 ([GHSA-wf8q-wvv8-p8jf](https://github.com/samanhappy/mcphub/security/advisories/GHSA-wf8q-wvv8-p8jf)).

## Verify

```bash
fly status -a "$APP"
curl -s https://<app>.fly.dev/health
```

`/health` is public and unauthenticated. It returns 200 for both `healthy` and
`degraded`, and only 503 when the process itself is broken, which is why Fly uses
it as the http check.

## Architecture

MCPHub is both an OAuth authorization server and an MCP proxy. Clients discover
auth endpoints via RFC 8414 metadata, register dynamically (RFC 7591), and
complete an OAuth PKCE flow. Runtime state (users, OAuth clients, tokens, server
configs) persists on the Fly volume at `/app/data`.

Better Auth ships in MCPHub 1.x but only activates in database mode, so this
deployment stays on the JSON settings file and needs no Postgres.

## Secrets

| Secret | Required | Purpose |
| ------ | -------- | ------- |
| `JWT_SECRET` | yes | JWT signing, must be stable across restarts |
| `ADMIN_PASSWORD` | no | Initial admin password, instead of a generated one |

---

Co-authored with Claude
