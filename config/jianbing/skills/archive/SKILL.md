---
name: archive
description: 归档任务，移动task.json到归档目录并push
triggers:
  - event: heartbeat_archivable
---

# Archive Skill

## 功能

检测到 task.json 审查通过时，执行归档操作。

## 执行前提检查

```bash
# read task config
eval $(python3 /scripts/read_task_config.py)

cd /workspace/$REPO_NAME

# check review result
REVIEW_RESULT=$(python3 /scripts/parse_task.py --review-result-only task.json)
REVIEW_STATUS=$(python3 /scripts/parse_task.py --reviewer-status-only task.json)
if [[ "$REVIEW_RESULT" != "passed" && "$REVIEW_STATUS" != "审查通过" ]]; then
  echo "审查尚未通过，跳过"
  exit 0
fi
```

## 执行步骤

### 1. 更新状态为"归档中"

```bash
python3 /scripts/parse_task.py --set-developer-status "归档中" task.json
python3 /scripts/parse_task.py --append-developer-note "开始归档任务" task.json
```

### 2. 获取序号并移动 task.json

```bash
# create milestones dir if not exists
mkdir -p milestones

# get next number
next_num=$(ls milestones/ 2>/dev/null | wc -l | awk '{printf "%02d", $1+1}')

# update final task state before archive
python3 /scripts/parse_task.py --set-archived true task.json
python3 /scripts/parse_task.py --set-developer-status "已完成" task.json
python3 /scripts/parse_task.py --append-developer-note "归档完成" task.json

# extract task name from task.json
task_name=$(python3 /scripts/parse_task.py --title-only task.json)
task_name_safe=$(printf '%s' "$task_name" | tr '/:' '__')

# move
mv task.json "milestones/${next_num}_${task_name_safe}.json"
```

### 3. 提交并推送

```bash
git add .
git commit -m "归档: ${task_name}"
git push origin "$BRANCH"
```

## 注意事项

1. **不做分支合并** — 分支合并由负责人处理
2. **不删除分支** — 分支管理由负责人处理
3. **仅移动+push** — 归档操作只移动 task.json 并推送

---

_煎饼的技能：归档任务 🐶_
