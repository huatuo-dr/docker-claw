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

# 检查刚子的API Key（Kimi）
if [[ -z "$GANGZI_API_KEY" ]]; then
  echo "⚠️ 警告: GANGZI_API_KEY 未设置（刚子使用Kimi模型）"
  read -p "是否继续? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# 设置刚子使用的模型和API Key
export MOONSHOT_API_KEY="$GANGZI_API_KEY"
export OPENCLAW_MODEL="${GANGZI_MODEL:-moonshot/kimi-k2.5}"

# 飞书配置（如果设置了的话）
if [[ -n "$FEISHU_APP_ID" ]]; then
  export FEISHU_APP_ID="$FEISHU_APP_ID"
  echo "✅ 飞书配置已加载"
fi

if [[ -n "$FEISHU_APP_SECRET" ]]; then
  export FEISHU_APP_SECRET="$FEISHU_APP_SECRET"
fi

# Git配置
export GIT_USER_NAME="${GANGZI_GIT_NAME:-Gangzi}"
export GIT_USER_EMAIL="${GIT_USER_EMAIL:-gangzi@docker-claw.local}"
echo "✅ Git配置已加载: $GIT_USER_NAME <$GIT_USER_EMAIL>"

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
  "wizard": {
    "lastRunMode": "local"
  },
  "models": {},
  "gateway": {
    "mode": "local"
  },
  "agents": {
    "defaults": {
      "workspace": "$OPENCLAW_WORKSPACE"
    }
  },
  "channels": {},
  "plugins": {
    "entries": {}
  }
}
EOF

  echo "✅ openclaw.json 已创建"

  # 配置 Kimi API Key
  if [[ -n "$GANGZI_API_KEY" ]]; then
    echo "🔧 配置 Kimi API Key..."
    mkdir -p "$HOME/.openclaw/agents/main/agent"
    cat > "$HOME/.openclaw/agents/main/agent/auth-profiles.json" << EOF
{
  "version": 1,
  "profiles": {
    "moonshot:default": {
      "type": "api_key",
      "provider": "moonshot",
      "key": "$GANGZI_API_KEY"
    }
  }
}
EOF
    echo "✅ auth-profiles.json 已创建"
  fi

  # 配置飞书通道
  if [[ -n "$FEISHU_APP_ID" && -n "$FEISHU_APP_SECRET" ]]; then
    echo "配置飞书通道..."
    openclaw config set channels.feishu.enabled true
    openclaw config set channels.feishu.appId "$FEISHU_APP_ID"
    openclaw config set channels.feishu.appSecret "$FEISHU_APP_SECRET"
    openclaw config set plugins.entries.feishu.enabled true
    echo "✅ 飞书通道已配置"
  fi
else
  echo "✅ openclaw.json 已存在"

  # 检查并创建 auth-profiles.json（如果不存在）
  if [[ -n "$GANGZI_API_KEY" ]] && [[ ! -f "$HOME/.openclaw/agents/main/agent/auth-profiles.json" ]]; then
    echo "🔧 配置 Kimi API Key..."
    mkdir -p "$HOME/.openclaw/agents/main/agent"
    cat > "$HOME/.openclaw/agents/main/agent/auth-profiles.json" << EOF
{
  "version": 1,
  "profiles": {
    "moonshot:default": {
      "type": "api_key",
      "provider": "moonshot",
      "key": "$GANGZI_API_KEY"
    }
  }
}
EOF
    echo "✅ auth-profiles.json 已创建"
  fi

  # 如果飞书配置存在但未在配置文件中，添加它
  if [[ -n "$FEISHU_APP_ID" && -n "$FEISHU_APP_SECRET" ]]; then
    if ! grep -q "feishu" "$OPENCLAW_CONFIG" 2>/dev/null; then
      echo "添加飞书通道配置..."
      openclaw config set channels.feishu.enabled true
      openclaw config set channels.feishu.appId "$FEISHU_APP_ID"
      openclaw config set channels.feishu.appSecret "$FEISHU_APP_SECRET"
      openclaw config set plugins.entries.feishu.enabled true
      echo "✅ 飞书通道已添加"
    else
      echo "✅ 飞书通道已存在"
    fi
  fi
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
