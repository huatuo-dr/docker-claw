---
name: history
description: 历史记录管理 - 记录、查询和分析Agent工作历史
trigger: manual
---

# 历史记录管理技能

## 概述

管理Docker-Claw系统的历史数据，以**项目→任务→Agent**三级结构记录所有事件。

## 核心能力

### 1. 记录事件（append_event）

**使用场景**：任何Agent状态变更时记录事件

**输入参数**：
- `task_id`: 任务ID
- `agent`: Agent名称（gangzi/jianbing/mozhi）
- `event`: 事件类型（见 EVENT-TYPES.md）
- `phase`: 当前阶段（可选，默认不更新）
- `data`: 事件数据（对象，可选）

**示例**：
```json
{
  "task_id": "TASK-20241215-001",
  "agent": "jianbing",
  "event": "push_code",
  "phase": "waiting_review",
  "data": {
    "commits_count": 5
  }
}
```

**执行步骤**：

1. 验证任务存在
   ```bash
   task_dir="/shared/history/projects/{project_id}/tasks/{task_id}"
   if [ ! -d "$task_dir" ]; then
     echo "错误: 任务不存在"
     exit 1
   fi
   ```

2. 生成事件ID和时间戳
   ```bash
   event_id="EVT-$(date +%Y%m%d%H%M%S)-$(shuf -i 1000-9999 -n 1)"
   ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
   ```

3. 追加到Agent事件文件
   ```bash
   agent_file="$task_dir/agents/{agent}.json"
   
   # 读取现有事件
   events=$(cat "$agent_file" | jq -r '.events')
   
   # 追加新事件
   new_event=$(cat <<EOF
   {
     "event_id": "$event_id",
     "ts": "$ts",
     "event": "{event}",
     "phase": "{phase}",
     "data": {data}
   }
   EOF
   )
   
   # 更新文件
   cat "$agent_file" | jq ".events += [$new_event]" > "$agent_file.tmp"
   mv "$agent_file.tmp" "$agent_file"
   ```

4. 更新任务阶段（如果提供了phase）
   ```bash
   if [ -n "{phase}" ]; then
     cat "$task_dir/task.json" | jq ".current_phase = \"{phase}\"" > "$task_dir/task.json.tmp"
     mv "$task_dir/task.json.tmp" "$task_dir/task.json"
   fi
   ```

5. 更新全局索引
   ```bash
   index_file="/shared/history/index.json"
   cat "$index_file" | jq '.stats.total_events += 1' > "$index_file.tmp"
   mv "$index_file.tmp" "$index_file"
   ```

---

### 2. 创建项目（create_project）

**输入参数**：
- `project_name`: 项目名称
- `description`: 项目描述（可选）

**执行步骤**：

1. 生成项目ID
   ```bash
   project_id="PROJ-$(echo {project_name} | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
   project_dir="/shared/history/projects/$project_id"
   ```

2. 检查项目是否已存在
   ```bash
   if [ -d "$project_dir" ]; then
     echo "项目已存在: $project_id"
     echo "项目路径: $project_dir"
     exit 0
   fi
   ```

3. 创建项目目录结构
   ```bash
   mkdir -p "$project_dir/tasks"
   ```

4. 创建project.json
   ```bash
   ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
   cat > "$project_dir/project.json" <<EOF
   {
     "project_id": "$project_id",
     "name": "{project_name}",
     "description": "{description}",
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
   ```

5. 更新全局索引
   ```bash
   index_file="/shared/history/index.json"
   
   # 如果索引文件不存在，先创建
   if [ ! -f "$index_file" ]; then
     cat > "$index_file" <<EOF
   {
     "version": "1.0",
     "last_updated": "$ts",
     "projects": [],
     "stats": {
       "total_projects": 0,
       "total_tasks": 0,
       "total_events": 0
     }
   }
   EOF
   fi
   
   # 添加项目到索引
   project_entry="{\"project_id\": \"$project_id\", \"name\": \"{project_name}\", \"created_at\": \"$ts\"}"
   cat "$index_file" | jq ".projects += [$project_entry] | .stats.total_projects += 1 | .last_updated = \"$ts\"" > "$index_file.tmp"
   mv "$index_file.tmp" "$index_file"
   ```

6. 输出结果
   ```
   ✅ 项目创建成功
   项目ID: PROJ-{project_name}
   项目路径: {project_dir}
   ```

---

### 3. 创建任务（create_task）

**输入参数**：
- `project_id`: 项目ID
- `task_name`: 任务名称
- `description`: 任务描述（可选）

**执行步骤**：

1. 验证项目存在
   ```bash
   project_dir="/shared/history/projects/{project_id}"
   if [ ! -d "$project_dir" ]; then
     echo "错误: 项目不存在: {project_id}"
     exit 1
   fi
   ```

2. 生成任务ID
   ```bash
   timestamp=$(date +%Y%m%d%H%M%S)
   seq=$(ls "$project_dir/tasks" 2>/dev/null | grep "TASK-$timestamp" | wc -l)
   seq_padded=$(printf "%03d" $seq)
   task_id="TASK-$timestamp-$seq_padded"
   ```

3. 创建任务目录结构
   ```bash
   task_dir="$project_dir/tasks/$task_id"
   mkdir -p "$task_dir/agents"
   ```

4. 创建task.json
   ```bash
   ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
   cat > "$task_dir/task.json" <<EOF
   {
     "task_id": "$task_id",
     "project_id": "{project_id}",
     "name": "{task_name}",
     "description": "{description}",
     "branch": "feature/$task_id",
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
   ```

5. 创建Agent事件文件（空事件列表）
   ```bash
   for agent in gangzi jianbing mozhi; do
     cat > "$task_dir/agents/$agent.json" <<EOF
   {
     "task_id": "$task_id",
     "agent": "$agent",
     "events": []
   }
   EOF
   done
   ```

6. 记录初始事件
   - 自动调用 `append_event`
   - task_id: `{task_id}`
   - agent: `gangzi`
   - event: `task_created`
   - data: `{"task_name": "{task_name}", "branch": "feature/$task_id"}`

7. 更新项目统计
   ```bash
   cat "$project_dir/project.json" | jq '.stats.total_tasks += 1' > "$project_dir/project.json.tmp"
   mv "$project_dir/project.json.tmp" "$project_dir/project.json"
   ```

8. 更新全局索引
   ```bash
   index_file="/shared/history/index.json"
   cat "$index_file" | jq '.stats.total_tasks += 1' > "$index_file.tmp"
   mv "$index_file.tmp" "$index_file"
   ```

9. 输出结果
   ```
   ✅ 任务创建成功
   任务ID: {task_id}
   任务路径: {task_dir}
   分支: feature/{task_id}
   ```

---

### 4. 更新任务状态（update_task_status）

**输入参数**：
- `task_id`: 任务ID
- `status`: 新状态（pending/running/completed/failed）
- `completed_at`: 完成时间（可选，完成时设置）

**执行步骤**：

1. 定位任务文件
   ```bash
   task_file=$(find /shared/history/projects -type f -name "task.json" -exec grep -l "\"task_id\": \"{task_id}\"" {} \;)
   
   if [ -z "$task_file" ]; then
     echo "错误: 任务不存在"
     exit 1
   fi
   ```

2. 更新任务状态
   ```bash
   if [ "{status}" = "completed" ]; then
     ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
     cat "$task_file" | jq ".status = \"{status}\" | .completed_at = \"$ts\"" > "$task_file.tmp"
   else
     cat "$task_file" | jq ".status = \"{status}\"" > "$task_file.tmp"
   fi
   mv "$task_file.tmp" "$task_file"
   ```

3. 更新项目统计（如果任务完成）
   ```bash
   if [ "{status}" = "completed" ]; then
     project_dir=$(dirname $(dirname "$task_file"))
     cat "$project_dir/project.json" | jq '.stats.completed_tasks += 1' > "$project_dir/project.json.tmp"
     mv "$project_dir/project.json.tmp" "$project_dir/project.json"
   fi
   ```

---

### 5. 查询历史（query_history）

**输入参数**（至少提供一个）：
- `project_id`: 按项目查询
- `task_id`: 按任务查询
- `agent`: 按Agent查询
- `event`: 按事件类型查询
- `from_date`: 起始日期（可选）
- `to_date`: 结束日期（可选）
- `limit`: 返回数量限制（默认100）

**查询示例**：

#### 查询某个任务的所有事件
```bash
task_id="TASK-20241215-001"
task_dir=$(find /shared/history/projects -type d -name "$task_id")

echo "任务: $task_id"
echo "================================"
for agent_file in "$task_dir"/agents/*.json; do
  agent=$(basename "$agent_file" .json)
  echo -e "\n[$agent]"
  cat "$agent_file" | jq -r '.events[] | "  \(.ts) - \(.event)"'
done
```

#### 查询某个Agent在某个任务中的事件
```bash
task_id="TASK-20241215-001"
agent="jianbing"
task_dir=$(find /shared/history/projects -type d -name "$task_id")

cat "$task_dir/agents/$agent.json" | jq -r '.events[] | "\(.ts) [\(.phase)] \(.event)"'
```

#### 查询某个项目的所有任务
```bash
project_id="PROJ-user-system"
project_dir="/shared/history/projects/$project_id"

echo "项目: $project_id"
echo "================================"
for task_dir in "$project_dir"/tasks/*/; do
  task_id=$(basename "$task_dir")
  task_name=$(cat "$task_dir/task.json" | jq -r '.name')
  status=$(cat "$task_dir/task.json" | jq -r '.status')
  echo "- $task_id: $task_name [$status]"
done
```

#### 查询特定事件类型
```bash
find /shared/history/projects -type f -name "jianbing.json" -exec sh -c '
  file="$1"
  task_id=$(jq -r ".task_id" "$file")
  jq -r --arg task "$task_id" ".events[] | select(.event == \"push_code\") | \"\($task) - \(.ts) - \(.event)\"" "$file"
' _ {} \;
```

---

### 6. 获取任务统计（get_task_stats）

**输入参数**：
- `task_id`: 任务ID

**执行步骤**：

1. 定位任务
   ```bash
   task_dir=$(find /shared/history/projects -type d -name "{task_id}")
   task_file="$task_dir/task.json"
   ```

2. 计算时长
   ```bash
   created=$(cat "$task_file" | jq -r '.created_at')
   completed=$(cat "$task_file" | jq -r '.completed_at // now')
   
   # 计算总时长
   if [ "$completed" != "null" ]; then
     duration=$(($(date -d "$completed" +%s) - $(date -d "$created" +%s)))
   else
     duration=$(($(date +%s) - $(date -d "$created" +%s)))
   fi
   
   hours=$((duration / 3600))
   minutes=$(((duration % 3600) / 60))
   ```

3. 统计各Agent事件数
   ```bash
   for agent in gangzi jianbing mozhi; do
     event_count=$(cat "$task_dir/agents/$agent.json" | jq '.events | length')
     echo "$agent: $event_count 事件"
   done
   ```

4. 输出完整统计
   ```
   任务: {task_id}
   ========================================
   名称: {task_name}
   状态: {status}
   阶段: {current_phase}
   
   时间统计:
     创建时间: {created_at}
     完成时间: {completed_at}
     总时长: {hours}h {minutes}m
   
   Agent活动:
     刚子: X 事件
     煎饼: Y 事件
     墨汁儿: Z 事件
   
   代码统计:
     Commits: {commits_count}
     Issues: {issues_count}
     修复轮次: {issue_rounds}
   ```

---

## 使用指南

### 刚子调用时机

| 场景 | 调用的能力 |
|-----|----------|
| 启动新项目 | `create_project` |
| 启动新任务 | `create_task` → `append_event(task_created)` |
| 任务状态变更 | `update_task_status` + `append_event(task_started/completed/failed)` |
| 检测到异常 | `append_event(exception_detected)` |
| 归档任务 | `append_event(archive_started/completed)` |
| 用户查询历史 | `query_history` |
| 用户查看统计 | `get_task_stats` |

### 煎饼/墨汁儿调用时机

通过共享状态文件通知刚子，由刚子统一记录：

1. Agent更新自己的状态文件
2. 刚子的Heartbeat检测到变化
3. 刚子调用 `append_event` 记录事件

---

## 错误处理

- 任务不存在：返回错误，不创建
- 项目不存在：返回错误，不创建
- 事件文件损坏：备份原文件，创建新文件
- 索引文件损坏：重建索引（扫描所有项目/任务）

---

## 数据备份

建议定期备份 `/shared/history/` 目录：

```bash
# 备份命令
tar -czf history-backup-$(date +%Y%m%d).tar.gz /shared/history/

# 恢复命令
tar -xzf history-backup-YYYYMMDD.tar.gz -C /
```
