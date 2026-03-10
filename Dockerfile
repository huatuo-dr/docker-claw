# Docker-Claw Multi-Agent Dockerfile
# 用于构建煎饼和墨汁儿的Docker镜像

FROM ubuntu:24.04

LABEL maintainer="K哥"
LABEL description="OpenClaw Agent Container for Jianbing and Mozhi"
LABEL version="1.0"

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=22
ENV OPENCLAW_VERSION=latest

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    vim \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# 安装Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# 验证Node.js和npm安装
RUN node --version && npm --version

# 安装OpenClaw CLI
RUN npm install -g openclaw@${OPENCLAW_VERSION}

# 验证OpenClaw安装
RUN openclaw --version

# 创建工作目录
WORKDIR /app

# 创建OpenClaw工作目录
RUN mkdir -p /app/.openclaw/workspace

# 创建共享目录挂载点
RUN mkdir -p /shared

# 复制配置文件（由启动脚本动态挂载）
# 这里不复制，使用volume挂载

# 设置Git配置（由启动脚本动态设置）
# 这里不设置，使用环境变量

# 暴露端口（如果需要）
# EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep -f "openclaw" > /dev/null || exit 1

# 默认命令（由启动脚本覆盖）
# 使用 --port 指定端口，避免 systemd 依赖
CMD ["openclaw", "gateway", "--port", "18789"]
