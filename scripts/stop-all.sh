#!/bin/bash

# stop-all.sh - 停止所有Agent

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================"
echo "停止 Docker-Claw 多Agent系统"
echo "================================"
echo ""

# 1. 停止刚子（宿主机）
echo "🛑 停止刚子（宿主机）..."

if pgrep -f "openclaw gateway" > /dev/null; then
  openclaw gateway stop
  echo "✅ 刚子已停止"
else
  echo "⚠️ 刚子未运行"
fi

# 2. 停止煎饼（容器）
echo ""
echo "🛑 停止煎饼（容器）..."

if docker ps | grep -q "jianbing-claw-container"; then
  docker stop jianbing-claw-container
  echo "✅ 煎饼已停止"
else
  echo "⚠️ 煎饼未运行"
fi

# 3. 停止墨汁儿（容器）
echo ""
echo "🛑 停止墨汁儿（容器）..."

if docker ps | grep -q "mozhi-claw-container"; then
  docker stop mozhi-claw-container
  echo "✅ 墨汁儿已停止"
else
  echo "⚠️ 墨汁儿未运行"
fi

echo ""
echo "================================"
echo "✅ 所有Agent已停止"
echo "================================"
echo ""
echo "📝 注意:"
echo "  - 容器数据已保留"
echo "  - 共享文件已保留"
echo "  - 日志文件已保留"
echo ""
echo "🔄 重启所有Agent:"
echo "  $PROJECT_ROOT/scripts/start-all.sh"
echo ""
echo "🗑️ 完全清理（包括容器）:"
echo "  docker-compose -f $PROJECT_ROOT/docker-compose.yml down"
echo ""
