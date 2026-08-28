# DSH Docker 部署 / Deploy DeepSeek Harness with Docker

> Deploy [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (DSH) — DeepSeek's official AI coding agent framework (Web UI + CLI) — on **any Docker environment** with one command.
>
> 在**任意 Docker 环境**（Linux 服务器 / NAS / 云主机 / Docker Desktop）一键部署
> [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（DSH）——DeepSeek 官方的 AI 编程 Agent 框架（Web UI + CLI）。

---

## ✨ Highlights / 方案亮点

- **Upgrade inside the container, never rebuild the image** — DSH is installed into the mounted volume `/opt/dsh` (npm global package). Upgrade with `docker exec dsh npm install -g @deepseek-ai/dsh@<version> && docker restart dsh`; the image only contains the runtime, build it once.
  **容器内升级，永不重建镜像** —— DSH 程序装在挂载卷 `/opt/dsh`（npm 全局包），升级只需 `docker exec dsh npm install -g @deepseek-ai/dsh@<版本> && docker restart dsh`；镜像只含运行环境，构建一次即可。

- **Secure by default** — `dsh web` intentionally listens only on `127.0.0.1:3081` (official security design); `socat` forwards the external `3080` port into it. Intranet-only by default; password + MFA authentication can be added for remote access.
  **安全默认** —— `dsh web` 刻意只监听 `127.0.0.1:3081`（官方安全设计），`socat` 把外部 `3080` 转发进去；默认内网直连，远程访问可加装账号密码 + MFA 认证。

- **Fully persisted data** — three separate volumes for program / user data (sessions, configs, plugins, memory) / workspace; backup = copy the directory.
  **数据全持久化** —— 程序 / 用户数据（会话、配置、插件、记忆库）/ 工作区三卷分离，备份 = 复制目录。

- **Multi-architecture** — GitHub Actions automatically builds `linux/amd64` + `linux/arm64` images and publishes them to `ghcr.io`.
  **多架构** —— GitHub Actions 自动构建 `linux/amd64` + `linux/arm64`，发布到 `ghcr.io`。

---

## 📦 Quick Start / 快速开始（3 步）

```bash
# 1. Clone and configure
git clone https://github.com/Steven-stack-s/dsh-docker.git && cd dsh-docker
cp .env.example .env            # edit .env, fill in DEEPSEEK_API_KEY

# 2. Start (DSH is installed automatically on first boot; takes a few minutes)
docker compose up -d

# 3. Access — open http://<host-ip>:3080 and create the first admin account
#    浏览器打开 http://<主机IP>:3080，创建首个管理员后即可使用
```

Detailed steps: [docs/01-快速开始.md](docs/01-快速开始.md) / 详细步骤见 [docs/01-快速开始.md](docs/01-快速开始.md)。

---

## 📚 Documentation / 文档

| 文档 Doc | 内容 Content |
|---|---|
| [docs/01-快速开始.md](docs/01-快速开始.md) | 安装、配置、首次管理员、验证 / Install, configure, first admin, verify |
| [docs/02-认证与远程访问.md](docs/02-认证与远程访问.md) | 可选 dsh-remote 认证、SSH 隧道、反向代理 / Optional auth, SSH tunnel, reverse proxy |
| [docs/03-升级与维护.md](docs/03-升级与维护.md) | 升级、插件、密钥、备份 / Upgrade, plugins, keys, backup |
| [docs/04-故障排查.md](docs/04-故障排查.md) | 常见问题 / Troubleshooting |
| [docs/05-平台差异.md](docs/05-平台差异.md) | Linux / NAS / Docker Desktop 差异 / Platform differences |

---

## 🔧 Directory Structure / 目录结构

```
.
├── docker-compose.yml        # 部署配置（变量见 .env.example）/ deployment config (vars in .env.example)
├── Dockerfile                # 基础镜像：node:24 + git + socat + entrypoint
├── entrypoint.sh             # 容器入口：首次装 DSH → socat 转发 → 启动 web
├── .env.example              # 环境变量模板（复制为 .env 填写）/ env template (copy to .env)
├── docs/                     # 详细文档 / detailed docs
└── .github/workflows/        # CI：自动构建镜像发布到 ghcr.io
```

---

## 🏗️ Architecture / 架构说明

```
Browser / 浏览器
   |
   v
Host :3080 ──> container socat(0.0.0.0:3080) ──> dsh web(127.0.0.1:3081)
```

- The image contains only the runtime (`node:24-slim` + git + ca-certificates + tzdata + socat).
  镜像只装运行环境（`node:24-slim` + git + ca-certificates + tzdata + socat）。
- On first boot, `entrypoint.sh` automatically runs `npm install -g @deepseek-ai/dsh` into the volume `/opt/dsh`, and installs pnpm (needed for plugin management).
  首次启动 `entrypoint.sh` 自动 `npm install -g @deepseek-ai/dsh` 到卷 `/opt/dsh`，并安装 pnpm（插件管理需要）。
- Three persistent volumes: `./programs` (DSH program), `./dsh` (DSH_HOME user data), `./workspace` (agent workspace).
  三个持久化卷：`./programs`（DSH 程序本体）、`./dsh`（DSH_HOME 用户数据）、`./workspace`（agent 工作区）。

---

## ⚠️ Security Notes / 安全提示

- `DEEPSEEK_API_KEY` lives only in `.env` (ignored by `.gitignore`) — never commit it.
  `DEEPSEEK_API_KEY` 只写在 `.env`（已被 `.gitignore` 忽略），不要提交到仓库。
- Do not expose port `3080` directly to the public internet; for remote access, add authentication + a reverse proxy (see [docs/02](docs/02-认证与远程访问.md)).
  不要把 `3080` 直接映射到公网；远程访问请按 [docs/02](docs/02-认证与远程访问.md) 配置认证 + 反向代理。
- Back up the whole deployment directory regularly.
  定期备份整个部署目录。

---

## 📄 License

[MIT](LICENSE)
