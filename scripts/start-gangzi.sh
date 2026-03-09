#!/bin/bash

# start-gangzi.sh - 启动刚子（宿主机）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================"
echo "启动刚子（协调者）"
echo "================================"
echo ""

# 检查依赖
echo "🔍 检查依赖..."

# 检查OpenClaw
if ! command -v openclaw &> /dev/null; then
  echo "❌ OpenClaw未安装"
  echo "请先安装OpenClaw: npm install -g openclaw"
  exit 1
fi

# 检查Git
if ! command -v git &> /dev/null; then
  echo "❌ Git未安装"
  exit 1
fi

# 检查jq
if ! command -v jq &> /dev/null; then
  echo "❌ jq未安装"
  echo "请先安装jq: apt-get install jq 或 brew install jq"
  exit 1
fi

echo "✅ 依赖检查通过"

# 设置环境变量
echo ""
echo "📝 设置环境变量..."

export AGENT_NAME="gangzi"
export AGENT_ROLE="coordinator"

# 检查必要的环境变量
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "⚠️ 警告: GITHUB_TOKEN 未设置"
  read -p "是否继续? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

if [[ -z "$ZHIPU_API_KEY" ]]; then
  echo "⚠️ 警告: ZHIPU_API_KEY 未设置"
  read -p "是否继续? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo "✅ 环境变量已设置"

# 初始化共享目录
echo ""
echo "📁 初始化共享目录..."

if [ ! -f "$PROJECT_ROOT/shared/config.json" ]; then
  echo "运行 init-shared.sh..."
  "$PROJECT_ROOT/scripts/init-shared.sh"
else
  echo "✅ 共享目录已存在"
fi

# 复制配置文件到OpenClaw工作目录
echo ""
echo "📋 复制配置文件..."

OPENCLAW_WORKSPACE="$HOME/.openclaw/workspace"
mkdir -p "$OPENCLAW_WORKSPACE"

# 复制刚子的配置文件
cp -r "$PROJECT_ROOT/config/gangzi/"* "$OPENCLAW_WORKSPACE/"

echo "✅ 配置文件已复制到 $OPENCLAW_WORKSPACE"

# 配置OpenClaw
echo ""
echo "⚙️ 配置OpenClaw..."

OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"

if [ ! -f "$OPENCLAW_CONFIG" ]; then
  echo "创建 openclaw.json..."
  
  cat > "$OPENCLAW_CONFIG" <<EOF
{
  "agents": {
    "defaults": {
      "workspace": "$OPENCLAW_WORKSPACE",
      "heartbeat": {
        "enabled": true,
        "intervalMs": 600000
      }
    }
  },
  "models": {
    "default": "zhipu/glm-4"
  }
}
EOF
  
  echo "✅ openclaw.json 已创建"
else
  echo "✅ openclaw.json 已存在"
fi

# 启动OpenClaw Gateway
echo ""
echo "🚀 启动OpenClaw Gateway..."

# 检查Gateway是否已运行
if pgrep -f "openclaw gateway" > /dev/null; then
  echo "⚠️ OpenClaw Gateway 已在运行"
  read -p "是否重启? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "停止现有Gateway..."
    openclaw gateway stop
    sleep 2
  else
    echo "跳过启动"
    exit 0
  fi
fi

# 启动Gateway
openclaw gateway start

# 等待Gateway启动
echo "等待Gateway启动..."
sleep 5

# 检查Gateway状态
if openclaw gateway status | grep -q "running"; then
  echo "✅ OpenClaw Gateway 启动成功"
else
  echo "❌ OpenClaw Gateway 启动失败"
  echo "查看日志: openclaw logs"
  exit 1
fi

# 显示状态
echo ""
echo "================================"
echo "✅ 刚子启动成功！"
echo "================================"
echo ""
echo "📋 信息:"
echo "  - Agent: 刚子 (协调者)"
echo "  - 工作目录: $OPENCLAW_WORKSPACE"
echo "  - 共享目录: $PROJECT_ROOT/shared"
echo "  - Gateway: 运行中"
echo ""
echo "📊 查看状态:"
echo "  openclaw gateway status"
echo ""
echo "📝 查看日志:"
echo "  openclaw logs"
echo "  tail -f $PROJECT_ROOT/shared/logs/gangzi.log"
echo ""
echo "🛑 停止刚子:"
echo "  openclaw gateway stop"
echo ""
