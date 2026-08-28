#!/bin/sh
set -e

# ============================================================
# DSH 容器入口（容器内升级方案）
#   - 首次启动：把 @deepseek-ai/dsh 安装进挂载卷（/opt/dsh）
#   - 日常升级：docker exec dsh npm install -g @deepseek-ai/dsh@<新版本>
#               docker restart dsh
#   - 无需重新构建/拉取镜像
# ============================================================

if ! command -v dsh >/dev/null 2>&1; then
  echo "[entrypoint] 首次启动：安装 @deepseek-ai/dsh 到卷目录 /opt/dsh ..."
  if [ -n "$NPM_REGISTRY" ]; then
    npm install -g @deepseek-ai/dsh --registry="$NPM_REGISTRY"
  else
    npm install -g @deepseek-ai/dsh
  fi
  echo "[entrypoint] DSH 已就绪: $(command -v dsh)"
fi

# pnpm：dsh plugin 命令（插件管理）转发到 pnpm 执行，必须可用
if ! command -v pnpm >/dev/null 2>&1; then
  echo "[entrypoint] 安装 pnpm（插件管理需要）..."
  if [ -n "$NPM_REGISTRY" ]; then
    npm install -g pnpm --registry="$NPM_REGISTRY"
  else
    npm install -g pnpm
  fi
fi

# dsh web 刻意只监听 127.0.0.1（--host 0.0.0.0 被安全拒绝）。
# 端口分工：dsh 内部监听 127.0.0.1:3081；socat 把外部 0.0.0.0:3080 转发到 3081。
# （socat 不能听 3080 再让 dsh 也听 3080：0.0.0.0 会占用 127.0.0.1，必然 EADDRINUSE）
if command -v socat >/dev/null 2>&1; then
  echo "[entrypoint] 启动 socat 转发: 0.0.0.0:3080 -> 127.0.0.1:3081"
  socat TCP-LISTEN:3080,fork,reuseaddr TCP:127.0.0.1:3081 &
fi

echo "[entrypoint] 启动 dsh web (内部 127.0.0.1:3081)"
# --no-open：容器内无浏览器，禁用 dsh 自动打开浏览器
exec dsh web --port 3081 --no-open
