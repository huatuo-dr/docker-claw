---
name: handle-issue
description: 处理GitHub Issue，修复bug
triggers:
  - manual: true
---

# Handle Issue Skill

## 执行步骤

### 1. 读取Issue内容

```bash
issue_number=$1
github_repo=$(cat /shared/config.json | jq -r '.current_task.github_repo')

# 获取Issue详情
issue=$(gh issue view "$issue_number" --repo "$github_repo" --json title,body,comments)

# 提取问题列表
bugs=$(echo "$issue" | jq -r '.body')
```

### 2. 分析问题

**解析Issue中的Bug列表：**
- Bug 1: 密码未加密存储
- Bug 2: 缺少输入验证
- Bug 3: 错误处理不完整

### 3. 修复问题

**逐个修复：**

```bash
# Bug 1: 修复密码加密
vim src/auth/login.js
# ... 修改代码 ...

git add src/auth/login.js
git commit -m "Fix: #$issue_number 修复密码加密问题"

# Bug 2: 添加输入验证
vim src/middleware/validate.js
# ... 修改代码 ...

git add src/middleware/validate.js
git commit -m "Fix: #$issue_number 添加输入验证"

# Bug 3: 完善错误处理
vim src/utils/error.js
# ... 修改代码 ...

git add src/utils/error.js
git commit -m "Fix: #$issue_number 完善错误处理"
```

### 4. 本地测试

```bash
# 运行测试
npm test

if [[ $? -ne 0 ]]; then
  echo "测试失败，继续修复"
  # 继续修复或通知刚子
fi
```

### 5. Push代码

```bash
target_branch=$(cat /shared/config.json | jq -r '.current_task.target_branch')

git push origin "$target_branch"
```

### 6. 回复Issue

```bash
# 生成回复
reply="已修复所有问题:
- Bug 1: ✅ 使用bcrypt加密
- Bug 2: ✅ 添加验证中间件  
- Bug 3: ✅ 统一错误处理

请审查"

# 提交评论
gh issue comment "$issue_number" --repo "$github_repo" --body "$reply"
```

### 7. 更新状态

```bash
# 更新状态文件
cat /shared/status/jianbing.json | jq "
  .phase = \"等待Issue\" |
  .phase_detail.local_commits = 0 |
  .last_update = \"$(date -Iseconds)\"
" > /shared/status/jianbing.json.tmp

mv /shared/status/jianbing.json.tmp /shared/status/jianbing.json
```

---

_煎饼的技能：处理Issue 🐶_
