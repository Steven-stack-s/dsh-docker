# 01 · Quick Start

> [English](01-quick-start.md) | [简体中文](../zh-CN/01-快速开始.md)

Deploy DeepSeek Harness (DSH) on any Docker environment.

## 1. Prerequisites

- Docker Engine ≥ 20.10 (with `docker compose` v2 support)
- Ability to pull `node:24-slim` (on mainland China networks, consider configuring a registry mirror accelerator; see [05](05-platform-differences.md))
- A DeepSeek API Key (or another compatible model API)

## 2. Directory Structure

```
dsh-docker/
├── docker-compose.yml   # deployment config
├── Dockerfile           # base image — build it yourself or use the ghcr.io image directly
├── entrypoint.sh        # container entrypoint
└── .env.example         # environment variable template
```

## 3. Installation Steps

### 3.1 Clone the Repo and Configure

```bash
git clone https://github.com/Steven-stack-s/dsh-docker.git
cd dsh-docker

cp .env.example .env
# edit .env; at minimum fill in:
#   DEEPSEEK_API_KEY=sk-你的密钥
# the rest have defaults; adjust as needed (port, data directory, resource limits, etc.)
```

> `.env` is ignored by `.gitignore`, so your keys never enter git.

### 3.2 Start

```bash
docker compose up -d
```

On first boot, `entrypoint.sh` automatically installs `@deepseek-ai/dsh` into the volume `/opt/dsh`. On slower networks this takes a few minutes, which is normal (the compose health check already relaxes `start_period` to 300s).

### 3.3 View Startup Logs

```bash
docker logs dsh --tail 15
```

Expected output:

```
[entrypoint] 启动 socat 转发: 0.0.0.0:3080 -> 127.0.0.1:3081
[entrypoint] 启动 dsh web (内部 127.0.0.1:3081)
dsh web: http://127.0.0.1:3081
```

- "opening the default browser" should not appear (`--no-open` is set)
- The `Connection refused` from socat right at startup is normal (dsh is not ready yet) and disappears once dsh is up

## 4. Create the First Admin

DSH's Web UI lets you create the first admin, but this operation is **loopback-only** (to prevent remote registration hijacking). Run it on the **host** (after port mapping, `127.0.0.1:3080` is the container's entry point):

```bash
curl -s -X POST http://127.0.0.1:3080/auth/bootstrap \
  -H 'Content-Type: application/json' \
  -d '{"username":"你的用户名","password":"你的密码"}'
# expected: {"ok":true,...,"user":{...}}
```

Hosts without curl can use an SSH tunnel instead (see [02](02-authentication-remote-access.md)).

## 5. Verification

- Open `http://<主机IP>:3080` in a browser and log in with the account you just created
- Go to Settings → Models and confirm the API Key is in effect
- In `docker ps`, the `dsh` container status is healthy (being "starting" for the first few minutes after first boot is normal)

## 6. Stop / Uninstall

```bash
docker compose down          # stop and remove the container (data stays in ./dsh ./programs ./workspace)
docker compose down -v       # ⚠️ also delete anonymous volumes (no named volumes are used; data lives in the mounted dirs and is unaffected)
rm -rf dsh programs workspace # permanently delete all data
```
