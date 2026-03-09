# HEARTBEAT.md - 刚子的心跳任务

**频率：** 每10分钟  
**执行者：** 刚子（Coordinator）  
**触发条件：** 只在开发状态时执行

---

## 执行前提检查

### 1. 检查任务状态

```bash
# 读取全局配置
config=$(cat /shared/config.json)

# 提取状态
status=$(echo "$config" | jq -r '.status')

# 判断是否执行
if [[ "$status" == "idle" || "$status" == "completed" ]]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 当前状态: $status，跳过心跳任务"
  exit 0
fi

# 如果是开发状态，继续执行
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始心跳监控..."
```

### 2. 更新自己的心跳

```bash
# 更新 gangzi.json
cat > /shared/status/gangzi.json.tmp <<EOF
{
  "agent": "gangzi",
  "phase": "监控中",
  "phase_list": [
    "空闲",
    "监控中",
    "处理归档",
    "处理异常"
  ],
  "current_task": $(echo "$config" | jq '.current_task'),
  "phase_detail": {
    "started_at": "$(date -Iseconds)",
    "monitoring_active": true
  },
  "statistics": {
    "tasks_completed": $(cat /shared/status/gangzi.json | jq '.statistics.tasks_completed // 0'),
    "tasks_failed": $(cat /shared/status/gangzi.json | jq '.statistics.tasks_failed // 0'),
    "issues_timeout": $(cat /shared/status/gangzi.json | jq '.statistics.issues_timeout // 0'),
    "tokens_used": $(cat /shared/status/gangzi.json | jq '.statistics.tokens_used // 0'),
    "duration_seconds": $(cat /shared/status/gangzi.json | jq '.statistics.duration_seconds // 0')
  },
  "last_update": "$(date -Iseconds)",
  "heartbeat": "$(date -Iseconds)"
}
EOF

mv /shared/status/gangzi.json.tmp /shared/status/gangzi.json
```

---

## 监控任务

### 任务1：检查煎饼状态

```bash
# 读取煎饼状态
jianbing=$(cat /shared/status/jianbing.json)

# 检查心跳
jianbing_heartbeat=$(echo "$jianbing" | jq -r '.heartbeat')
jianbing_age_seconds=$(( $(date +%s) - $(date -d "$jianbing_heartbeat" +%s 2>/dev/null || echo 0) ))

# 判断健康状态
if [[ $jianbing_age_seconds -gt 900 ]]; then
  # 超过15分钟未更新
  jianbing_health="error"
  jianbing_warning="⚠️ 煎饼可能离线（最后心跳: ${jianbing_age_seconds}秒前）"
elif [[ $jianbing_age_seconds -gt 600 ]]; then
  # 超过10分钟未更新
  jianbing_health="warning"
  jianbing_warning="⚠️ 煎饼响应较慢（最后心跳: ${jianbing_age_seconds}秒前）"
else
  jianbing_health="ok"
  jianbing_warning=""
fi

# 提取关键信息
jianbing_phase=$(echo "$jianbing" | jq -r '.phase')
jianbing_task_id=$(echo "$jianbing" | jq -r '.current_task.id // "N/A"')
jianbing_local_commits=$(echo "$jianbing" | jq -r '.phase_detail.local_commits // 0')
```

### 任务2：检查墨汁儿状态

```bash
# 读取墨汁儿状态
mozhi=$(cat /shared/status/mozhi.json)

# 检查心跳
mozhi_heartbeat=$(echo "$mozhi" | jq -r '.heartbeat')
mozhi_age_seconds=$(( $(date +%s) - $(date -d "$mozhi_heartbeat" +%s 2>/dev/null || echo 0) ))

# 判断健康状态
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

# 提取关键信息
mozhi_phase=$(echo "$mozhi" | jq -r '.phase')
mozhi_issue_number=$(echo "$mozhi" | jq -r '.current_issue.number // "N/A"')
mozhi_issue_comments=$(echo "$mozhi" | jq -r '.current_issue.comments_count // 0')
```

### 任务3：检查Issue状态

```bash
# 如果墨汁儿有Issue
if [[ "$mozhi_issue_number" != "null" && "$mozhi_issue_number" != "N/A" ]]; then
  # 检查Issue文件
  issue_file="/shared/issues/${mozhi_issue_number}.json"
  
  if [[ -f "$issue_file" ]]; then
    issue=$(cat "$issue_file")
    issue_comments=$(echo "$issue" | jq -r '.comments_count // 0')
    issue_max_comments=15
    issue_warning_threshold=12
    
    # 检查是否超过警告阈值
    if [[ $issue_comments -ge $issue_max_comments ]]; then
      # 触发异常流程（15轮）
      issue_status="⚠️ 超时"
      issue_warning="🚨 Issue #$mozhi_issue_number 已达 ${issue_comments}/15 轮，需要人工介入"
      
      # 通知K哥（如果还未通知）
      last_notification=$(cat /shared/status/summary.json | jq -r '.last_notification')
      if [[ -z "$last_notification" || "$last_notification" == "null" ]]; then
        # TODO: 调用 handle-exception 技能
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Issue超时，需要通知K哥"
      fi
      
    elif [[ $issue_comments -ge $issue_warning_threshold ]]; then
      # 警告（12轮）
      issue_status="⚠️ 警告"
      issue_warning="⚠️ Issue #$mozhi_issue_number 已达 ${issue_comments}/15 轮"
    else
      issue_status="正常"
      issue_warning=""
    fi
  fi
fi
```

---

## 生成进度报告

### 汇总信息

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

### 生成报告

```bash
# 构建报告
report="📊 开发进度报告
⏰ $(date '+%Y-%m-%d %H:%M:%S')

📋 任务: $task_name (ID: $task_id)
📍 状态: $(echo "$config" | jq -r '.status')
⏱️ 耗时: ${elapsed_minutes} 分钟

🐶 煎饼:
   阶段: $jianbing_phase
   健康度: $jianbing_health
   本地commits: $jianbing_local_commits
   $jianbing_warning

🦊 墨汁儿:
   阶段: $mozhi_phase
   健康度: $mozhi_health
   当前Issue: #$mozhi_issue_number ($mozhi_issue_comments/15)
   $mozhi_warning"

# 如果有Issue警告，添加到报告
if [[ -n "$issue_warning" ]]; then
  report="$report

⚠️ Issue状态: $issue_status
$issue_warning"
fi

# 添加下次汇报时间
report="$report

⏱️ 下次汇报: 10分钟后"

# 输出报告
echo "$report"

# TODO: 通过消息平台发送给K哥
# send_message_to_k_ge "$report"
```

---

## 更新汇总状态

```bash
# 更新 summary.json
cat > /shared/status/summary.json.tmp <<EOF
{
  "task_id": "$task_id",
  "task_name": "$task_name",
  "status": "$(echo "$config" | jq -r '.status')",
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

---

## 记录日志

```bash
# 记录到日志文件
log_entry="[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] 刚子: Heartbeat完成 - 煎饼($jianbing_health), 墨汁儿($mozhi_health)"

# 如果有警告，记录警告
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

## 异常处理

### 1. Agent离线

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

  # TODO: 立即通知K哥（不等待下次Heartbeat）
  # send_message_to_k_ge "$error_report"
fi
```

### 2. Issue超时

```bash
if [[ "$issue_status" == "⚠️ 超时" ]]; then
  # 生成超时报告
  timeout_report="🚨 Issue超时警告

Issue: #$mozhi_issue_number
讨论轮次: ${issue_comments}/15
任务: $task_name

需要K哥人工介入决策。

建议方案:
1. 手动审查代码
2. 重新设计部分功能
3. 取消任务

请K哥决策。"

  # TODO: 立即通知K哥
  # send_message_to_k_ge "$timeout_report"
fi
```

---

## 完成心跳

```bash
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] 刚子: Heartbeat完成"
exit 0
```

---

## 注意事项

1. **只在开发状态执行**
   - `idle`: 跳过
   - `completed`: 跳过
   - `in_progress`: 执行
   - `reviewing`: 执行

2. **原子操作**
   - 写文件时先写临时文件，再重命名
   - 避免读写冲突

3. **心跳更新**
   - 每次Heartbeat必须更新自己的心跳时间
   - 这是健康检查的依据

4. **立即通知**
   - Agent离线和Issue超时需要立即通知K哥
   - 不要等待下次Heartbeat

5. **日志记录**
   - 所有操作都记录到日志
   - 便于故障排查

---

_刚子的心跳任务，让K哥随时掌握进度 🤖_
