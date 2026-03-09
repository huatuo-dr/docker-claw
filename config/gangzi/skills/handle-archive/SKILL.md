---
name: handle-archive
description: 处理K哥的归档指令，通知煎饼执行归档
triggers:
  - manual: true
---

# Handle Archive Skill

## 功能

接收K哥的归档指令，通知煎饼执行归档流程。

## 触发条件

1. 墨汁儿审查通过 → 通知刚子
2. 刚子通知K哥 → K哥决定是否归档
3. K哥批准归档 → 刚子调用此技能

## 执行步骤

### 1. 接收K哥的归档指令

**输入：**
```json
{
  "approved": true,
  "task_id": "task-001",
  "approved_by": "K哥",
  "approved_at": "2026-03-09T12:00:00Z"
}
```

**验证：**
```bash
# 检查当前任务
config=$(cat /shared/config.json)
current_task_id=$(echo "$config" | jq -r '.current_task.id')

if [[ "$current_task_id" != "$task_id" ]]; then
  send_message_to_k_ge "❌ 归档失败: 任务ID不匹配"
  exit 1
fi

# 检查墨汁儿状态
mozhi=$(cat /shared/status/mozhi.json)
mozhi_phase=$(echo "$mozhi" | jq -r '.phase')

if [[ "$mozhi_phase" != "审查成功" ]]; then
  send_message_to_k_ge "❌ 归档失败: 墨汁儿尚未完成审查"
  exit 1
fi
```

### 2. 更新全局配置

```bash
# 标记归档已触发
cat /shared/config.json | jq "
  .archive_triggered = true |
  .archive_approved_by = \"K哥\" |
  .archive_approved_at = \"$(date -Iseconds)\"
" > /shared/config.json.tmp

mv /shared/config.json.tmp /shared/config.json
```

### 3. 通知煎饼

**方式1：通过状态文件（推荐）**

煎饼的Cron任务会检测到：
- `config.json.archive_triggered = true`

煎饼会自动调用 `archive` 技能。

**方式2：直接调用（如果煎饼在线）**

```bash
# 如果煎饼有API接口
call_jianbing_skill "archive" "{
  \"task_id\": \"$task_id\",
  \"approved_by\": \"K哥\"
}"
```

### 4. 更新自己的状态

```bash
cat /shared/status/gangzi.json | jq "
  .phase = \"处理归档\" |
  .phase_detail.archive_status = \"已通知煎饼\" |
  .last_update = \"$(date -Iseconds)\"
" > /shared/status/gangzi.json.tmp

mv /shared/status/gangzi.json.tmp /shared/status/gangzi.json
```

### 5. 通知K哥

**消息模板：**
```
✅ 归档指令已发送

📋 任务: ${task_name}
📍 状态: 等待煎饼归档

🐶 煎饼: 正在归档...

⏰ 时间: $(date '+%Y-%m-%d %H:%M:%S')

归档流程:
1. ✅ K哥批准
2. ✅ 通知煎饼
3. ⏳ 煎饼归档中
4. ⏳ 合并分支
5. ⏳ 完成通知

稍后会通知你归档结果！
```

**发送消息：**
```bash
send_message_to_k_ge "${message}"
```

### 6. 等待煎饼完成

**轮询检查：**
```bash
# 每30秒检查一次
max_wait=600  # 最长等待10分钟
waited=0

while [[ $waited -lt $max_wait ]]; do
  # 读取煎饼状态
  jianbing=$(cat /shared/status/jianbing.json)
  jianbing_phase=$(echo "$jianbing" | jq -r '.phase')
  
  # 检查是否完成
  if [[ "$jianbing_phase" == "等待需求" ]]; then
    # 煎饼已完成归档
    break
  fi
  
  # 等待30秒
  sleep 30
  waited=$((waited + 30))
done

if [[ $waited -ge $max_wait ]]; then
  # 超时
  send_message_to_k_ge "⚠️ 归档超时: 煎饼10分钟内未完成归档"
  exit 1
fi
```

### 7. 确认归档成功

**检查：**
```bash
# 检查milestone是否已归档
if [ ! -f "/workspace/milestone.md" ]; then
  # milestone已移走，归档成功
  
  # 检查分支是否已合并
  git checkout main
  git pull origin main
  
  # 检查feature分支是否已删除
  if ! git branch --list "feature/${task_id}" | grep -q .; then
    # 分支已删除，归档完全成功
    archive_success=true
  else
    archive_success=false
    archive_error="Feature分支未删除"
  fi
else
  archive_success=false
  archive_error="Milestone未归档"
fi
```

### 8. 更新最终状态

**如果成功：**
```bash
# 调用 end-task 技能
call_skill "end-task" "{
  \"task_id\": \"$task_id\",
  \"reason\": \"归档完成\"
}"
```

**如果失败：**
```bash
# 通知K哥
send_message_to_k_ge "❌ 归档失败: ${archive_error}

请手动检查并处理。"
```

### 9. 记录日志

```bash
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] 刚子: 归档指令处理 - ${task_id} (K哥批准)" >> /shared/logs/gangzi.log
```

---

## 完整流程示例

### K哥批准归档

```
K哥: "可以归档"
刚子: "收到！正在通知煎饼执行归档..."
```

### 刚子处理

```
1. ✅ 验证任务状态
2. ✅ 更新 config.json.archive_triggered = true
3. ✅ 通知煎饼（通过状态文件）
4. ✅ 通知K哥: "已通知煎饼，正在归档..."
5. ⏳ 等待煎饼完成
6. ✅ 确认归档成功
7. ✅ 调用 end-task
8. ✅ 通知K哥: "归档完成！"
```

### 煎饼归档

```
1. 检测到 archive_triggered = true
2. 执行归档:
   - mv milestone.md milestones/001_{名称}.md
   - git checkout main
   - git merge feature/task-001 --no-ff
   - git push origin main
   - git branch -d feature/task-001
3. 更新状态: phase = "等待需求"
```

### 刚子确认

```
1. 检测到煎饼 phase = "等待需求"
2. 检查milestone已归档
3. 检查分支已合并
4. 调用 end-task
5. 通知K哥: "✅ 任务已完成并归档"
```

---

## 错误处理

### 1. 煎饼离线

```bash
# 检查煎饼心跳
jianbing_heartbeat=$(cat /shared/status/jianbing.json | jq -r '.heartbeat')
jianbing_age=$(( $(date +%s) - $(date -d "$jianbing_heartbeat" +%s) ))

if [[ $jianbing_age -gt 900 ]]; then
  send_message_to_k_ge "❌ 归档失败: 煎饼离线，无法执行归档

请先重启煎饼，再重试归档。"
  exit 1
fi
```

### 2. 归档超时

```bash
if [[ $waited -ge $max_wait ]]; then
  # 回滚状态
  cat /shared/config.json | jq ".archive_triggered = false" > /shared/config.json.tmp
  mv /shared/config.json.tmp /shared/config.json
  
  # 通知K哥
  send_message_to_k_ge "⚠️ 归档超时

煎饼10分钟内未完成归档，已回滚状态。

建议:
1. 检查煎饼日志
2. 手动归档
3. 重新触发归档指令"
fi
```

### 3. Git操作失败

```bash
if ! git checkout main; then
  send_message_to_k_ge "❌ Git操作失败: 无法切换到main分支

请手动处理Git冲突后再归档。"
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
  "archive_triggered": true,
  "notified_jianbing": true,
  "waiting_for_completion": true
}
```

**失败：**
```json
{
  "success": false,
  "error": "煎饼离线",
  "task_id": "task-001"
}
```

---

## 注意事项

1. **验证状态**：必须确认墨汁儿审查通过
2. **通知方式**：优先通过状态文件，避免依赖API
3. **等待超时**：最长等待10分钟
4. **回滚机制**：失败时回滚状态
5. **K哥确认**：完成后必须通知K哥

---

_刚子的技能：处理归档指令 🤖_
