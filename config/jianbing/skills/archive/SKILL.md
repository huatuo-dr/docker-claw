---
name: archive
description: 归档任务，合并分支到main
triggers:
  - event: archive_triggered
---

# Archive Skill

## 执行前提检查

```bash
config=$(cat /shared/config.json)

# 检查归档是否触发
if [[ $(echo "$config" | jq -r '.archive_triggered') != "true" ]]; then
  echo "归档未触发"
  exit 0
fi

# 检查是否已批准
approved_by=$(echo "$config" | jq -r '.archive_approved_by')
if [[ -z "$approved_by" || "$approved_by" == "null" ]]; then
  echo "归档未批准"
  exit 0
fi
```

## 执行步骤

### 1. 更新状态

```bash
cat > /shared/status/jianbing.json <<EOF
{
  "agent": "jianbing",
  "phase": "归档中",
  "current_task": $(cat /shared/config.json | jq '.current_task'),
  "phase_detail": {
    "started_at": "$(date -Iseconds)",
    "archive_status": "processing"
  },
  "last_update": "$(date -Iseconds)",
  "heartbeat": "$(date -Iseconds)"
}
EOF
```

### 2. 获取序号

```bash
# 查看已归档的文件数量
next_num=$(ls /workspace/milestones/ 2>/dev/null | wc -l | awk '{printf "%02d", $1+1}')

# 获取任务名称
task_name=$(cat /shared/config.json | jq -r '.current_task.name')
task_id=$(cat /shared/config.json | jq -r '.current_task.id')
```

### 3. 归档milestone

```bash
# 重命名并移动
cd /workspace
mv milestone.md "milestones/${next_num}_${task_name}.md"

# 提交
git add milestones/
git commit -m "归档: ${task_name}"
```

### 4. 切换到main分支

```bash
git checkout main
git pull origin main
```

### 5. 合并feature分支

```bash
feature_branch="feature/${task_id}"

# 合并（--no-ff保留分支历史）
git merge "$feature_branch" --no-ff -m "合并: ${task_name}"

if [[ $? -ne 0 ]]; then
  # 合并失败，通知刚子
  notify_gangzi "Git合并冲突，需要手动解决"
  exit 1
fi
```

### 6. 推送到远程

```bash
git push origin main
```

### 7. 删除feature分支

```bash
# 删除本地分支
git branch -d "$feature_branch"

# 删除远程分支
git push origin --delete "$feature_branch"
```

### 8. 更新最终状态

```bash
cat > /shared/status/jianbing.json <<EOF
{
  "agent": "jianbing",
  "phase": "等待需求",
  "current_task": null,
  "phase_detail": {
    "started_at": null,
    "archive_status": "completed"
  },
  "statistics": {
    "total_commits": $(cat /shared/status/jianbing.json | jq '.statistics.total_commits'),
    "total_pushes": $(cat /shared/status/jianbing.json | jq '.statistics.total_pushes + 1'),
    "files_changed": 0,
    "lines_added": 0,
    "lines_deleted": 0,
    "tokens_used": 0,
    "duration_seconds": 0
  },
  "last_update": "$(date -Iseconds)",
  "heartbeat": "$(date -Iseconds)"
}
EOF
```

### 9. 通知刚子

```bash
# 通过状态文件通知
# 刚子的monitor技能会检测到phase变化
```

### 10. 记录日志

```bash
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] 煎饼: 归档完成 - ${task_id} (${task_name})" >> /shared/logs/jianbing.log
```

---

## 错误处理

### Git合并冲突

```bash
if git merge失败; then
  # 回滚
  git merge --abort
  
  # 通知刚子
  notify_gangzi "Git合并冲突: ${conflict_files}"
  
  # 等待手动解决
  exit 1
fi
```

---

_煎饼的技能：归档任务 🐶_
