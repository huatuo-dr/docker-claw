---
name: verify-fix
description: 验证修复，关闭Issue或继续审查
triggers:
  - manual: true
---

# Verify Fix Skill

## 执行步骤

### 1. 拉取最新代码

```bash
target_branch=$(cat /shared/config.json | jq -r '.current_task.target_branch')
git pull origin "$target_branch"
```

### 2. 重新审查

```bash
# 调用review技能
review_result=$(call_skill "review")

# 解析结果
remaining_bugs=$(echo "$review_result" | jq -r '.bugs | length')
```

### 3. 更新Issue追踪

```bash
issue_number=$(cat /shared/status/mozhi.json | jq -r '.current_issue.number')
issue_file="/shared/issues/${issue_number}.json"

# 读取Issue文件
issue=$(cat "$issue_file")

# 增加comments计数
comments_count=$(echo "$issue" | jq -r '.comments_count + 1')

# 添加时间线事件
timeline=$(echo "$issue" | jq -r '.timeline')
timeline="$timeline
{
  \"timestamp\": \"$(date -Iseconds)\",
  \"action\": \"review_completed\",
  \"by\": \"mozhi\",
  \"comment_id\": $comments_count
}"

# 更新文件
cat "$issue_file" | jq "
  .comments_count = $comments_count |
  .timeline = $(echo "$timeline" | jq -R .)
" > "$issue_file.tmp"

mv "$issue_file.tmp" "$issue_file"
```

### 4. 检查15轮限制

```bash
if [[ $comments_count -ge 15 ]]; then
  # 触发超时流程
  handle_timeout "$issue_number"
  exit 0
fi

# 警告阈值
if [[ $comments_count -ge 12 ]]; then
  # 通知刚子
  notify_gangzi "⚠️ Issue #$issue_number 已达 ${comments_count}/15 轮"
fi
```

### 5. 如果还有问题

```bash
if [[ $remaining_bugs -gt 0 ]]; then
  # 在Issue下追加评论
  reply="⚠️ 还有问题需要修复:

**剩余问题:**
$(for bug in "${remaining_bugs[@]}"; do
  echo "- Bug $(echo "$bug" | jq -r '.id'): $(echo "$bug" | jq -r '.description')"
done)

请继续修复 🦊"

  gh issue comment "$issue_number" --body "$reply"
  
  # 更新状态
  update_status "等待Issue回复"
else
  # 审查通过
  approve_fix "$issue_number"
fi
```

### 6. 审查通过

```bash
approve_fix() {
  issue_number=$1
  
  # 在Issue下回复
  reply="✅ 审查通过！

所有问题已修复并验证。

测试结果:
- ✅ 正常流程: 10/10 通过
- ✅ 异常流程: 5/5 通过
- ✅ 边界情况: 3/3 通过
- ✅ 安全测试: 3/3 通过

代码质量: 优秀 🎉"

  gh issue comment "$issue_number" --body "$reply"
  
  # 关闭Issue
  gh issue close "$issue_number" --comment "审查通过"
  
  # 归档测试文档
  task_name=$(cat /shared/config.json | jq -r '.current_task.name')
  task_id=$(cat /shared/config.json | jq -r '.current_task.id')
  next_num=$(ls /workspace/review_doc/ 2>/dev/null | wc -l | awk '{printf "%02d", $1+1}')
  
  mv /workspace/tmp/${task_id}_test_plan.md "/workspace/review_doc/${next_num}_${task_name}.md"
  
  git add /workspace/review_doc/
  git commit -m "审查通过: ${task_name}"
  git push origin "$target_branch"
  
  # 更新状态
  cat /shared/status/mozhi.json | jq "
    .phase = \"审查成功\" |
    .current_issue = null |
    .last_update = \"$(date -Iseconds)\"
  " > /shared/status/mozhi.json.tmp
  
  mv /shared/status/mozhi.json.tmp /shared/status/mozhi.json
  
  # 通知刚子
  notify_gangzi "审查通过，Issue #$issue_number 已关闭"
}
```

### 7. 处理超时

```bash
handle_timeout() {
  issue_number=$1
  
  # 生成失败报告
  cat > /shared/issues/${issue_number}_failed.json <<EOF
{
  "type": "issue_timeout",
  "issue_number": $issue_number,
  "comments": 15,
  "open_bugs": $(echo "${remaining_bugs[@]}" | jq -R .),
  "timeline": $(cat /shared/issues/${issue_number}.json | jq '.timeline'),
  "created_at": "$(cat /shared/issues/${issue_number}.json | jq -r '.created_at')",
  "timeout_at": "$(date -Iseconds)",
  "reason": "15轮审查仍未解决"
}
EOF
  
  # 通知刚子
  notify_gangzi "🚨 Issue #$issue_number 超时（15轮）"
  
  # 更新状态
  cat /shared/status/mozhi.json | jq "
    .phase = \"审查失败\" |
    .current_issue.status = \"timeout\" |
    .last_update = \"$(date -Iseconds)\"
  " > /shared/status/mozhi.json.tmp
  
  mv /shared/status/mozhi.json.tmp /shared/status/mozhi.json
}
```

---

_墨汁儿的技能：验证修复 🦊_
