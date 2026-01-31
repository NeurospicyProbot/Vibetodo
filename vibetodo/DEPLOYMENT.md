# Deployment

Vibetodo is deployed on Fly.io with SQLite persistence.

## Architecture

```mermaid
flowchart TB
    subgraph Internet
        User[Browser]
    end

    subgraph Fly.io["Fly.io (Sydney Region)"]
        Proxy[Fly Proxy<br/>HTTPS + WebSocket]

        subgraph VM["Fly Machine (shared-cpu-1x, 1GB RAM)"]
            Phoenix[Phoenix App<br/>Port 4000]
            LiveView[LiveView<br/>Real-time UI]
        end

        subgraph Storage["Persistent Volume (1GB)"]
            SQLite[(SQLite DB<br/>/data/vibetodo.db)]
        end
    end

    User -->|HTTPS| Proxy
    Proxy -->|HTTP| Phoenix
    Phoenix --> LiveView
    Phoenix -->|Read/Write| SQLite

    style Fly.io fill:#8b5cf6,color:#fff
    style VM fill:#3b82f6,color:#fff
    style Storage fill:#10b981,color:#fff
    style SQLite fill:#fbbf24,color:#000
```

## Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| Web Framework | Phoenix 1.8 | HTTP handling, routing |
| Real-time UI | LiveView | WebSocket-based reactive updates |
| Database | SQLite + Ecto | Persistent storage |
| Hosting | Fly.io | Edge deployment, auto-sleep |
| Storage | Fly Volume | Persistent disk for SQLite |

## Details

- **Region:** Sydney (syd)
- **Auto-sleep:** VMs sleep after ~5min idle, wake on request (~2-3s)
- **URL:** https://vibetodo.fly.dev
- **Data:** Persisted on Fly Volume, survives restarts

## Commands

```bash
# Deploy
fly deploy

# View logs
fly logs

# SSH into VM
fly ssh console

# Check app status
fly status
```

## Configuration Files

- `fly.toml` - Fly.io app configuration
- `Dockerfile` - Container build instructions
- `rel/` - Release scripts (server, migrate)
