---
name: develop
description: 开发功能，读取task.json并实现代码
triggers:
  - manual: true
  - event: heartbeat_new_task
---

# Develop Skill

## 功能

读取 task.json，逐步实现功能代码。

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

# check task.json
if [ ! -f "task.json" ]; then
  echo "错误: task.json 不存在"
  exit 1
fi
```

### 3. 获取当前测试轮次并更新状态

```bash
# get current test round (0 if first time developing)
current_round=$(python3 /scripts/parse_task.py --round-only task.json)
review_result=$(python3 /scripts/parse_task.py --review-result-only task.json)
review_status=$(python3 /scripts/parse_task.py --reviewer-status-only task.json)

if [[ "$review_result" = "changes_requested" || "$review_status" = "等待修复" ]]; then
  dev_phase="修复中"
else
  dev_phase="开发中"
fi

python3 /scripts/write_status.py --phase "$dev_phase" --repo "$REPO_NAME" --branch "$BRANCH" --test-round "$current_round"
python3 /scripts/parse_task.py --set-developer-status "$dev_phase" task.json
```

### 4. 读取并解析 task.json

```bash
# get pending milestone numbers (space-separated)
PENDING=$(python3 /scripts/parse_task.py --pending-only task.json)

if [ -z "$PENDING" ]; then
  if [[ "$review_result" = "changes_requested" || "$review_status" = "等待修复" ]]; then
    echo "没有待完成的里程碑，按审查意见修复现有实现"
  else
    echo "没有待完成的里程碑"
    exit 0
  fi
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
  goal=$(python3 /scripts/parse_task.py --goal $milestone_num task.json)

  # update milestone status to in_progress via Python
  python3 /scripts/parse_task.py --set-milestone-status "${milestone_num}:in_progress" task.json
  python3 /scripts/parse_task.py --append-developer-note "开始处理里程碑 ${milestone_num}" task.json

  # === AI generates and writes code here ===

  # commit
  git add .
  git commit -m "M${milestone_num}: ${goal}"
  total_commits=$((total_commits + 1))

  # update milestone status to done via Python
  python3 /scripts/parse_task.py --set-milestone-status "${milestone_num}:done" task.json
  python3 /scripts/parse_task.py --append-developer-note "完成里程碑 ${milestone_num}" task.json

  echo "✅ 里程碑 $milestone_num 完成"
done

if [[ -z "$PENDING" && "$dev_phase" = "修复中" ]]; then
  python3 /scripts/parse_task.py --append-developer-note "根据审查意见进行修复" task.json
fi
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

### 7. 更新 task.json 开发状态并 Push

```bash
# calculate next test round
next_round=$((current_round + 1))

# update task.json via Python
python3 /scripts/parse_task.py --set-round "$next_round" task.json
python3 /scripts/parse_task.py --set-developer-status "等待审查" task.json
python3 /scripts/parse_task.py --append-developer-note "提交开发结果，等待第${next_round}轮审查" task.json

git add .
git commit -m "更新开发状态: 等待第${next_round}轮审查"

# push
git push origin "$BRANCH"
```

### 8. 更新最终状态

```bash
python3 /scripts/write_status.py \
  --phase "等待审查" \
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
