# OpenSpace Docker Setup

Docker Compose configuration for running OpenSpace with all services containerized.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Network                     │
│                                                             │
│  ┌─────────────┐         ┌─────────────┐                    │
│  │   Frontend  │────────▶│  Dashboard  │                    │
│  │   (React)   │  :7788  │   Server    │                    │
│  │   :3789     │         │  (Flask)    │                    │
│  └─────────────┘         └──────┬──────┘                    │
│                                 │                           │
│                         ┌───────▼────────┐                  │
│                         │  Local Server   │                  │
│                         │   (Flask)       │                  │
│                         │    :5000        │                  │
│                         └─────────────────┘                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- API keys for LLM providers (Anthropic, OpenAI, OpenRouter)

## Quick Start

### 1. Configure Environment

Copy the example environment file and add your API keys:

```bash
cp .env.example .env
# Edit .env and add your API keys
```

Required environment variables in `.env`:

```env
ANTHROPIC_API_KEY=your_anthropic_key
OPENAI_API_KEY=your_openai_key
OPENROUTER_API_KEY=your_openrouter_key
OPENSPACE_API_KEY=your_openspace_key  # optional
```

### 2. Build and Start Services

```bash
# Build all images
docker compose build

# Start all services in detached mode
docker compose up -d

# View logs
docker compose logs -f
```

### 3. Verify Services

```bash
# Frontend (UI)
curl http://localhost:3789

# Dashboard API
curl http://localhost:7788/api/v1/skills

# Local Server
curl http://localhost:5000/
```

### 4. Stop Services

```bash
docker compose down
# With volumes (removes all data)
docker compose down -v
```

## Service Ports

| Service | Port | Description |
|---------|------|-------------|
| Frontend | 3789 | React dashboard UI |
| Dashboard API | 7788 | Workflow visualization API |
| Local Server | 5000 | Shell/GUI automation endpoint |

## Docker Compose Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Production configuration |
| `docker-compose.dev.yml` | Development overrides (hot-reload) |
| `Dockerfile` | Core Python service image |
| `frontend/Dockerfile` | Frontend React app image |

## Development Mode

For development with hot-reload:

```bash
# Start with development overrides
docker compose -f docker-compose.yml -f docker-compose.dev.yml up

# Or use the shorthand if you rename dev file
docker compose up -d
```

## Data Persistence

Named volumes are used for persistent data:

- `openspace-data` → `/app/data` (skill storage)
- `openspace-logs` → `/app/logs` (workflow recordings)

To backup data:

```bash
docker run --rm -v openspace-data:/data -v $(pwd)/backup:/backup alpine tar czf /backup/data.tar.gz -C /data
```

## Shell Access

Access a shell in the running container:

```bash
docker exec -it openspace-core /bin/bash
```

## Running CLI Commands

Execute OpenSpace CLI commands inside the container:

```bash
# Show help
docker exec openspace-core python -m openspace --help

# List skills
docker exec openspace-core python -m openspace skill list

# Run a task
docker exec openspace-core python -m openspace run "Your task here"
```

## GUI Automation Notes

> **Important:** Platform-specific GUI dependencies (pyautogui, pyobjc, etc.) are NOT installed in the container since GUI automation requires host display access.

For GUI automation use cases, consider:
- Running OpenSpace directly on the host
- Using server mode with host networking: `docker compose up --network=host`

## Troubleshooting

### Services won't start

Check logs for errors:
```bash
docker compose logs openspace-core
docker compose logs openspace-frontend
```

### Port conflicts

If ports are already in use, modify `.env`:
```env
DASHBOARD_PORT=8788
LOCAL_SERVER_PORT=6000
FRONTEND_PORT=4789
```

### Permission issues

The containers run as non-root user (UID 1000). Ensure mounted directories are writable:
```bash
chmod -R 777 data logs
```

### Health check failures

Increase health check timeout in `docker-compose.yml` or check if services are properly configured:
```bash
docker inspect openspace-core | grep -A 10 Health
```

## Building Without Cache

Force a fresh build:
```bash
docker compose build --no-cache
```
