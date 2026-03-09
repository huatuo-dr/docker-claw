---
name: handle-exception
description: 处理异常情况（15轮Issue、Agent离线、Git冲突等）
triggers:
  - manual: true
  - event: exception
---

# Handle Exception Skill

## 功能

处理各种异常情况，通知K哥并等待决策。

## 异常类型

### 1. Issue超时（15轮）

**触发条件：** Issue comments ≥ 15

**检测方式：**
- 墨汁儿在 `verify-fix` 技能中检测
- 墨汁儿通知刚子

### 2. Agent离线

**触发条件：** Heartbeat超过15分钟

**检测方式：**
- 刚子在 `monitor` 技能中检测

### 3. Git冲突

**触发条件：** Git操作失败（merge conflict）

**检测方式：**
- 煎饼/墨汁儿在Git操作中检测
- 煎饼/墨汁儿通知刚子

### 4. Cron任务失败

**触发条件：** Cron任务执行失败

**检测方式：**
- OpenClaw Cron系统报告

---

## 执行步骤

### 1. 接收异常通知

**输入：**
```json
{
  "type": "issue_timeout",
  "task_id": "task-001",
  "issue_number": 123,
  "comments": 15,
  "open_bugs": [...],
  "timeline": [...],
  "reported_by": "mozhi",
  "reported_at": "2026-03-09T12:00:00Z"
}
```

**验证：**
```bash
# 检查异常类型
if [[ "$type" not in ["issue_timeout", "agent_offline", "git_conflict", "cron_failed"] ]]; then
  echo "未知的异常类型: $type"
  exit 1
fi
```

### 2. 生成异常报告

**Issue超时报告：**
```bash
if [[ "$type" == "issue_timeout" ]]; then
  report="🚨 Issue超时警告

⏰ 检测时间: $(date '+%Y-%m-%d %H:%M:%S')

📋 Issue信息:
- 编号: #$issue_number
- 任务: $task_name
- 讨论轮次: ${comments}/15

🔴 未解决的问题:
$(for bug in "${open_bugs[@]}"; do
  echo "- Bug ${bug.id}: ${bug.description}"
done)

📊 时间线:
$(for event in "${timeline[@]}"; do
  echo "- ${event.timestamp}: ${event.action} by ${event.by}"
done)

💡 建议方案:
1. 手动审查代码，定位根本问题
2. 重新设计部分功能
3. 取消本次任务

请K哥决策。"
fi
```

**Agent离线报告：**
```bash
if [[ "$type" == "agent_offline" ]]; then
  report="🚨 Agent离线警告

⏰ 检测时间: $(date '+%Y-%m-%d %H:%M:%S')

📋 离线Agent:
$(if [[ "$jianbing_offline" == "true" ]]; then
  echo "- 🐶 煎饼 (离线 ${jianbing_age} 秒)"
fi)
$(if [[ "$mozhi_offline" == "true" ]]; then
  echo "- 🦊 墨汁儿 (离线 ${mozhi_age} 秒)"
fi)

💡 建议操作:
1. 检查容器状态: docker ps
2. 查看日志: docker logs {container}
3. 重启Agent: docker restart {container}

请K哥决策。"
fi
```

**Git冲突报告：**
```bash
if [[ "$type" == "git_conflict" ]]; then
  report="🚨 Git冲突警告

⏰ 检测时间: $(date '+%Y-%m-%d %H:%M:%S')

📋 冲突信息:
- Agent: ${reported_by}
- 分支: ${branch}
- 冲突文件: ${conflict_files}

💡 建议操作:
1. 查看冲突文件
2. 手动解决冲突
3. 提交解决方案

请K哥决策。"
fi
```

### 3. 通知K哥

**立即通知（不等待）：**
```bash
# 通过消息平台发送
send_message_to_k_ge "$report"

# 标记为紧急消息
mark_message_urgent
```

### 4. 更新状态

```bash
# 更新自己的状态
cat /shared/status/gangzi.json | jq "
  .phase = \"处理异常\" |
  .phase_detail.exception_type = \"$type\" |
  .phase_detail.exception_time = \"$(date -Iseconds)\" |
  .last_update = \"$(date -Iseconds)\"
" > /shared/status/gangzi.json.tmp

mv /shared/status/gangzi.json.tmp /shared/status/gangzi.json

# 更新统计信息
cat /shared/status/gangzi.json | jq "
  .statistics.issues_timeout += 1
" > /shared/status/gangzi.json.tmp

mv /shared/status/gangzi.json.tmp /shared/status/gangzi.json
```

### 5. 保存异常报告

```bash
# 保存到文件
cat > /shared/issues/${issue_number}_failed.json <<EOF
{
  "type": "$type",
  "task_id": "$task_id",
  "issue_number": $issue_number,
  "comments": $comments,
  "open_bugs": $(echo "${open_bugs[@]}" | jq -R .),
  "timeline": $(echo "${timeline[@]}" | jq -R .),
  "reported_by": "$reported_by",
  "reported_at": "$reported_at",
  "handled_by": "gangzi",
  "handled_at": "$(date -Iseconds)",
  "status": "waiting_for_k_ge"
}
EOF
```

### 6. 等待K哥决策

**轮询等待：**
```bash
# 等待K哥回复（通过消息平台）
# 或者K哥直接执行某个指令

# 暂停监控（避免重复通知）
cat /shared/config.json | jq ".status = \"waiting_for_decision\"" > /shared/config.json.tmp
mv /shared/config.json.tmp /shared/config.json
```

### 7. 执行K哥的决策

**可能的决策：**

#### 7.1 继续任务

```bash
if [[ "$decision" == "continue" ]]; then
  # 恢复状态
  cat /shared/config.json | jq ".status = \"in_progress\"" > /shared/config.json.tmp
  mv /shared/config.json.tmp /shared/config.json
  
  # 通知煎饼/墨汁儿继续
  send_message_to_agents "K哥决定继续任务，请继续工作"
fi
```

#### 7.2 重新设计

```bash
if [[ "$decision" == "redesign" ]]; then
  # 关闭当前Issue
  gh issue close $issue_number --comment "重新设计，关闭此Issue"
  
  # 通知煎饼重新开发
  send_message_to_jianbing "K哥决定重新设计，请重新开发此功能"
  
  # 通知墨汁儿重新审查
  send_message_to_mozhi "K哥决定重新设计，请重新设计测试"
fi
```

#### 7.3 取消任务

```bash
if [[ "$decision" == "cancel" ]]; then
  # 关闭Issue
  gh issue close $issue_number --comment "任务取消"
  
  # 删除feature分支
  git push origin --delete feature/${task_id}
  git branch -D feature/${task_id}
  
  # 调用 end-task
  call_skill "end-task" "{
    \"task_id\": \"$task_id\",
    \"reason\": \"K哥取消任务\"
  }"
fi
```

#### 7.4 手动介入

```bash
if [[ "$decision" == "manual" ]]; then
  # 等待K哥手动解决
  send_message_to_k_ge "好的，我会等待您手动解决问题。

完成手动介入后，请告诉我继续还是取消。"
fi
```

### 8. 记录日志

```bash
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] 刚子: 异常处理 - ${type} (${task_id})" >> /shared/logs/gangzi.log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] 刚子: 已通知K哥，等待决策" >> /shared/logs/gangzi.log
```

---

## 异常处理流程图

```
检测到异常
    ↓
生成报告
    ↓
通知K哥（立即）
    ↓
暂停监控
    ↓
等待K哥决策
    ↓
    ├─ 继续 → 恢复状态 → 通知Agent继续
    ├─ 重新设计 → 关闭Issue → 通知Agent重新开始
    ├─ 取消 → 关闭Issue → 删除分支 → 结束任务
    └─ 手动介入 → 等待K哥 → 继续或取消
```

---

## 返回值

**成功：**
```json
{
  "success": true,
  "exception_type": "issue_timeout",
  "notified_k_ge": true,
  "waiting_for_decision": true,
  "report_saved": true
}
```

**失败：**
```json
{
  "success": false,
  "error": "无法通知K哥",
  "exception_type": "issue_timeout"
}
```

---

## 注意事项

1. **立即通知**：异常必须立即通知K哥，不等待
2. **暂停监控**：避免重复通知
3. **保存报告**：详细记录异常信息
4. **等待决策**：不擅自决定，等待K哥指令
5. **记录日志**：所有操作都记录

---

## 常见问题

### Q1: 如果K哥长时间不回复怎么办？

**A:** 
- 每30分钟提醒一次
- 24小时后自动暂停任务（保留状态）

### Q2: 如果多个异常同时发生？

**A:** 
- 优先级：Agent离线 > Issue超时 > Git冲突
- 逐个处理，不遗漏

### Q3: 如果异常处理后问题依然存在？

**A:** 
- 记录到MEMORY.md
- 建议K哥调整工作流程

---

_刚子的技能：处理异常 🤖_
