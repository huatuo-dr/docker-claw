#!/bin/bash
# M3: 启动 Mozhi-Claw 容器脚本

CONTAINER_NAME="mozhi-claw-container"
IMAGE_NAME="mozhi-claw:m2"
CONFIG_DIR="$(pwd)/config/mozhi"

echo "🚀 启动 Mozhi-Claw 容器..."

# 创建配置目录
mkdir -p $CONFIG_DIR

# 停止并删除旧容器（如果存在）
docker stop $CONTAINER_NAME 2>/dev/null
docker rm $CONTAINER_NAME 2>/dev/null

# 启动新容器
docker run -d \
    --name $CONTAINER_NAME \
    -v $CONFIG_DIR:/app/.openclaw \
    -w /app \
    $IMAGE_NAME \
    tail -f /dev/null

echo "✅ 容器已启动: $CONTAINER_NAME"
echo "📁 配置目录: $CONFIG_DIR"
echo ""
echo "常用命令:"
echo "  docker exec -it $CONTAINER_NAME bash    # 进入容器"
echo "  docker logs $CONTAINER_NAME              # 查看日志"
echo "  docker stop $CONTAINER_NAME              # 停止容器"
