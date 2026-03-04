# M2: OpenClaw Dockerfile
# 基础镜像: Ubuntu 24.04
# 目标: 安装 OpenClaw CLI 并准备运行环境

FROM ubuntu:24.04

# 设置非交互式环境变量
ENV DEBIAN_FRONTEND=noninteractive

# 工作目录
WORKDIR /app

# 安装基础依赖 + xz (用于解压 Node.js)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# 下载并安装 Node.js v22
RUN curl -fsSL https://nodejs.org/dist/v22.14.0/node-v22.14.0-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1

# 验证 Node.js 安装
RUN node --version && npm --version

# 安装 OpenClaw CLI (使用淘宝镜像加速)
RUN npm config set registry https://registry.npmmirror.com \
    && npm install -g openclaw \
    && npm config set registry https://registry.npmjs.org

# 验证 OpenClaw 安装
RUN openclaw --version

# 创建 OpenClaw 配置目录
RUN mkdir -p /app/.openclaw

# 设置环境变量
ENV OPENCLAW_HOME=/app/.openclaw
ENV PATH="/app/.openclaw/bin:${PATH}"

# 暴露端口 (如果需要)
EXPOSE 3000

# 启动命令
CMD ["openclaw", "status"]
