---
name: create-issue
description: 创建GitHub Issue
triggers:
  - manual: true
---

# Create Issue Skill

## 执行步骤

### 1. 准备Issue内容

```bash
task_id=$(cat /shared/config.json | jq -r '.current_task.id')
task_name=$(cat /shared/config.json | jq -r '.current_task.name')
labels=$(cat /shared/config.json | jq -r '.current_task.labels | join(",")')
github_repo=$(cat /shared/config.json | jq -r '.current_task.github_repo')

# 生成Issue标题
title="[Review] ${task_name} - 发现${#bugs[@]}个问题"

# 生成Issue内容
body="# 问题类型统计
- 🔴 严重: $(echo "${bugs[@]}" | jq -r 'map(select(.severity=="high")) | length') 个
- 🟡 中等: $(echo "${bugs[@]}" | jq -r 'map(select(.severity=="medium")) | length') 个
- 🟢 轻微: $(echo "${bugs[@]}" | jq -r 'map(select(.severity=="low")) | length') 个

## 问题列表

$(for bug in "${bugs[@]}"; do
  severity_emoji=$(if [[ $(echo "$bug" | jq -r '.severity') == "high" ]]; then echo "🔴"; elif [[ $(echo "$bug" | jq -r '.severity') == "medium" ]]; then echo "🟡"; else echo "🟢"; fi)
  echo "### ${severity_emoji} Bug $(echo "$bug" | jq -r '.id'): $(echo "$bug" | jq -r '.description') ($(echo "$bug" | jq -r '.severity'))"
  echo "**位置**: \`$(echo "$bug" | jq -r '.location')\`"
  echo ""
done)

## 测试覆盖

- ✅ 正常流程: ${passed}/10 通过
- ❌ 异常流程: ${failed}/5 通过
- ⚠️ 边界情况: 2/3 通过
- ❌ 安全测试: 0/3 通过
"
```

### 2. 创建Issue

```bash
issue_url=$(gh issue create \
  --repo "$github_repo" \
  --title "$title" \
  --body "$body" \
  --label "$labels")

issue_number=$(echo "$issue_url" | grep -oE '[0-9]+$')
```

### 3. 创建Issue追踪文件

```bash
cat > /shared/issues/${issue_number}.json <<EOF
{
  "issue_number": $issue_number,
  "task_id": "$task_id",
  "url": "$issue_url",
  "created_at": "$(date -Iseconds)",
  "created_by": "mozhi",
  "bugs": $(echo "${bugs[@]}" | jq -R .),
  "timeline": [
    {
      "timestamp": "$(date -Iseconds)",
      "action": "issue_created",
      "by": "mozhi",
      "comment_id": 1
    }
  ],
  "comments_count": 1,
  "max_comments": 15,
  "status": "open"
}
EOF
```

### 4. 更新状态

```bash
cat /shared/status/mozhi.json | jq "
  .phase = \"等待Issue回复\" |
  .current_issue = {
    \"number\": $issue_number,
    \"url\": \"$issue_url\",
    \"created_at\": \"$(date -Iseconds)\",
    \"comments_count\": 1,
    \"max_comments\": 15,
    \"status\": \"open\"
  } |
  .last_update = \"$(date -Iseconds)\"
" > /shared/status/mozhi.json.tmp

mv /shared/status/mozhi.json.tmp /shared/status/mozhi.json
```

---

_墨汁儿的技能：创建Issue 🦊_
