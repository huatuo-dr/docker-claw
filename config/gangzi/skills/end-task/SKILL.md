---
name: end-task
description: 结束任务，停止Cron、更新状态、记录历史
triggers:
  - manual: true
---

# End Task Skill

## 功能

当任务完成或取消时，结束当前任务。

## 执行步骤

### 1. 检查当前任务状态

```bash
# 读取当前任务
config=$(cat /shared/config.json)
task_id=$(echo "$config" | jq -r '.current_task.id')
task_name=$(echo "$config" | jq -r '.current_task.name')
status=$(echo "$config" | jq -r '.status')

if [[ "$task_id" == "null" || -z "$task_id" ]]; then
  echo "没有正在进行的任务"
  exit 0
fi
```

### 2. 停止Cron任务

```bash
# 获取Cron Job IDs
jianbing_job=$(echo "$config" | jq -r '.cron_jobs.jianbing')
mozhi_job=$(echo "$config" | jq -r '.cron_jobs.mozhi')

# 停止煎饼的Cron
if [[ "$jianbing_job" != "null" && -n "$jianbing_job" ]]; then
  openclaw cron disable "$jianbing_job"
  echo "已停止煎饼的Cron任务: $jianbing_job"
fi

# 停止墨汁儿的Cron
if [[ "$mozhi_job" != "null" && -n "$mozhi_job" ]]; then
  openclaw cron disable "$mozhi_job"
  echo "已停止墨汁儿的Cron任务: $mozhi_job"
fi
```

### 3. 更新全局配置

```bash
cat > /shared/config.json <<EOF
{
  "version": "1.0",
  "status": "completed",
  "current_task": null,
  "cron_jobs": {
    "jianbing": null,
    "mozhi": null
  },
  "archive_triggered": false,
  "archive_approved_by": null,
  "archive_approved_at": null
}
EOF
```

### 4. 更新任务汇总

```bash
# 计算耗时
started_at=$(cat /shared/status/summary.json | jq -r '.started_at')
if [[ -n "$started_at" && "$started_at" != "null" ]]; then
  started_seconds=$(date -d "$started_at" +%s 2>/dev/null || echo 0)
  elapsed_seconds=$(( $(date +%s) - started_seconds ))
else
  elapsed_seconds=0
fi

# 更新summary.json
cat > /shared/status/summary.json <<EOF
{
  "task_id": "${task_id}",
  "task_name": "${task_name}",
  "status": "completed",
  "started_at": "${started_at}",
  "elapsed_seconds": ${elapsed_seconds},
  "completed_at": "$(date -Iseconds)",
  "agents": {
    "gangzi": {
      "phase": "空闲",
      "health": "ok",
      "last_heartbeat": "$(date -Iseconds)"
    },
    "jianbing": {
      "phase": "等待需求",
      "health": "ok",
      "last_heartbeat": null
    },
    "mozhi": {
      "phase": "空闲",
      "health": "ok",
      "last_heartbeat": null
    }
  },
  "progress": {
    "milestone_completed": 0,
    "milestone_total": 0,
    "issue_number": null,
    "issue_url": null,
    "issue_comments": 0,
    "issue_max_comments": 15,
    "issue_warning_threshold": 12
  },
  "next_notification": null,
  "last_notification": "$(date -Iseconds)"
}
EOF
```

### 5. 更新自己的状态

```bash
cat > /shared/status/gangzi.json <<EOF
{
  "agent": "gangzi",
  "phase": "空闲",
  "phase_list": [
    "空闲",
    "监控中",
    "处理归档",
    "处理异常"
  ],
  "current_task": null,
  "phase_detail": {
    "started_at": null,
    "monitoring_active": false
  },
  "statistics": {
    "tasks_completed": $(cat /shared/status/gangzi.json | jq '.statistics.tasks_completed + 1'),
    "tasks_failed": $(cat /shared/status/gangzi.json | jq '.statistics.tasks_failed'),
    "issues_timeout": $(cat /shared/status/gangzi.json | jq '.statistics.issues_timeout'),
    "tokens_used": $(cat /shared/status/gangzi.json | jq '.statistics.tokens_used'),
    "duration_seconds": $(cat /shared/status/gangzi.json | jq '.statistics.duration_seconds')
  },
  "last_update": "$(date -Iseconds)",
  "heartbeat": "$(date -Iseconds)"
}
EOF
```

### 6. 记录到MEMORY.md

```bash
# 追加到MEMORY.md
cat >> ~/.openclaw/workspace/MEMORY.md <<EOF

## 任务历史

### ${task_id}: ${task_name}
- **开始时间**: ${started_at}
- **结束时间**: $(date -Iseconds)
- **耗时**: ${elapsed_seconds} 秒
- **状态**: ✅ 完成

EOF
```

### 7. 通知煎饼和墨汁儿

**通知方式：** 通过状态文件

煎饼和墨汁儿会在下次Cron或会话启动时读取到：
- `config.json.status = "completed"`
- `config.json.current_task = null`

他们会自动进入空闲状态。

### 8. 通知K哥

**消息模板：**
```
✅ 任务已完成

📋 任务信息:
- ID: ${task_id}
- 名称: ${task_name}
- 状态: 已完成
- 耗时: ${elapsed_minutes} 分钟

🐶 煎饼: 已进入空闲状态
🦊 墨汁儿: 已进入空闲状态

⏰ 完成时间: $(date '+%Y-%m-%d %H:%M:%S')

准备接收新任务！
```

**发送消息：**
```bash
send_message_to_k_ge "${message}"
```

### 9. 记录日志

```bash
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] 刚子: 任务结束 - ${task_id} (${task_name})" >> /shared/logs/gangzi.log
```

---

## 错误处理

### 1. Cron任务停止失败

```bash
if ! openclaw cron disable "$jianbing_job"; then
  echo "⚠️ 警告: 无法停止煎饼的Cron任务，请手动处理"
  # 继续执行，不退出
fi
```

### 2. 文件写入失败

```bash
if [ ! -f "/shared/config.json" ]; then
  echo "❌ 错误: 无法更新配置文件"
  exit 1
fi
```

---

## 返回值

**成功：**
```json
{
  "success": true,
  "task_id": "task-001",
  "task_name": "用户认证功能",
  "elapsed_seconds": 3600,
  "completed_at": "2026-03-09T10:00:00Z"
}
```

---

## 注意事项

1. **Cron任务**：必须停止，避免浪费资源
2. **状态更新**：所有状态文件都要更新
3. **历史记录**：记录到MEMORY.md
4. **通知K哥**：任务完成后立即通知

---

_刚子的技能：结束任务 🤖_
