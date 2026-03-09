---
name: monitor
description: 监控煎饼和墨汁儿的状态，生成进度报告
triggers:
  - heartbeat: true  # 由Heartbeat调用
---

# Monitor Skill

## 功能

由Heartbeat调用（每10分钟），监控煎饼和墨汁儿的工作状态，生成进度报告。

## 执行前提检查

```bash
# 读取全局配置
config=$(cat /shared/config.json)
status=$(echo "$config" | jq -r '.status')

# 只在开发状态时执行
if [[ "$status" != "in_progress" && "$status" != "reviewing" ]]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 当前状态: $status，跳过监控"
  exit 0
fi
```

## 执行步骤

### 1. 更新自己的心跳

```bash
# 更新gangzi.json的heartbeat字段
cat /shared/status/gangzi.json | jq ".heartbeat = \"$(date -Iseconds)\" | .last_update = \"$(date -Iseconds)\"" > /shared/status/gangzi.json.tmp
mv /shared/status/gangzi.json.tmp /shared/status/gangzi.json
```

### 2. 检查煎饼状态

```bash
# 读取煎饼状态
jianbing=$(cat /shared/status/jianbing.json)

# 检查心跳
jianbing_heartbeat=$(echo "$jianbing" | jq -r '.heartbeat')
if [[ -n "$jianbing_heartbeat" && "$jianbing_heartbeat" != "null" ]]; then
  jianbing_age_seconds=$(( $(date +%s) - $(date -d "$jianbing_heartbeat" +%s 2>/dev/null || echo 0) ))
  
  if [[ $jianbing_age_seconds -gt 900 ]]; then
    jianbing_health="error"
    jianbing_warning="⚠️ 煎饼可能离线（最后心跳: ${jianbing_age_seconds}秒前）"
  elif [[ $jianbing_age_seconds -gt 600 ]]; then
    jianbing_health="warning"
    jianbing_warning="⚠️ 煎饼响应较慢（最后心跳: ${jianbing_age_seconds}秒前）"
  else
    jianbing_health="ok"
    jianbing_warning=""
  fi
else
  jianbing_health="unknown"
  jianbing_warning="⚠️ 煎饼尚未启动"
fi

# 提取关键信息
jianbing_phase=$(echo "$jianbing" | jq -r '.phase')
jianbing_local_commits=$(echo "$jianbing" | jq -r '.phase_detail.local_commits // 0')
```

### 3. 检查墨汁儿状态

```bash
# 读取墨汁儿状态
mozhi=$(cat /shared/status/mozhi.json)

# 检查心跳
mozhi_heartbeat=$(echo "$mozhi" | jq -r '.heartbeat')
if [[ -n "$mozhi_heartbeat" && "$mozhi_heartbeat" != "null" ]]; then
  mozhi_age_seconds=$(( $(date +%s) - $(date -d "$mozhi_heartbeat" +%s 2>/dev/null || echo 0) ))
  
  if [[ $mozhi_age_seconds -gt 900 ]]; then
    mozhi_health="error"
    mozhi_warning="⚠️ 墨汁儿可能离线（最后心跳: ${mozhi_age_seconds}秒前）"
  elif [[ $mozhi_age_seconds -gt 600 ]]; then
    mozhi_health="warning"
    mozhi_warning="⚠️ 墨汁儿响应较慢（最后心跳: ${mozhi_age_seconds}秒前）"
  else
    mozhi_health="ok"
    mozhi_warning=""
  fi
else
  mozhi_health="unknown"
  mozhi_warning="⚠️ 墨汁儿尚未启动"
fi

# 提取关键信息
mozhi_phase=$(echo "$mozhi" | jq -r '.phase')
mozhi_issue_number=$(echo "$mozhi" | jq -r '.current_issue.number // "N/A"')
mozhi_issue_comments=$(echo "$mozhi" | jq -r '.current_issue.comments_count // 0')
```

### 4. 检查Issue状态

```bash
issue_status="正常"
issue_warning=""

if [[ "$mozhi_issue_number" != "null" && "$mozhi_issue_number" != "N/A" ]]; then
  # 检查Issue文件
  issue_file="/shared/issues/${mozhi_issue_number}.json"
  
  if [[ -f "$issue_file" ]]; then
    issue=$(cat "$issue_file")
    issue_comments=$(echo "$issue" | jq -r '.comments_count // 0')
    issue_max_comments=15
    issue_warning_threshold=12
    
    if [[ $issue_comments -ge $issue_max_comments ]]; then
      issue_status="⚠️ 超时"
      issue_warning="🚨 Issue #$mozhi_issue_number 已达 ${issue_comments}/15 轮，需要人工介入"
      
      # 触发异常处理
      # （在后续步骤中处理）
      
    elif [[ $issue_comments -ge $issue_warning_threshold ]]; then
      issue_status="⚠️ 警告"
      issue_warning="⚠️ Issue #$mozhi_issue_number 已达 ${issue_comments}/15 轮"
    fi
  fi
fi
```

### 5. 汇总信息

```bash
# 读取任务信息
task_id=$(echo "$config" | jq -r '.current_task.id')
task_name=$(echo "$config" | jq -r '.current_task.name')
started_at=$(echo "$config" | jq -r '.current_task.started_at')

# 计算耗时
if [[ -n "$started_at" && "$started_at" != "null" ]]; then
  started_seconds=$(date -d "$started_at" +%s 2>/dev/null || echo 0)
  elapsed_seconds=$(( $(date +%s) - started_seconds ))
  elapsed_minutes=$(( elapsed_seconds / 60 ))
else
  elapsed_minutes=0
fi

# 读取进度信息
summary=$(cat /shared/status/summary.json)
milestone_completed=$(echo "$summary" | jq -r '.progress.milestone_completed // 0')
milestone_total=$(echo "$summary" | jq -r '.progress.milestone_total // 0')
```

### 6. 生成进度报告

```bash
# 构建报告
report="📊 开发进度报告
⏰ $(date '+%Y-%m-%d %H:%M:%S')

📋 任务: $task_name (ID: $task_id)
📍 状态: $status
⏱️ 耗时: ${elapsed_minutes} 分钟

🐶 煎饼:
   阶段: $jianbing_phase
   健康度: $jianbing_health
   本地commits: $jianbing_local_commits"

if [[ -n "$jianbing_warning" ]]; then
  report="$report
   $jianbing_warning"
fi

report="$report

🦊 墨汁儿:
   阶段: $mozhi_phase
   健康度: $mozhi_health
   当前Issue: #$mozhi_issue_number ($mozhi_issue_comments/15)"

if [[ -n "$mozhi_warning" ]]; then
  report="$report
   $mozhi_warning"
fi

# 如果有Issue警告，添加到报告
if [[ -n "$issue_warning" ]]; then
  report="$report

⚠️ Issue状态: $issue_status
$issue_warning"
fi

# 添加下次汇报时间
report="$report

⏱️ 下次汇报: 10分钟后"
```

### 7. 发送报告给K哥

```bash
# 通过消息平台发送
send_message_to_k_ge "$report"
```

### 8. 更新汇总状态

```bash
cat > /shared/status/summary.json.tmp <<EOF
{
  "task_id": "$task_id",
  "task_name": "$task_name",
  "status": "$status",
  "started_at": "$started_at",
  "elapsed_seconds": $elapsed_seconds,
  
  "agents": {
    "gangzi": {
      "phase": "监控中",
      "health": "ok",
      "last_heartbeat": "$(date -Iseconds)"
    },
    "jianbing": {
      "phase": "$jianbing_phase",
      "health": "$jianbing_health",
      "last_heartbeat": "$jianbing_heartbeat"
    },
    "mozhi": {
      "phase": "$mozhi_phase",
      "health": "$mozhi_health",
      "last_heartbeat": "$mozhi_heartbeat"
    }
  },
  
  "progress": {
    "milestone_completed": $milestone_completed,
    "milestone_total": $milestone_total,
    "issue_number": ${mozhi_issue_number:-null},
    "issue_url": $(echo "$mozhi" | jq '.current_issue.url // null'),
    "issue_comments": ${mozhi_issue_comments:-0},
    "issue_max_comments": 15,
    "issue_warning_threshold": 12
  },
  
  "next_notification": "$(date -d '+10 minutes' -Iseconds)",
  "last_notification": "$(date -Iseconds)"
}
EOF

mv /shared/status/summary.json.tmp /shared/status/summary.json
```

### 9. 处理异常

#### 9.1 Agent离线

```bash
if [[ "$jianbing_health" == "error" || "$mozhi_health" == "error" ]]; then
  # 生成异常报告
  error_report="🚨 Agent离线警告

检测时间: $(date '+%Y-%m-%d %H:%M:%S')

离线Agent:
$( [[ "$jianbing_health" == "error" ]] && echo "- 煎饼 (离线 ${jianbing_age_seconds} 秒)" )
$( [[ "$mozhi_health" == "error" ]] && echo "- 墨汁儿 (离线 ${mozhi_age_seconds} 秒)" )

建议操作:
1. 检查容器状态
2. 查看日志
3. 重启Agent

请K哥决策。"

  # 立即通知K哥
  send_message_to_k_ge "$error_report"
fi
```

#### 9.2 Issue超时

```bash
if [[ "$issue_status" == "⚠️ 超时" ]]; then
  # 调用 handle-exception 技能
  # 或者直接处理
  error_report="🚨 Issue超时警告

Issue: #$mozhi_issue_number
讨论轮次: ${issue_comments}/15
任务: $task_name

需要K哥人工介入决策。

建议方案:
1. 手动审查代码
2. 重新设计部分功能
3. 取消任务

请K哥决策。"

  # 立即通知K哥
  send_message_to_k_ge "$error_report"
fi
```

### 10. 记录日志

```bash
log_entry="[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] 刚子: Heartbeat完成 - 煎饼($jianbing_health), 墨汁儿($mozhi_health)"

if [[ -n "$jianbing_warning" ]]; then
  log_entry="$log_entry | 煎饼警告: $jianbing_warning"
fi

if [[ -n "$mozhi_warning" ]]; then
  log_entry="$log_entry | 墨汁儿警告: $mozhi_warning"
fi

if [[ -n "$issue_warning" ]]; then
  log_entry="$log_entry | Issue警告: $issue_warning"
fi

echo "$log_entry" >> /shared/logs/gangzi.log
```

---

## 返回值

**成功：**
```json
{
  "success": true,
  "report_sent": true,
  "agents_health": {
    "jianbing": "ok",
    "mozhi": "ok"
  },
  "issue_status": "正常"
}
```

**异常：**
```json
{
  "success": true,
  "report_sent": true,
  "agents_health": {
    "jianbing": "error",
    "mozhi": "ok"
  },
  "error_notified": true
}
```

---

## 注意事项

1. **只在开发状态执行**：避免日常状态浪费资源
2. **心跳更新**：每次必须更新自己的heartbeat
3. **立即通知**：Agent离线和Issue超时需要立即通知K哥
4. **原子操作**：状态文件使用临时文件+重命名
5. **日志记录**：所有操作都记录日志

---

_刚子的技能：监控状态（Heartbeat调用） 🤖_
