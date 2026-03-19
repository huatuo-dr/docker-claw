---
name: archive
description: 归档任务，移动milestone到归档目录并push
triggers:
  - event: heartbeat_archivable
---

# Archive Skill

## 功能

检测到 milestone.md 状态为"可归档"时，执行归档操作。

## 执行前提检查

```bash
# read task config
eval $(python3 /scripts/read_task_config.py)

cd /workspace/$REPO_NAME

# check milestone status
DEV_STATUS=$(python3 /scripts/parse_milestone.py --status-only milestone.md)
if [[ "$DEV_STATUS" != "可归档" ]]; then
  echo "状态不是可归档，跳过"
  exit 0
fi
```

## 执行步骤

### 1. 更新状态为"执行归档"

```bash
python3 /scripts/write_status.py --phase "执行归档" --repo "$REPO_NAME" --branch "$BRANCH"
```

### 2. 获取序号并移动 milestone

```bash
# create milestones dir if not exists
mkdir -p milestones

# get next number
next_num=$(ls milestones/ 2>/dev/null | wc -l | awk '{printf "%02d", $1+1}')

# extract task name from milestone.md title
task_name=$(head -1 milestone.md | sed 's/^# Milestone: //')

# move
mv milestone.md "milestones/${next_num}_${task_name}.md"
```

### 3. 提交并推送

```bash
git add .
git commit -m "归档: ${task_name}"
git push origin "$BRANCH"
```

### 4. 更新最终状态

```bash
python3 /scripts/write_status.py --phase "等待任务" --clear-task --status-file "$STATUS_FILE"
```

---

## 注意事项

1. **不做分支合并** — 分支合并由负责人处理
2. **不删除分支** — 分支管理由负责人处理
3. **仅移动+push** — 归档操作只移动 milestone.md 并推送

---

_煎饼的技能：归档任务 🐶_
