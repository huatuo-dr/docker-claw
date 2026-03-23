---
name: check-commits
description: 检查代码提交（Cron 5分钟）
triggers:
  - cron: "*/5 * * * *"
---

# Check Commits Skill

## 执行步骤

### 1. 读取任务配置并同步仓库

```bash
eval $(python3 /scripts/read_task_config.py)

cd /workspace
if [ ! -d "$REPO_NAME" ]; then
  git clone "$REPO" "$REPO_NAME"
fi

cd "/workspace/$REPO_NAME"
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"
```

### 2. 检查 task.json 是否进入可审查状态

```bash
if [ ! -f "task.json" ]; then
  echo "task.json 不存在"
  exit 0
fi

developer_status=$(python3 /scripts/parse_task.py --developer-status-only task.json)
review_result=$(python3 /scripts/parse_task.py --review-result-only task.json)
review_round=$(python3 /scripts/parse_task.py --round-only task.json)

if [[ "$developer_status" != "等待审查" ]]; then
  echo "开发者当前不是等待审查"
  exit 0
fi

if [[ "$review_result" != "pending" && "$review_result" != "changes_requested" ]]; then
  echo "当前审查结果不需要继续审查"
  exit 0
fi
```

### 3. 更新观测状态

```bash
python3 /scripts/write_status.py \
  --phase "审查中" \
  --repo "$REPO_NAME" \
  --branch "$BRANCH" \
  --review-round "$review_round"
```

### 4. 调用 review 技能

```bash
call_skill "review"
```

---

_墨汁儿的技能：检查提交 🦊_
