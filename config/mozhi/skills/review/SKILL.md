---
name: review
description: 审查代码并将结果写入task.json
triggers:
  - manual: true
---

# Review Skill

## 执行步骤

### 1. 读取任务配置和 task.json

```bash
eval $(python3 /scripts/read_task_config.py)
cd "/workspace/$REPO_NAME"

if [ ! -f "task.json" ]; then
  echo "task.json 不存在"
  exit 1
fi

current_round=$(python3 /scripts/parse_task.py --round-only task.json)
task_title=$(python3 /scripts/parse_task.py --title-only task.json)
```

### 2. 执行测试

```bash
test_result=0
passed=0
failed=0
test_cases=0

if [ -f "package.json" ]; then
  npm test || test_result=$?
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  python -m pytest || test_result=$?
elif [ -f "go.mod" ]; then
  go test ./... || test_result=$?
elif [ -f "Cargo.toml" ]; then
  cargo test || test_result=$?
else
  echo "未检测到测试框架，按代码审查路径继续"
fi

if [[ $test_result -ne 0 ]]; then
  failed=1
  test_cases=1
else
  passed=1
  test_cases=1
fi
```

### 3. 汇总审查结果

```bash
if [[ $failed -gt 0 ]]; then
  issues='[
    {
      "id": 1,
      "title": "自动化测试未通过",
      "severity": "high",
      "status": "open",
      "source_round": '"$current_round"',
      "resolved_in_round": null,
      "comment": "至少一个测试命令执行失败，需要开发者修复后重新审查"
    }
  ]'

  python3 /scripts/parse_task.py --replace-review-issues "$issues" task.json
  python3 /scripts/parse_task.py --set-review-summary changes_requested "发现需要修复的问题，请开发者处理后重新提交审查" task.json
  python3 /scripts/parse_task.py --set-reviewer-status "等待修复" task.json
  python3 /scripts/parse_task.py --append-reviewer-note "第${current_round}轮审查发现问题，等待开发者修复" task.json
  phase="等待修复"
else
  python3 /scripts/parse_task.py --replace-review-issues "[]" task.json
  python3 /scripts/parse_task.py --set-review-summary passed "审查通过，可以归档" task.json
  python3 /scripts/parse_task.py --set-reviewer-status "审查通过" task.json
  python3 /scripts/parse_task.py --append-reviewer-note "第${current_round}轮审查通过" task.json
  phase="审查通过"
fi
```

### 4. 更新观测状态

```bash
python3 /scripts/write_status.py \
  --phase "$phase" \
  --repo "$REPO_NAME" \
  --branch "$BRANCH" \
  --review-round "$current_round" \
  --passed "$passed" \
  --failed "$failed" \
  --test-cases "$test_cases"
```

---

_墨汁儿的技能：审查代码 🦊_
