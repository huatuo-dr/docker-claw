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

### 3. 获取当前测试轮次并更新状态

```bash
# get current test round (0 if first time developing)
current_round=$(python3 /scripts/parse_milestone.py --get-test-round milestone.md)

python3 /scripts/write_status.py --phase "开发中" --repo "$REPO_NAME" --branch "$BRANCH" --test-round "$current_round"
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

  # get milestone goal via Python
  goal=$(python3 /scripts/parse_milestone.py --goal $milestone_num milestone.md)

  # update milestone status to "进行中" via Python
  python3 /scripts/parse_milestone.py --update-status "${milestone_num}:🔄" milestone.md

  # === AI generates and writes code here ===

  # commit
  git add .
  git commit -m "M${milestone_num}: ${goal}"
  total_commits=$((total_commits + 1))

  # update milestone status to "已完成" via Python
  python3 /scripts/parse_milestone.py --update-status "${milestone_num}:✅" milestone.md

  echo "✅ 里程碑 $milestone_num 完成"
done
```

### 6. 本地测试

```bash
echo "开始本地测试..."

test_result=0

if [ -f "package.json" ]; then
  npm test || test_result=$?
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  python -m pytest || test_result=$?
elif [ -f "go.mod" ]; then
  go test ./... || test_result=$?
elif [ -f "Cargo.toml" ]; then
  cargo test || test_result=$?
else
  echo "未检测到测试框架，跳过测试"
fi

if [[ $test_result -ne 0 ]]; then
  echo "❌ 测试失败，不push"
  exit 1
fi

echo "✅ 测试通过"
```

### 7. 更新 milestone.md 开发状态并 Push

```bash
# calculate next test round
next_round=$((current_round + 1))

# update dev status via Python
python3 /scripts/parse_milestone.py --set-dev-status "等待第${next_round}轮测试" milestone.md

git add .
git commit -m "更新开发状态: 等待第${next_round}轮测试"

# push
git push origin "$BRANCH"
```

### 8. 更新最终状态

```bash
python3 /scripts/write_status.py \
  --phase "等待第${next_round}轮测试" \
  --repo "$REPO_NAME" \
  --branch "$BRANCH" \
  --test-round $next_round \
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
