# Docker-Claw

多 Agent 协作开发系统（负责人+开发者+审查员），各 Agent 独立工作，互不感知

## 仓库
- 任务发布: huatuo-dr/task-publish-repo (master)
- 开发: huatuo-dr/test-task-repo (task/*)

## 流程
需求 → 负责人创里程碑 → 开发者开发 → 审查员测试 → 开发者归档 → 负责人合并分支

## 状态
待开发 → 开发中 → 等待第N轮测试 → 第N轮测试修复中 → ... → 可归档 → 执行归档 → 等待任务

## 规范
- 提交: `{角色}: {描述}` (如 `煎饼: M1: 实现登录`)
- 分支: `task/{名称}`
- 每次提交前 `git pull --rebase` 防冲突
- 归档不删分支，用户手动删除

## 常用
```bash
# 触发开发者
docker exec jianbing-claw-container openclaw agent --local --agent main --message "..."

# 触发审查员
docker exec mozhi-claw-container openclaw agent --local --agent main --message "..."
```

## 测试规则
当我们测试Agent之间的协作是，期间不能干预或影响Agent，只监控和记录，最后复盘

## 沟通规则
每次回答前，在内容前面加上：【K哥】

## 重新部署

```bash
# 1. 删除 docker 容器
docker rm -f jianbing-claw-container mozhi-claw-container

# 2. 清除 workspace 内容（在容器内用 root 删除）
docker run --rm -v $(pwd)/workspace:/workspace root rm -rf /workspace/*

# 3. 清除 shared 目录残留状态文件（在容器内用 root 删除）
docker run --rm -v $(pwd)/shared:/shared root find /shared -name "*-status.json" -delete

# 4. 重新创建容器
docker-compose up -d

# 5. 等待容器启动后，分别对话一次
docker exec jianbing-claw-container openclaw agent --local --agent main --message "你是谁"
docker exec mozhi-claw-container openclaw agent --local --agent main --message "你是谁"
```

**说明**：workspace 和 shared 中的状态文件属于容器内的 root 用户，需要用 root 容器来删除。
