---
name: design-test
description: 设计测试计划
triggers:
  - event: new_task
---

# Design Test Skill

## 执行步骤

### 1. 读取任务配置和 task.json

```bash
eval $(python3 /scripts/read_task_config.py)
cd "/workspace/$REPO_NAME"

if [ ! -f "task.json" ]; then
  echo "task.json 不存在"
  exit 1
fi

task_title=$(python3 /scripts/parse_task.py --title-only task.json)
review_round=$(python3 /scripts/parse_task.py --round-only task.json)
```

### 2. 更新状态

```bash
python3 /scripts/write_status.py \
  --phase "测试设计中" \
  --repo "$REPO_NAME" \
  --branch "$BRANCH" \
  --review-round "$review_round"

python3 /scripts/parse_task.py --set-reviewer-status "测试设计中" task.json
python3 /scripts/parse_task.py --append-reviewer-note "开始为任务设计测试计划" task.json
```

### 3. 生成本地测试计划

```bash
mkdir -p /workspace/tmp
cat > /workspace/tmp/review-plan.md <<EOF
# ${task_title} - 测试计划

## 审查范围

- 覆盖 task.json 中的全部里程碑
- 校验正常流程、异常流程、边界情况和安全场景
- 结合当前项目的测试命令验证实现

## 审查关注点

- 功能是否与里程碑一致
- 异常处理是否完整
- 输入校验是否充分
- 安全边界是否缺失
- 自动化测试是否稳定
EOF
```

### 4. 更新 task.json 和观测状态

```bash
python3 /scripts/parse_task.py --set-reviewer-status "待审查" task.json
python3 /scripts/parse_task.py --append-reviewer-note "测试计划已准备完成，等待开发者提交审查" task.json
python3 /scripts/write_status.py \
  --phase "待审查" \
  --repo "$REPO_NAME" \
  --branch "$BRANCH" \
  --review-round "$review_round"
```

---

_墨汁儿的技能：设计测试 🦊_
