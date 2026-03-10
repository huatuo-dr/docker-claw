---
name: start-task
description: 启动新任务，创建milestone、分支、启动Cron任务
triggers:
  - manual: true
---

# Start Task Skill

## 功能

当K哥发起新需求时，启动一个新的开发任务。

## 执行步骤

### 1. 接收K哥的需求

**输入：**
- 需求名称
- 需求描述（可选）
- **目标仓库**（格式: owner/repo）

**示例：**
```
K哥: "开发用户认证功能，仓库是 huatuo/my-project"
```

或者分步交互：
```
K哥: "开发用户认证功能"
刚子: "好的，请问要开发哪个仓库？格式: owner/repo"
K哥: "huatuo/my-project"
```

**确认仓库信息：**
```bash
# 从用户输入中提取仓库，或主动询问
target_repo="${user_specified_repo}"

if [[ -z "$target_repo" ]]; then
  send_message_to_k_ge "请指定目标仓库，格式: owner/repo"
  # 等待用户回复...
fi

# 验证仓库格式
if [[ ! "$target_repo" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$ ]]; then
  send_message_to_k_ge "仓库格式不正确，请使用 owner/repo 格式"
  exit 1
fi

# 验证仓库可访问
if ! gh repo view "$target_repo" &>/dev/null; then
  send_message_to_k_ge "无法访问仓库 $target_repo，请检查仓库名称和Token权限"
  exit 1
fi
```

### 2. 生成任务ID

```bash
# 查找下一个任务ID
next_num=$(ls /workspace/milestones/ 2>/dev/null | wc -l | awk '{printf "%03d", $1+1}')
task_id="task-${next_num}"
```

### 3. 创建历史记录（任务）

**确定项目：**
```bash
# 如果没有项目，创建默认项目
if [ ! -f "/shared/history/index.json" ]; then
  # 调用 history 技能的 create_project
  project_name="default"
  project_id="PROJ-default"
  
  # 创建项目（详见 skills/history/SKILL.md）
  mkdir -p "/shared/history/projects/$project_id/tasks"
  
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  cat > "/shared/history/projects/$project_id/project.json" <<EOF
  {
    "project_id": "$project_id",
    "name": "$project_name",
    "description": "默认项目",
    "created_at": "$ts",
    "status": "active",
    "stats": {
      "total_tasks": 0,
      "completed_tasks": 0,
      "failed_tasks": 0,
      "total_duration": "0h"
    }
  }
  EOF
  
  # 创建全局索引
  cat > /shared/history/index.json <<EOF
  {
    "version": "1.0",
    "last_updated": "$ts",
    "projects": [{"project_id": "$project_id", "name": "$project_name", "created_at": "$ts"}],
    "stats": {"total_projects": 1, "total_tasks": 0, "total_events": 0}
  }
  EOF
else
  # 读取第一个项目ID（或让用户指定）
  project_id=$(cat /shared/history/index.json | jq -r '.projects[0].project_id')
fi
```

**创建任务历史：**
```bash
# 调用 history 技能的 create_task
timestamp=$(date +%Y%m%d%H%M%S)
seq=$(ls "/shared/history/projects/$project_id/tasks" 2>/dev/null | grep "TASK-$timestamp" | wc -l)
seq_padded=$(printf "%03d" $seq)
history_task_id="TASK-$timestamp-$seq_padded"

task_dir="/shared/history/projects/$project_id/tasks/$history_task_id"
mkdir -p "$task_dir/agents"

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 创建 task.json
cat > "$task_dir/task.json" <<EOF
{
  "task_id": "$history_task_id",
  "project_id": "$project_id",
  "name": "${task_name}",
  "description": "${task_description:-}",
  "branch": "feature/${task_id}",
  "milestone_file": "milestone.md",
  "created_at": "$ts",
  "completed_at": null,
  "status": "pending",
  "current_phase": "initialized",
  "stats": {
    "dev_duration": null,
    "review_duration": null,
    "total_duration": null,
    "commits_count": 0,
    "issues_count": 0,
    "issue_rounds": 0
  }
}
EOF

# 创建 Agent 事件文件
for agent in gangzi jianbing mozhi; do
  cat > "$task_dir/agents/$agent.json" <<EOF
{
  "task_id": "$history_task_id",
  "agent": "$agent",
  "events": []
}
EOF
done

# 更新项目统计
project_file="/shared/history/projects/$project_id/project.json"
cat "$project_file" | jq '.stats.total_tasks += 1' > "$project_file.tmp"
mv "$project_file.tmp" "$project_file"

# 更新全局索引
cat /shared/history/index.json | jq '.stats.total_tasks += 1' > /shared/history/index.json.tmp
mv /shared/history/index.json.tmp /shared/history/index.json

# 记录初始事件
event_id="EVT-$(date +%Y%m%d%H%M%S)-$(shuf -i 1000-9999 -n 1)"
cat "$task_dir/agents/gangzi.json" | jq ".events += [{
  \"event_id\": \"$event_id\",
  \"ts\": \"$ts\",
  \"event\": \"task_created\",
  \"phase\": \"initialized\",
  \"data\": {\"task_name\": \"${task_name}\", \"branch\": \"feature/${task_id}\"}
}]" > "$task_dir/agents/gangzi.json.tmp"
mv "$task_dir/agents/gangzi.json.tmp" "$task_dir/agents/gangzi.json"

# 保存 history_task_id 供后续使用
echo "$history_task_id" > /tmp/current_history_task_id
```

### 4. 创建 milestone.md

**模板：**
```markdown
# {需求名称} - 里程碑文档

## 项目概述
{需求描述}

---

## 里程碑 1: {里程碑名称}
**目标**: {具体目标}

### 任务
1. {任务A}
2. {任务B}

### 验证机制
\`\`\`bash
# 验证命令
\`\`\`

### 产物
- {文件1}
- {文件2}

**状态**: ⬜ 待开始

---

## 里程碑 2: {里程碑名称}
...

**文档版本**: v1.0  
**创建时间**: {当前时间}  
**创建者**: 刚子 🤖
```

**创建文件：**
```bash
cat > /workspace/milestone.md <<EOF
# ${task_name} - 里程碑文档
...
EOF
```

### 5. 初始化全局配置

**创建 /shared/config.json：**
```bash
cat > /shared/config.json <<EOF
{
  "version": "1.0",
  "status": "in_progress",
  "current_task": {
    "id": "${task_id}",
    "history_id": "${history_task_id}",
    "project_id": "${project_id}",
    "name": "${task_name}",
    "github_repo": "${target_repo}",
    "main_branch": "main",
    "target_branch": "feature/${task_id}",
    "milestone_file": "milestone.md",
    "labels": ["${task_id}", "review"],
    "started_at": "$(date -Iseconds)",
    "created_by": "gangzi"
  },
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

### 6. 创建Git分支

```bash
cd /workspace

# 确保在main分支
git checkout main

# 拉取最新代码
git pull origin main

# 创建feature分支
git checkout -b feature/${task_id}

# 提交 milestone.md 到 feature 分支
# 注意：milestone.md 已在第3步创建
git add milestone.md
git commit -m "初始化: ${task_name}"

# 推送到远程（milestone.md 会随分支一起推送）
git push -u origin feature/${task_id}
```

**重要说明：**
- milestone.md 只存在于 feature 分支
- main 分支不会有 milestone.md
- 煎饼 pull feature 分支时能获取到 milestone.md

**记录历史事件：**
```bash
# 记录 Git 分支创建事件
history_task_id=$(cat /tmp/current_history_task_id)
task_dir="/shared/history/projects/${project_id}/tasks/${history_task_id}"

event_id="EVT-$(date +%Y%m%d%H%M%S)-$(shuf -i 1000-9999 -n 1)"
ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat "$task_dir/agents/gangzi.json" | jq ".events += [{
  \"event_id\": \"$event_id\",
  \"ts\": \"$ts\",
  \"event\": \"branch_created\",
  \"phase\": \"initialized\",
  \"data\": {\"branch\": \"feature/${task_id}\", \"commit\": \"初始化: ${task_name}\"}
}]" > "$task_dir/agents/gangzi.json.tmp"
mv "$task_dir/agents/gangzi.json.tmp" "$task_dir/agents/gangzi.json"

# 更新任务阶段
cat "$task_dir/task.json" | jq ".current_phase = \"developing\" | .status = \"running\"" > "$task_dir/task.json.tmp"
mv "$task_dir/task.json.tmp" "$task_dir/task.json"

# 更新全局索引事件计数
cat /shared/history/index.json | jq '.stats.total_events += 2' > /shared/history/index.json.tmp
mv /shared/history/index.json.tmp /shared/history/index.json
```

### 7. 初始化状态文件

**创建 /shared/status/summary.json：**
```bash
cat > /shared/status/summary.json <<EOF
{
  "task_id": "${task_id}",
  "task_name": "${task_name}",
  "status": "in_progress",
  "started_at": "$(date -Iseconds)",
  "elapsed_seconds": 0,
  "agents": {
    "gangzi": {
      "phase": "监控中",
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
  "next_notification": "$(date -d '+10 minutes' -Iseconds)",
  "last_notification": null
}
EOF
```

### 8. 启动Cron任务

**启动煎饼的Cron：**
```bash
# 创建煎饼的Cron任务
openclaw cron add \
  --name "Jianbing Check Issues" \
  --cron "*/5 * * * *" \
  --tz "Asia/Shanghai" \
  --session isolated \
  --message "检查GitHub Issues" \
  --agent jianbing

# 获取Job ID
jianbing_job_id=$(openclaw cron list --json | jq -r '.[] | select(.name=="Jianbing Check Issues") | .jobId')

# 启用任务
openclaw cron enable "${jianbing_job_id}"
```

**启动墨汁儿的Cron：**
```bash
# 创建墨汁儿的Cron任务
openclaw cron add \
  --name "Mozhi Check Commits" \
  --cron "*/5 * * * *" \
  --tz "Asia/Shanghai" \
  --session isolated \
  --message "检查代码提交" \
  --agent mozhi

# 获取Job ID
mozhi_job_id=$(openclaw cron list --json | jq -r '.[] | select(.name=="Mozhi Check Commits") | .jobId')

# 启用任务
openclaw cron enable "${mozhi_job_id}"
```

**更新 config.json：**
```bash
# 更新Cron Job IDs
cat /shared/config.json | jq ".cron_jobs.jianbing = \"${jianbing_job_id}\" | .cron_jobs.mozhi = \"${mozhi_job_id}\"" > /shared/config.json.tmp
mv /shared/config.json.tmp /shared/config.json
```

### 9. 通知煎饼和墨汁儿

**通知煎饼（通过状态文件）：**
```bash
# 煎饼会在每次会话启动时读取 config.json
# 看到有 current_task 就知道有新任务
```

**通知墨汁儿（通过状态文件）：**
```bash
# 墨汁儿会在每次会话启动时读取 config.json
# 看到有 current_task 就知道有新任务
```

### 10. 通知K哥

**消息模板：**
```
✅ 任务已启动

📋 任务信息:
- ID: ${task_id}
- 名称: ${task_name}
- 分支: feature/${task_id}
- Milestone: milestone.md

🐶 煎饼: 准备开发
🦊 墨汁儿: 准备测试设计

⏰ 启动时间: $(date '+%Y-%m-%d %H:%M:%S')
⏱️ 下次进度汇报: 10分钟后

我会持续监控进度并每10分钟向你汇报！
```

**发送消息：**
```bash
# 通过消息平台发送给K哥
send_message_to_k_ge "${message}"
```

### 11. 更新自己的状态

```bash
cat > /shared/status/gangzi.json <<EOF
{
  "agent": "gangzi",
  "phase": "监控中",
  "phase_list": [
    "空闲",
    "监控中",
    "处理归档",
    "处理异常"
  ],
  "current_task": {
    "id": "${task_id}",
    "name": "${task_name}"
  },
  "phase_detail": {
    "started_at": "$(date -Iseconds)",
    "monitoring_active": true
  },
  "statistics": {
    "tasks_completed": 0,
    "tasks_failed": 0,
    "issues_timeout": 0,
    "tokens_used": 0,
    "duration_seconds": 0
  },
  "last_update": "$(date -Iseconds)",
  "heartbeat": "$(date -Iseconds)"
}
EOF
```

### 12. 记录日志

```bash
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] 刚子: 任务启动 - ${task_id} (${task_name})" >> /shared/logs/gangzi.log
```

---

## 错误处理

### 1. Git分支已存在

```bash
if git branch --list "feature/${task_id}" | grep -q .; then
  # 分支已存在
  send_message_to_k_ge "❌ 任务启动失败: 分支 feature/${task_id} 已存在"
  exit 1
fi
```

### 2. Cron任务创建失败

```bash
if [ -z "$jianbing_job_id" ] || [ -z "$mozhi_job_id" ]; then
  # Cron任务创建失败
  send_message_to_k_ge "⚠️ 任务启动警告: Cron任务创建失败，请手动启动"
  # 继续执行，不退出
fi
```

### 3. 文件写入失败

```bash
if [ ! -f "/shared/config.json" ]; then
  send_message_to_k_ge "❌ 任务启动失败: 无法创建配置文件"
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
  "branch": "feature/task-001",
  "started_at": "2026-03-09T09:00:00Z"
}
```

**失败：**
```json
{
  "success": false,
  "error": "分支已存在",
  "task_id": "task-001"
}
```

---

## 注意事项

1. **任务ID唯一性**：确保task_id不重复
2. **Git分支**：创建前检查是否已存在
3. **Cron任务**：记录Job ID到config.json，便于后续停止
4. **状态文件**：所有文件使用原子操作写入
5. **通知K哥**：任务启动后立即通知

---

## 📄 milestone.md 生命周期

### 完整流程

```
1. 刚子创建 feature 分支
   ├─ 创建 milestone.md
   ├─ commit: "初始化: {任务名称}"
   └─ milestone.md 存在于 feature 分支

2. 煎饼开发
   ├─ git pull feature/{task_id}
   ├─ 读取 milestone.md
   ├─ 开发代码
   └─ milestone.md 仍在 feature 分支

3. 归档
   ├─ mv milestone.md milestones/{序号}_{名称}.md
   ├─ commit: "归档: {任务名称}"
   └─ milestone.md 被移动到 milestones/ 目录

4. 合并到 main
   ├─ git checkout main
   ├─ git merge feature/{task_id} --no-ff
   └─ main 分支包含 milestones/，       但不包含根目录的 milestone.md
```

### 关键点

- **milestone.md 只存在于 feature 分支**， main 分支不会有
- **归档后 milestone.md 移动到 milestones/ 目录**
- **main 分支只包含归档后的文件**，不包含 milestone.md

---

_刚子的技能：启动任务 🤖_
