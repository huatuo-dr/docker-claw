# SKILL.md - 监控状态

## 触发条件

每1分钟自动触发，或状态变化时触发。

## 执行步骤

### 1. 读取 milestone.md

```bash
milestone_file="/workspace/target-repo/milestone.md"
milestone_status=$(grep "^## 状态:" "$milestone_file" | sed 's/.*状态: //')
```

### 2. 读取 Agent 状态

```bash
jianbing=$(cat /shared/status/jianbing.json)
mozhi=$(cat /shared/status/mozhi.json)
```

### 3. 检测状态变化

```bash
# 对比上次状态
if [[ "$milestone_status" != "$last_status" ]]; then
  # 状态变化
fi
```

### 4. 汇报 K哥

```bash
# 通过飞书发送报告
report="📊 状态变化报告
状态: $milestone_status
煎饼: $jianbing_phase
墨汁儿: $mozhi_phase"

# send_to_feishu "$report"
```

---

## 输出

- 状态报告已发送
- 状态已更新
