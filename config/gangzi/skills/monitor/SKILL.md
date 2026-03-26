---
name: monitor
description: 读取 task.json 并生成进度观察结果
triggers:
  - heartbeat: true
  - manual: true
---

# Monitor Skill

## 执行步骤

### 1. 读取任务配置

```bash
cd /workspace/task-publish-repo

if [ ! -f "task-config.json" ]; then
  echo "task-config.json 不存在"
  exit 0
fi

REPO=$(jq -r '.repo' task-config.json)
BRANCH=$(jq -r '.branch' task-config.json)
REPO_NAME=$(basename "$REPO" .git)
```

### 2. 同步目标仓库

```bash
cd /workspace

if [ ! -d "$REPO_NAME" ]; then
  git clone "$REPO" "$REPO_NAME"
fi

cd "$REPO_NAME"
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"
```

### 3. 读取 task.json

```bash
if [ ! -f "task.json" ]; then
  echo "task.json 不存在"
  exit 0
fi

task_title=$(jq -r '.task.title' task.json)
developer_status=$(jq -r '.developer.status' task.json)
reviewer_status=$(jq -r '.reviewer.status' task.json)
review_result=$(jq -r '.review.summary.result // "pending"' task.json)
round=$(jq -r '.workflow.round' task.json)
archived=$(jq -r '.workflow.archived' task.json)
done_count=$(jq '[.milestones[] | select(.status == "done")] | length' task.json)
total_count=$(jq '.milestones | length' task.json)
```

### 4. 输出观察结果

```bash
echo "任务: $task_title"
echo "开发者状态: $developer_status"
echo "审查者状态: $reviewer_status"
echo "审查结果: $review_result"
echo "当前轮次: $round"
echo "里程碑进度: $done_count/$total_count"
echo "已归档: $archived"
```
