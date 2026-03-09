---
name: check-commits
description: 检查代码提交（Cron 5分钟）
triggers:
  - cron: "*/5 * * * *"
---

# Check Commits Skill

## 执行前提检查

```bash
config=$(cat /shared/config.json)
status=$(cat /shared/status/mozhi.json)

# 只在开发状态执行
if [[ $(echo "$config" | jq -r '.status') != "in_progress" ]]; then
  exit 0
fi

# 只在特定阶段执行
phase=$(echo "$status" | jq -r '.phase')
if [[ "$phase" != "等待开发提交" && "$phase" != "等待Issue回复" ]]; then
  exit 0
fi
```

## 执行步骤

### 1. 读取配置

```bash
target_branch=$(echo "$config" | jq -r '.current_task.target_branch')
last_checked=$(echo "$status" | jq -r '.phase_detail.last_checked_commit // ""')
```

### 2. 拉取最新代码

```bash
cd /workspace
git pull origin "$target_branch"
```

### 3. 检查commit历史

```bash
# 获取上次检查后的commits
if [[ -n "$last_checked" ]]; then
  commits=$(git log "$last_checked"..HEAD --oneline)
else
  # 首次检查，获取最近1小时的commits
  commits=$(git log --since="1 hour ago" --oneline)
fi

if [[ -z "$commits" ]]; then
  echo "没有新的提交"
  exit 0
fi
```

### 4. 更新状态

```bash
latest_commit=$(git log -1 --format="%H")

cat /shared/status/mozhi.json | jq "
  .phase = \"审查中\" |
  .phase_detail.target_commit = \"$latest_commit\" |
  .phase_detail.last_checked_commit = \"$latest_commit\" |
  .last_update = \"$(date -Iseconds)\"
" > /shared/status/mozhi.json.tmp

mv /shared/status/mozhi.json.tmp /shared/status/mozhi.json
```

### 5. 调用review技能

```bash
# 调用review技能
call_skill "review" "{
  \"commit\": \"$latest_commit\",
  \"commits\": \"$commits\"
}"
```

---

_墨汁儿的技能：检查提交 🦊_
