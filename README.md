# DSH Docker 部署

> 在任意 Docker 环境（Linux 服务器 / NAS / 云主机 / Docker Desktop）一键部署
> [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（DSH）——
> DeepSeek 官方的 AI 编程 Agent 框架（Web UI + CLI）。

## ✨ 方案亮点

- **容器内升级，永不重建镜像**：DSH 程序装在挂载卷 `/opt/dsh`（npm 全局包），升级只需
  `docker exec dsh npm install -g @deepseek-ai/dsh@<版本> && docker restart dsh`；镜像只含运行环境，构建一次即可
- **安全默认**：`dsh web` 刻意只监听 `127.0.0.1:3081`（官方安全设计），`socat` 把外部 `3080` 转发进去；默认内网直连，远程访问可加装账号密码 + MFA 认证
- **数据全持久化**：程序 / 用户数据（会话、配置、插件、记忆库）/ 工作区三卷分离，备份 = 复制目录
- **多架构**：GitHub Actions 自动构建 `linux/amd64` + `linux/arm64`，发布到 `ghcr.io`

## 📦 快速开始（3 步）

```bash
# 1. 拉取仓库并配置
git clone https://github.com/Steven-stack-s/dsh-docker.git && cd dsh-docker
cp .env.example .env            # 编辑 .env，填入 DEEPSEEK_API_KEY

# 2. 启动（首次启动会自动安装 DSH，需几分钟）
docker compose up -d

# 3. 访问
# 浏览器打开 http://<主机IP>:3080，创建首个管理员后即可使用
```

详细步骤见 [docs/01-快速开始.md](docs/01-快速开始.md)。

## 📚 文档

| 文档 | 内容 |
|---|---|
| [docs/01-快速开始.md](docs/01-快速开始.md) | 安装、配置、首次管理员、验证 |
| [docs/02-认证与远程访问.md](docs/02-认证与远程访问.md) | 可选：dsh-remote 账号密码 + MFA、SSH 隧道、反向代理 |
| [docs/03-升级与维护.md](docs/03-升级与维护.md) | 升级 DSH、装插件、换密钥、备份 |
| [docs/04-故障排查.md](docs/04-故障排查.md) | 常见问题与解决 |
| [docs/05-平台差异.md](docs/05-平台差异.md) | 通用 Linux / 群晖、绿联、威联通 NAS / Docker Desktop |

## 🔧 目录结构

```
.
├── docker-compose.yml        # 部署配置（全部变量见 .env.example）
├── Dockerfile                # 基础镜像：node:24 + git + socat + entrypoint
├── entrypoint.sh             # 容器入口：首次装 DSH → socat 转发 → 启动 web
├── .env.example              # 环境变量模板（复制为 .env 填写）
├── docs/                     # 详细文档
└── .github/workflows/        # CI：自动构建镜像发布到 ghcr.io
```

## 🏗️ 架构说明

```
浏览器
   |
   v
宿主机 :3080 ──> 容器 socat(0.0.0.0:3080) ──> dsh web(127.0.0.1:3081)
```

- 镜像只装运行环境（`node:24-slim` + git + ca-certificates + tzdata + socat）
- 首次启动 `entrypoint.sh` 自动 `npm install -g @deepseek-ai/dsh` 到卷 `/opt/dsh`，并安装 pnpm（插件管理需要）
- 三个持久化卷：`./programs`（DSH 程序本体）、`./dsh`（DSH_HOME 用户数据）、`./workspace`（agent 工作区）

## ⚠️ 安全提示

- `DEEPSEEK_API_KEY` 只写在 `.env`（已被 `.gitignore` 忽略），不要提交到仓库
- 不要把 `3080` 直接映射到公网；远程访问请按 [docs/02](docs/02-认证与远程访问.md) 配置认证 + 反向代理
- 定期备份整个部署目录

## 📄 License

[MIT](LICENSE)
