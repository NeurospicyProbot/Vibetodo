# Deployment

Vibetodo is deployed on [Fly.io](https://fly.io) with SQLite persistence and CI/CD via GitHub Actions.

## Architecture

```mermaid
flowchart TB
    subgraph GitHub
        Repo[GitHub Repo]
        Actions[GitHub Actions]
    end

    subgraph Internet
        User[Browser]
    end

    subgraph Fly.io["Fly.io (Sydney Region)"]
        Proxy[Fly Proxy<br/>HTTPS + WebSocket]

        subgraph VM["Fly Machine (shared-cpu-1x, 1GB RAM)"]
            Phoenix[Phoenix App<br/>Port 4000]
            LiveView[LiveView<br/>Real-time UI]
            Health[/api/health]
        end

        subgraph Storage["Persistent Volume (1GB)"]
            SQLite[(SQLite DB<br/>/data/vibetodo.db)]
        end
    end

    Repo -->|push to main| Actions
    Actions -->|fly deploy| Fly.io
    User -->|HTTPS| Proxy
    Proxy -->|HTTP| Phoenix
    Phoenix --> LiveView
    Phoenix --> Health
    Phoenix -->|Read/Write| SQLite

    style GitHub fill:#24292e,color:#fff
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
| CI/CD | GitHub Actions | Automated testing & deployment |

## URLs

- **App:** https://vibetodo.fly.dev
- **Health:** https://vibetodo.fly.dev/api/health

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/ci.yml`):

1. **On PR / push:** Run tests + format check
2. **On push to main:** Auto-deploy to Fly.io

### Setup Auto-Deploy

```bash
# Generate Fly.io deploy token
fly tokens create deploy -x 999999h

# Add to GitHub: Settings → Secrets → Actions
# Name: FLY_API_TOKEN
# Value: <your token>
```

## Details

- **Region:** Sydney (syd)
- **Auto-sleep:** VMs sleep after ~5min idle, wake on request (~2-3s)
- **Data:** Persisted on Fly Volume, survives restarts

## Commands

```bash
# Deploy manually
fly deploy

# View logs
fly logs

# SSH into VM
fly ssh console

# Check app status
fly status

# Test health endpoint
curl https://vibetodo.fly.dev/api/health
```

## Email (Resend)

Transactional emails (registration, login links) are sent via [Resend](https://resend.com).

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `RESEND_API_KEY` | Yes | API key from resend.com/api-keys |
| `FROM_EMAIL` | No | Sender address (default: `onboarding@resend.dev`) |

### Setup

1. Sign up at [resend.com](https://resend.com) (free: 3,000 emails/month)
2. Get your API key from Settings → API Keys
3. Add `RESEND_API_KEY` to GitHub Secrets
4. The CI workflow automatically sets it on Fly.io during deploy

### Using a Custom Domain

The default `onboarding@resend.dev` is for testing only. For production:

1. Add and verify your domain at [resend.com/domains](https://resend.com/domains)
2. Add DNS records (SPF, DKIM) as instructed
3. Add `FROM_EMAIL` to GitHub Secrets (e.g., `noreply@yourdomain.com`)
4. Update `.github/workflows/ci.yml` to set `FROM_EMAIL` on Fly.io:
   ```yaml
   - name: Set Fly.io secrets
     run: flyctl secrets set RESEND_API_KEY="${RESEND_API_KEY}" FROM_EMAIL="${FROM_EMAIL}" --stage
     env:
       FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
       RESEND_API_KEY: ${{ secrets.RESEND_API_KEY }}
       FROM_EMAIL: ${{ secrets.FROM_EMAIL }}
   ```

### Local Development

Emails are captured in memory using Swoosh's Local adapter. View them at:
http://localhost:4000/dev/mailbox

## Configuration Files

- `fly.toml` - Fly.io app configuration
- `Dockerfile` - Container build instructions
- `rel/` - Release scripts (server, migrate)
- `.github/workflows/ci.yml` - CI/CD pipeline
