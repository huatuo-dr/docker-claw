---
name: check-milestone
description: 检查 milestone.md 状态变化（Cron 5分钟）
triggers:
  - cron: "*/5 * * * *"
---

# Check Milestone Skill

## 执行前提检查

```bash
# 读取 milestone.md
milestone_file="/workspace/test-task/milestone.md"

if [[ ! -f "$milestone_file" ]]; then
  exit 0
fi

# 提取状态
milestone_status=$(grep "^## 状态:" "$milestone_file" | sed 's/.*状态: //')
```

## 执行步骤

### 1. 检测状态

```bash
# 读取当前状态
if [[ "$milestone_status" == "开发完成" ]]; then
  # 开始测试设计
  phase="测试计划"
elif [[ "$milestone_status" == "测试计划完成" ]]; then
  # 开始测试
  phase="测试中"
elif [[ "$milestone_status" == "测试通过" ]]; then
  # 测试完成
  phase="测试完成"
fi
```

### 2. 更新 milestone

```bash
# 在测试记录中追加
if [[ "$phase" == "测试计划" ]]; then
  # 更新测试计划
  sed -i 's/## 状态:.*/## 状态: 测试计划完成/' "$milestone_file"
fi
```

---

_墨汁儿的技能：检查里程碑 🦊_
