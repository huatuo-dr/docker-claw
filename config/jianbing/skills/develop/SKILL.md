---
name: develop
description: 开发功能，读取milestone.md并实现代码
triggers:
  - manual: true
  - event: new_task
---

# Develop Skill

## 功能

读取milestone.md，逐步实现功能代码。

## 执行步骤

### 1. 检查任务状态

```bash
# 读取全局配置
config=$(cat /shared/config.json)
task_id=$(echo "$config" | jq -r '.current_task.id')
task_name=$(echo "$config" | jq -r '.current_task.name')
target_branch=$(echo "$config" | jq -r '.current_task.target_branch')
milestone_file=$(echo "$config" | jq -r '.current_task.milestone_file')

if [[ "$task_id" == "null" || -z "$task_id" ]]; then
  echo "没有正在进行的任务"
  exit 0
fi

# 检查是否在正确的分支
current_branch=$(git branch --show-current)
if [[ "$current_branch" != "$target_branch" ]]; then
  echo "错误: 当前分支 $current_branch，应该是 $target_branch"
  exit 1
fi
```

### 2. 读取milestone.md

```bash
if [ ! -f "/workspace/$milestone_file" ]; then
  echo "错误: milestone.md 不存在"
  # 通知刚子
  update_status "等待需求"
  notify_gangzi "milestone.md 不存在"
  exit 1
fi

milestone=$(cat /workspace/$milestone_file)
```

### 3. 更新状态

```bash
cat > /shared/status/jianbing.json <<EOF
{
  "agent": "jianbing",
  "phase": "开发需求",
  "phase_list": [
    "等待需求",
    "开发需求",
    "等待Issue",
    "处理Issue",
    "等待归档指令",
    "归档中"
  ],
  "current_task": {
    "id": "$task_id",
    "milestone": "$milestone_file",
    "branch": "$target_branch"
  },
  "phase_detail": {
    "started_at": "$(date -Iseconds)",
    "local_commits": 0,
    "last_push_at": null,
    "ready_to_push": false
  },
  "current_issue": null,
  "statistics": {
    "total_commits": 0,
    "total_pushes": 0,
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

### 4. 解析milestone.md

**提取里程碑列表：**
```bash
# 使用grep提取所有里程碑
milestones=$(echo "$milestone" | grep -E "^## 里程碑" | wc -l)

# 提取每个里程碑的状态
pending_milestones=()
for i in $(seq 1 $milestones); do
  status=$(echo "$milestone" | grep -A 20 "## 里程碑 $i:" | grep "状态" | grep -o "⬜\|🔄\|✅")
  
  if [[ "$status" == "⬜" ]]; then
    pending_milestones+=($i)
  fi
done

echo "发现 ${#pending_milestones[@]} 个待完成的里程碑"
```

### 5. 逐个完成里程碑

```bash
total_commits=0
start_time=$(date +%s)

for milestone_num in "${pending_milestones[@]}"; do
  echo "========================================"
  echo "开始处理 里程碑 $milestone_num"
  echo "========================================"
  
  # 提取里程碑内容
  milestone_content=$(echo "$milestone" | sed -n "/## 里程碑 $milestone_num:/,/## 里程碑/p" | head -n -1)
  
  # 提取目标
  goal=$(echo "$milestone_content" | grep "目标" | sed 's/\*\*目标\*\*: //')
  echo "目标: $goal"
  
  # 提取任务列表
  tasks=$(echo "$milestone_content" | grep -E "^[0-9]+\." | sed 's/^[0-9]*\. //')
  
  # 更新状态为"进行中"
  sed -i "s/## 里程碑 $milestone_num:/## 里程碑 $milestone_num: (进行中)/" /workspace/$milestone_file
  sed -i "/## 里程碑 $milestone_num/,/状态:/ s/⬜ 待开始/🔄 进行中/" /workspace/$milestone_file
  
  # 执行任务（这里需要根据实际需求编写代码）
  # 这是一个示例，实际需要AI来生成代码
  
  echo "任务列表:"
  echo "$tasks"
  
  # 示例：创建文件、编写代码等
  # 实际操作需要根据milestone内容动态执行
  
  # 假设完成了这个里程碑
  # 提交commit
  git add .
  
  commit_message="M${milestone_num}: ${goal}"
  git commit -m "$commit_message"
  
  total_commits=$((total_commits + 1))
  
  # 更新milestone状态为"已完成"
  sed -i "/## 里程碑 $milestone_num/,/状态:/ s/🔄 进行中/✅ 已完成/" /workspace/$milestone_file
  
  # 更新状态文件
  cat /shared/status/jianbing.json | jq "
    .phase_detail.local_commits = $total_commits |
    .statistics.total_commits = $total_commits
  " > /shared/status/jianbing.json.tmp
  mv /shared/status/jianbing.json.tmp /shared/status/jianbing.json
  
  echo "✅ 里程碑 $milestone_num 完成"
done
```

### 6. 统计代码变更

```bash
# 统计文件变更
files_changed=$(git diff --stat HEAD~$total_commits | tail -1 | awk '{print $1}')
lines_added=$(git diff --shortstat HEAD~$total_commits | grep -o '[0-9]* insertion' | awk '{print $1}')
lines_deleted=$(git diff --shortstat HEAD~$total_commits | grep -o '[0-9]* deletion' | awk '{print $1}')

# 计算耗时
end_time=$(date +%s)
duration=$((end_time - start_time))

# 更新统计信息
cat /shared/status/jianbing.json | jq "
  .phase_detail.local_commits = $total_commits |
  .phase_detail.ready_to_push = true |
  .statistics.total_commits = $total_commits |
  .statistics.files_changed = ${files_changed:-0} |
  .statistics.lines_added = ${lines_added:-0} |
  .statistics.lines_deleted = ${lines_deleted:-0} |
  .statistics.duration_seconds = $duration
" > /shared/status/jianbing.json.tmp
mv /shared/status/jianbing.json.tmp /shared/status/jianbing.json
```

### 7. 本地测试

```bash
echo "开始本地测试..."

# 根据项目类型执行不同的测试
if [ -f "package.json" ]; then
  # Node.js项目
  npm test
elif [ -f "requirements.txt" ]; then
  # Python项目
  python -m pytest
elif [ -f "go.mod" ]; then
  # Go项目
  go test ./...
fi

test_result=$?

if [[ $test_result -ne 0 ]]; then
  echo "❌ 测试失败，不push"
  # 更新状态
  cat /shared/status/jianbing.json | jq ".phase_detail.test_passed = false" > /shared/status/jianbing.json.tmp
  mv /shared/status/jianbing.json.tmp /shared/status/jianbing.json
  
  # 修复问题后重试
  exit 1
fi

echo "✅ 测试通过"
```

### 8. Push代码

```bash
echo "开始push代码..."

# 加锁
if [ ! -f /shared/locks/jianbing.lock ]; then
  touch /shared/locks/jianbing.lock
  
  # Push
  git push origin $target_branch
  
  push_result=$?
  
  # 解锁
  rm /shared/locks/jianbing.lock
  
  if [[ $push_result -ne 0 ]]; then
    echo "❌ Push失败"
    # 通知刚子
    notify_gangzi "Git push失败"
    exit 1
  fi
  
  echo "✅ Push成功"
else
  echo "⚠️ 其他操作正在进行，等待..."
  sleep 10
  # 重试
fi
```

### 9. 更新最终状态

```bash
cat > /shared/status/jianbing.json <<EOF
{
  "agent": "jianbing",
  "phase": "等待Issue",
  "phase_list": [
    "等待需求",
    "开发需求",
    "等待Issue",
    "处理Issue",
    "等待归档指令",
    "归档中"
  ],
  "current_task": {
    "id": "$task_id",
    "milestone": "$milestone_file",
    "branch": "$target_branch"
  },
  "phase_detail": {
    "started_at": "$(date -Iseconds)",
    "local_commits": $total_commits,
    "last_push_at": "$(date -Iseconds)",
    "ready_to_push": false
  },
  "current_issue": null,
  "statistics": {
    "total_commits": $total_commits,
    "total_pushes": 1,
    "files_changed": ${files_changed:-0},
    "lines_added": ${lines_added:-0},
    "lines_deleted": ${lines_deleted:-0},
    "tokens_used": 0,
    "duration_seconds": $duration
  },
  "last_update": "$(date -Iseconds)",
  "heartbeat": "$(date -Iseconds)"
}
EOF
```

### 10. 记录日志

```bash
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] 煎饼: 开发完成 - ${task_id} (${total_commits} commits)" >> /shared/logs/jianbing.log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] 煎饼: Push成功 - ${target_branch}" >> /shared/logs/jianbing.log
```

---

## 重要说明

### 关于代码生成

这个技能的核心是**根据milestone.md生成代码**。实际执行时，需要：

1. **AI代码生成**：
   - 读取milestone的目标和任务
   - 理解需要实现的功能
   - 生成符合规范的代码
   - 确保代码质量

2. **示例实现**：
```javascript
// 里程碑: 实现用户注册接口
// 任务: 创建 /api/register 路由

app.post('/api/register', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // 验证输入
    if (!email || !password) {
      return res.status(400).json({ error: '邮箱和密码不能为空' });
    }
    
    // 检查邮箱是否已存在
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ error: '邮箱已被注册' });
    }
    
    // 加密密码
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // 创建用户
    const user = new User({
      email,
      password: hashedPassword
    });
    
    await user.save();
    
    res.status(201).json({ message: '注册成功' });
  } catch (error) {
    res.status(500).json({ error: '服务器错误' });
  }
});
```

3. **多文件协作**：
   - 可能需要修改多个文件
   - 遵循现有代码风格
   - 保持向后兼容

---

## 返回值

**成功：**
```json
{
  "success": true,
  "task_id": "task-001",
  "milestones_completed": 3,
  "total_commits": 3,
  "files_changed": 12,
  "pushed": true
}
```

**失败：**
```json
{
  "success": false,
  "error": "测试失败",
  "task_id": "task-001"
}
```

---

## 注意事项

1. **本地commit多个**：不要每个里程碑都push
2. **所有完成后push**：只在所有milestone完成后才push
3. **本地测试**：push前必须测试
4. **原子操作**：文件操作使用临时文件+重命名
5. **更新状态**：每个操作后都更新状态文件

---

_煎饼的技能：开发功能 🐶_
