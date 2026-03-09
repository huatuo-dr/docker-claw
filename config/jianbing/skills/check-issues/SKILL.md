---
name: check-issues
description: 定期检查GitHub Issues（Cron 5分钟）
triggers:
  - cron: "*/5 * * * *"
---

# Check Issues Skill

## 执行前提检查

```bash
config=$(cat /shared/config.json)
status=$(cat /shared/status/jianbing.json)

# 只在开发状态且"等待Issue"阶段执行
if [[ $(echo "$config" | jq -r '.status') != "in_progress" ]]; then
  exit 0
fi

if [[ $(echo "$status" | jq -r '.phase') != "等待Issue" ]]; then
  exit 0
fi
```

## 执行步骤

### 1. 读取任务配置

```bash
task_id=$(echo "$config" | jq -r '.current_task.id')
labels=$(echo "$config" | jq -r '.current_task.labels | join(",")')
github_repo=$(echo "$config" | jq -r '.current_task.github_repo')
```

### 2. 查询GitHub Issues

```bash
# 查询open的Issues，带有指定labels
issues=$(gh issue list \
  --repo "$github_repo" \
  --label "$labels" \
  --state open \
  --json number,title,comments \
  --jq '.[]')

if [[ -z "$issues" ]]; then
  echo "没有需要处理的Issue"
  exit 0
fi
```

### 3. 过滤已处理的Issue

```bash
# 读取上次处理的Issue
last_issue=$(echo "$status" | jq -r '.current_issue.number // 0')

# 找出未处理的Issue
for issue in $issues; do
  issue_number=$(echo "$issue" | jq -r '.number')
  
  # 跳过已处理的Issue
  if [[ "$issue_number" == "$last_issue" ]]; then
    continue
  fi
  
  # 找到新Issue，处理它
  handle_issue "$issue_number"
  break
done
```

### 4. 调用handle-issue技能

```bash
# 如果有新Issue
if [[ -n "$new_issue_number" ]]; then
  # 更新状态
  update_status "处理Issue" --issue "$new_issue_number"
  
  # 调用handle-issue技能
  call_skill "handle-issue" "{
    \"issue_number\": $new_issue_number
  }"
fi
```

---

_煎饼的技能：检查Issue（Cron调用）🐶_
