#!/bin/bash

# start-mozhi.sh - 启动墨汁儿（容器）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================"
echo "启动墨汁儿（审查者）"
echo "================================"
echo ""

# 检查Docker
if ! command -v docker &> /dev/null; then
  echo "❌ Docker未安装"
  exit 1
fi

# 检查Docker是否运行
if ! docker info &> /dev/null; then
  echo "❌ Docker未运行"
  echo "请先启动Docker"
  exit 1
fi

# 检查环境变量
echo "🔍 检查环境变量..."

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "❌ 错误: GITHUB_TOKEN 未设置"
  echo "请设置: export GITHUB_TOKEN=your_token"
  exit 1
fi

if [[ -z "$MOZHI_API_KEY" ]]; then
  echo "❌ 错误: MOZHI_API_KEY 未设置（墨汁儿使用智谱GLM模型）"
  echo "请设置: export MOZHI_API_KEY=your_key"
  exit 1
fi

if [[ -z "$WORKSPACE_PATH" ]]; then
  echo "⚠️ WORKSPACE_PATH 未设置，使用默认值: ./workspace"
  export WORKSPACE_PATH="$PROJECT_ROOT/workspace"
  mkdir -p "$WORKSPACE_PATH"
fi

echo "✅ 环境变量检查通过"

# 构建Docker镜像（如果需要）
echo ""
echo "🔨 检查Docker镜像..."

if ! docker images | grep -q "docker-claw"; then
  echo "构建Docker镜像..."
  docker build -t docker-claw:latest "$PROJECT_ROOT"
  echo "✅ Docker镜像构建完成"
else
  echo "✅ Docker镜像已存在"
fi

# 创建网络（如果不存在）
echo ""
echo "🌐 创建Docker网络..."

if ! docker network ls | grep -q "docker-claw-network"; then
  docker network create docker-claw-network
  echo "✅ Docker网络创建完成"
else
  echo "✅ Docker网络已存在"
fi

# 停止现有容器（如果存在）
echo ""
echo "🛑 检查现有容器..."

if docker ps -a | grep -q "mozhi-claw-container"; then
  echo "停止并删除现有容器..."
  docker stop mozhi-claw-container 2>/dev/null || true
  docker rm mozhi-claw-container 2>/dev/null || true
fi

# 启动容器
echo ""
echo "🚀 启动墨汁儿容器..."

docker run -d \
  --name mozhi-claw-container \
  --hostname mozhi \
  --network docker-claw-network \
  --restart unless-stopped \
  -e AGENT_NAME=mozhi \
  -e AGENT_ROLE=reviewer \
  -e GITHUB_TOKEN="$GITHUB_TOKEN" \
  -e GITHUB_REPO="" \
  -e GIT_USER_NAME="${MOZHI_GIT_NAME:-Mozhi}" \
  -e GIT_USER_EMAIL="${GIT_USER_EMAIL:-mozhi@docker-claw.local}" \
  -e ZHIPU_API_KEY="$MOZHI_API_KEY" \
  -e OPENCLAW_MODEL="${MOZHI_MODEL:-zhipu/glm-5}" \
  -v "$PROJECT_ROOT/shared:/shared:rw" \
  -v "$WORKSPACE_PATH:/workspace:rw" \
  -v "$PROJECT_ROOT/config/mozhi:/app/.openclaw/workspace:ro" \
  -v "$HOME/.gitconfig:/root/.gitconfig:ro" \
  -v "$HOME/.ssh:/root/.ssh:ro" \
  -v "$PROJECT_ROOT/config/mozhi/.openclaw:/root/.openclaw:rw" \
  -w /workspace \
  --cpus="2" \
  --memory="4g" \
  docker-claw:latest \
  openclaw gateway --port 18790

# 等待容器启动
echo "等待容器启动..."
sleep 5

# 检查容器状态
if docker ps | grep -q "mozhi-claw-container"; then
  echo "✅ 墨汁儿容器启动成功"
else
  echo "❌ 墨汁儿容器启动失败"
  echo "查看日志: docker logs mozhi-claw-container"
  exit 1
fi

# 初始化OpenClaw（容器内）
echo ""
echo "⚙️ 初始化OpenClaw..."

# 等待容器完全启动
echo "等待容器完全启动..."
sleep 10

# 创建配置文件
docker exec mozhi-claw-container bash -c "
  mkdir -p /app/.openclaw && \
  echo '{\"gateway\":{\"mode\":\"local\"}}' > /app/.openclaw/openclaw.json
"

echo "✅ 配置文件已创建"

# 初始化workspace
docker exec mozhi-claw-container bash -c "
  mkdir -p /app/.openclaw/workspace && \
  cd /app/.openclaw/workspace && \
  if [ ! -f 'BOOTSTRAP.md' ]; then \
    openclaw setup; \
  fi
"

echo "✅ OpenClaw初始化完成"

# 显示状态
echo ""
echo "================================"
echo "✅ 墨汁儿启动成功！"
echo "================================"
echo ""
echo "📋 信息:"
echo "  - Agent: 墨汁儿 (审查者)"
echo "  - 容器名: mozhi-claw-container"
echo "  - 工作目录: $WORKSPACE_PATH"
echo "  - 共享目录: $PROJECT_ROOT/shared"
echo ""
echo "📊 查看状态:"
echo "  docker ps | grep mozhi"
echo "  docker exec mozhi-claw-container openclaw status"
echo ""
echo "📝 查看日志:"
echo "  docker logs -f mozhi-claw-container"
echo "  tail -f $PROJECT_ROOT/shared/logs/mozhi.log"
echo ""
echo "🖥️ 进入容器:"
echo "  docker exec -it mozhi-claw-container bash"
echo ""
echo "🛑 停止墨汁儿:"
echo "  docker stop mozhi-claw-container"
echo ""
