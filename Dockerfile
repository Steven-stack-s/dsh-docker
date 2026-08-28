# ============================================================================
# DSH (DeepSeek Harness) 基础镜像 —— 只含运行环境，不含 DSH 程序本体
#
# 【设计：容器内升级方案】
#   DSH 程序装在挂载卷 /opt/dsh（npm 全局前缀），升级 DSH 不需要重新构建镜像：
#     日常升级：docker exec dsh npm install -g @deepseek-ai/dsh@<版本>
#                docker restart dsh
#   镜像只在基础环境（Node 版本 / 系统依赖）变化时才需要重建。
#
# 【Node 版本要求】DSH 需要 Node >= 22.18（zstd / Promise.withResolvers /
#   stripTypeScriptTypes 等新 API），故用当前 LTS 的 node:24-slim。
# ============================================================================

FROM node:24-slim

# DSH 运行依赖：git、ca-certificates（HTTPS）、tzdata（时区）、socat（端口转发）
# socat 用途（勿删）：dsh web 刻意只监听 127.0.0.1:3081
# （--host 0.0.0.0 被官方安全拒绝），socat 把外部 0.0.0.0:3080 转发到 127.0.0.1:3081。
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        tzdata \
        socat \
    && rm -rf /var/lib/apt/lists/*

# npm 全局前缀改到 /opt/dsh：该目录整体挂载到宿主机卷，
# 避免挂载 /usr/local 遮蔽镜像内的 node/npm 命令
ENV NPM_CONFIG_PREFIX=/opt/dsh
ENV PATH=/opt/dsh/bin:$PATH

# 数据根目录：DSH 所有用户数据（会话/配置/插件/记忆库）
ENV DSH_HOME=/data/dsh

# 时区（可用 .env 覆盖）
ENV TZ=Asia/Shanghai

WORKDIR /workspace
EXPOSE 3080

COPY entrypoint.sh /usr/local/bin/dsh-entrypoint
RUN chmod +x /usr/local/bin/dsh-entrypoint

ENTRYPOINT ["dsh-entrypoint"]

# 健康检查：探测 dsh 内部端口 3081（探测 socat 的 3080 会误报健康）
# 首次启动会自动安装 DSH（几分钟），start_period 需放宽
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=5 \
  CMD node -e "require('net').connect(3081,'127.0.0.1').on('connect',()=>process.exit(0)).on('error',()=>process.exit(1))"
