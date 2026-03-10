#!/bin/bash

# start-all.sh - 启动所有Agent（刚子、煎饼、墨汁儿）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================"
echo "启动 Docker-Claw 多Agent系统"
echo "================================"
echo ""

# 检查环境变量
echo "🔍 检查环境变量..."

ENV_MISSING=0

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "❌ GITHUB_TOKEN 未设置"
  ENV_MISSING=1
fi

if [[ -z "$GANGZI_API_KEY" ]]; then
  echo "❌ GANGZI_API_KEY 未设置（刚子使用Kimi）"
  ENV_MISSING=1
fi

if [[ -z "$JIANBING_API_KEY" ]]; then
  echo "❌ JIANBING_API_KEY 未设置（煎饼使用MiniMax）"
  ENV_MISSING=1
fi

if [[ -z "$MOZHI_API_KEY" ]]; then
  echo "❌ MOZHI_API_KEY 未设置（墨汁儿使用智谱GLM）"
  ENV_MISSING=1
fi

if [[ $ENV_MISSING -eq 1 ]]; then
  echo ""
  echo "请在 .env 文件中设置必要的环境变量:"
  echo "  GITHUB_TOKEN=ghp_xxx"
  echo "  GANGZI_API_KEY=sk-kimi-xxx"
  echo "  JIANBING_API_KEY=sk-minimax-xxx"
  echo "  MOZHI_API_KEY=xxx.zhipu-xxx"
  echo ""
  echo "可选环境变量:"
  echo "  FEISHU_APP_ID=cli_xxx          # 飞书通讯"
  echo "  FEISHU_APP_SECRET=xxx          # 飞书通讯"
  echo "  GIT_USER_EMAIL=your@email.com  # Git提交邮箱"
  echo "  WORKSPACE_PATH=./workspace     # 工作目录"
  exit 1
fi

echo "✅ 环境变量检查通过"

# 显示配置信息
echo ""
echo "📋 配置信息:"
echo "  - 刚子模型: ${GANGZI_MODEL:-moonshot/kimi-k2.5}"
echo "  - 煎饼模型: ${JIANBING_MODEL:-minimax/MiniMax-M2.5}"
echo "  - 墨汁儿模型: ${MOZHI_MODEL:-zhipu/glm-5}"
if [[ -n "$FEISHU_APP_ID" ]]; then
  echo "  - 飞书通讯: 已配置"
fi

# 初始化共享目录
echo ""
echo "📁 初始化共享目录..."

if [ ! -f "$PROJECT_ROOT/shared/config.json" ]; then
  echo "运行 init-shared.sh..."
  "$PROJECT_ROOT/scripts/init-shared.sh"
else
  echo "✅ 共享目录已存在"
fi

# 1. 启动刚子（宿主机）
echo ""
echo "================================"
echo "1/3 启动刚子（协调者）"
echo "================================"

"$PROJECT_ROOT/scripts/start-gangzi.sh"

# 等待刚子启动
sleep 3

# 2. 启动煎饼（容器）
echo ""
echo "================================"
echo "2/3 启动煎饼（开发者）"
echo "================================"

"$PROJECT_ROOT/scripts/start-jianbing.sh"

# 等待煎饼启动
sleep 3

# 3. 启动墨汁儿（容器）
echo ""
echo "================================"
echo "3/3 启动墨汁儿（审查者）"
echo "================================"

"$PROJECT_ROOT/scripts/start-mozhi.sh"

# 显示最终状态
echo ""
echo "================================"
echo "🎉 所有Agent启动成功！"
echo "================================"
echo ""
echo "📋 Agent状态:"
echo ""
echo "🤖 刚子（协调者）:"
echo "  - 位置: 宿主机"
echo "  - Gateway: $(openclaw gateway status 2>/dev/null | grep -o 'running\|stopped' || echo '未知')"
echo "  - 状态文件: $PROJECT_ROOT/shared/status/gangzi.json"
echo ""
echo "🐶 煎饼（开发者）:"
echo "  - 容器: jianbing-claw-container"
echo "  - 状态: $(docker ps --filter name=jianbing-claw-container --format '{{.Status}}')"
echo "  - 状态文件: $PROJECT_ROOT/shared/status/jianbing.json"
echo ""
echo "🦊 墨汁儿（审查者）:"
echo "  - 容器: mozhi-claw-container"
echo "  - 状态: $(docker ps --filter name=mozhi-claw-container --format '{{.Status}}')"
echo "  - 状态文件: $PROJECT_ROOT/shared/status/mozhi.json"
echo ""
echo "📊 监控命令:"
echo ""
echo "  # 查看所有容器状态"
echo "  docker ps"
echo ""
echo "  # 查看刚子日志"
echo "  tail -f $PROJECT_ROOT/shared/logs/gangzi.log"
echo ""
echo "  # 查看煎饼日志"
echo "  docker logs -f jianbing-claw-container"
echo ""
echo "  # 查看墨汁儿日志"
echo "  docker logs -f mozhi-claw-container"
echo ""
echo "  # 查看任务状态"
echo "  cat $PROJECT_ROOT/shared/status/summary.json | jq ."
echo ""
echo "🛑 停止所有Agent:"
echo ""
echo "  # 停止刚子"
echo "  openclaw gateway stop"
echo ""
echo "  # 停止煎饼和墨汁儿"
echo "  docker stop jianbing-claw-container mozhi-claw-container"
echo ""
echo "  # 停止并删除容器"
echo "  docker-compose -f $PROJECT_ROOT/docker-compose.yml down"
echo ""
