---
name: develop
description: 开发功能，读取milestone.md并实现代码
triggers:
  - manual: true
  - event: heartbeat_new_task
---

# Develop Skill

## 功能

读取 milestone.md，逐步实现功能代码。

## 执行步骤

### 1. 读取任务配置

```bash
# Python handles JSON parsing, outputs shell variables
eval $(python3 /scripts/read_task_config.py)
# now available: $REPO, $BRANCH, $REPO_NAME, $BRANCH_SAFE, $STATUS_DIR, $STATUS_FILE

cd /workspace/$REPO_NAME
```

### 2. 检查任务状态

```bash
# check branch
current_branch=$(git branch --show-current)
if [[ "$current_branch" != "$BRANCH" ]]; then
  echo "错误: 当前分支 $current_branch，应该是 $BRANCH"
  exit 1
fi

# check milestone.md
if [ ! -f "milestone.md" ]; then
  echo "错误: milestone.md 不存在"
  exit 1
fi
```

### 3. 更新状态为"开发中"

```bash
python3 /scripts/write_status.py --phase "开发中" --repo "$REPO_NAME" --branch "$BRANCH"
```

### 4. 读取并解析 milestone.md

```bash
# get pending milestone numbers (space-separated)
PENDING=$(python3 /scripts/parse_milestone.py --pending-only milestone.md)

if [ -z "$PENDING" ]; then
  echo "没有待完成的里程碑"
  exit 0
fi

echo "待完成里程碑: $PENDING"
```

### 5. 逐个完成里程碑

```bash
total_commits=0

for milestone_num in $PENDING; do
  echo "========================================"
  echo "开始处理 里程碑 $milestone_num"
  echo "========================================"

  # get milestone details via Python
  goal=$(python3 -c "
import json, sys
data = json.loads(open('milestone.md.parsed.json' if False else '/dev/stdin').read())
ms = [m for m in data['milestones'] if m['number'] == $milestone_num]
print(ms[0]['goal'] if ms else '')
" < <(python3 /scripts/parse_milestone.py milestone.md))

  # update milestone status to "进行中"
  sed -i "/## 里程碑 $milestone_num/,/状态:/ s/⬜ 待开始/🔄 进行中/" milestone.md

  # === AI generates and writes code here ===

  # commit
  git add .
  git commit -m "M${milestone_num}: ${goal}"
  total_commits=$((total_commits + 1))

  # update milestone status to "已完成"
  sed -i "/## 里程碑 $milestone_num/,/状态:/ s/🔄 进行中/✅ 已完成/" milestone.md

  echo "✅ 里程碑 $milestone_num 完成"
done
```

### 6. 本地测试

```bash
echo "开始本地测试..."

if [ -f "package.json" ]; then
  npm test
elif [ -f "requirements.txt" ]; then
  python -m pytest
elif [ -f "go.mod" ]; then
  go test ./...
fi

test_result=$?

if [[ $test_result -ne 0 ]]; then
  echo "❌ 测试失败，不push"
  exit 1
fi

echo "✅ 测试通过"
```

### 7. 更新 milestone.md 开发状态并 Push

```bash
# update milestone.md dev status
sed -i 's/\*\*状态\*\*: 开发中/**状态**: 等待第1轮测试/' milestone.md

git add .
git commit -m "更新开发状态: 等待第1轮测试"

# push
git push origin "$BRANCH"
```

### 8. 更新最终状态

```bash
python3 /scripts/write_status.py \
  --phase "等待第1轮测试" \
  --repo "$REPO_NAME" \
  --branch "$BRANCH" \
  --test-round 1 \
  --commits $total_commits
```

---

## 注意事项

1. **本地commit多个**：不要每个里程碑都push
2. **所有完成后push**：只在所有milestone完成后才push
3. **本地测试**：push前必须测试
4. **更新状态**：每个关键节点都更新 jianbing-status.json

---

_煎饼的技能：开发功能 🐶_
