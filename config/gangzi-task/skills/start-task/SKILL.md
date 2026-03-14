# SKILL.md - 启动任务

## 触发条件

当 task-publish-repo 中有新的任务配置时触发。

## 执行步骤

### 1. 解析任务配置

```json
{
  "repo": "https://github.com/xxx/yyy",
  "branch": "feature-xxx",
  "milestone_version": "v1.0.0"
}
```

### 2. Clone 目标仓库

```bash
git clone {repo} /workspace/target-repo
cd /workspace/target-repo
git checkout -b {branch}
```

### 3. 创建 milestone.md

```bash
# 复制模板
cp /shared/templates/milestone.template.md milestone.md

# 替换占位符
sed -i "s/{version}/{milestone_version}/g" milestone.md
sed -i "s/{待开发|...}/待开发/g" milestone.md
```

### 4. 更新全局配置

```bash
cat > /shared/config.json <<EOF
{
  "status": "待开发",
  "current_task": {
    "repo": "{repo}",
    "branch": "{branch}",
    "milestone_version": "{milestone_version}"
  }
}
EOF
```

### 5. 自动提交（防冲突）

```bash
# 设置Git用户信息
git config user.name "刚子"
git config user.email "gangzi@docker-claw.local"

# 获取最新代码（防冲突）
git fetch origin
git pull --rebase origin {branch}

# 如果有冲突:
# - 停止提交
# - 报告错误给用户

# 提交变更
git add milestone.md
git commit -m "刚子: 创建里程碑文档"

# 推送到远程
git push origin {branch}
```

### 6. 通知刚子-监控

```bash
# 通知刚子-监控开始监控
docker exec gangzi-monitor-container /bin/bash -c \
  'openclaw agent --local --agent main --message "新任务已创建: {milestone_version}"'
```

---

## 输出

- milestone.md 已创建并提交
- config.json 已更新
- 刚子-监控已通知
