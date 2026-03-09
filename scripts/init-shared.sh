#!/bin/bash

# init-shared.sh - 初始化共享目录和状态文件
# 用途：创建共享目录结构，初始化默认配置文件

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SHARED_DIR="$PROJECT_ROOT/shared"

echo "================================"
echo "初始化 Docker-Claw 共享目录"
echo "================================"
echo ""

# 创建目录结构
echo "📁 创建目录结构..."
mkdir -p "$SHARED_DIR"/{status,issues,locks,logs}

# 检查是否已存在配置文件
if [ -f "$SHARED_DIR/config.json" ]; then
  echo "⚠️  警告: config.json 已存在"
  read -p "是否覆盖? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 取消初始化"
    exit 1
  fi
fi

# 初始化 config.json
echo "📝 初始化 config.json..."
cp "$SHARED_DIR/templates/config.template.json" "$SHARED_DIR/config.json"

# 初始化状态文件
echo "📝 初始化状态文件..."
cp "$SHARED_DIR/templates/summary.template.json" "$SHARED_DIR/status/summary.json"
cp "$SHARED_DIR/templates/gangzi.template.json" "$SHARED_DIR/status/gangzi.json"
cp "$SHARED_DIR/templates/jianbing.template.json" "$SHARED_DIR/status/jianbing.json"
cp "$SHARED_DIR/templates/mozhi.template.json" "$SHARED_DIR/status/mozhi.json"

# 创建空的日志文件
echo "📝 创建日志文件..."
touch "$SHARED_DIR/logs/gangzi.log"
touch "$SHARED_DIR/logs/jianbing.log"
touch "$SHARED_DIR/logs/mozhi.log"

# 设置权限
echo "🔒 设置权限..."
chmod 666 "$SHARED_DIR"/*.json
chmod 666 "$SHARED_DIR"/status/*.json
chmod 666 "$SHARED_DIR"/logs/*.log
chmod 777 "$SHARED_DIR"/locks

# 显示目录结构
echo ""
echo "✅ 初始化完成！"
echo ""
echo "📂 目录结构:"
echo ""
tree -L 2 "$SHARED_DIR" 2>/dev/null || find "$SHARED_DIR" -type d -o -type f | head -20

echo ""
echo "📋 下一步操作:"
echo "1. 配置 GitHub 仓库信息 (编辑 shared/config.json)"
echo "2. 运行 start-task.sh 启动新任务"
echo "3. 监控日志: tail -f shared/logs/*.log"
echo ""
