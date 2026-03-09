---
name: review
description: 审查代码
triggers:
  - manual: true
---

# Review Skill

## 执行步骤

### 1. 读取commit内容

```bash
commit=$1
commit_diff=$(git show "$commit" --stat)
commit_files=$(git show "$commit" --name-only)
```

### 2. 读取测试计划

```bash
task_id=$(cat /shared/config.json | jq -r '.current_task.id')
test_plan=$(cat /workspace/tmp/${task_id}_test_plan.md)
```

### 3. 代码质量审查

**检查项：**
- [ ] 命名是否清晰
- [ ] 注释是否完整
- [ ] 代码结构是否合理
- [ ] 是否遵循规范

### 4. 安全审查

**检查项：**
- [ ] 是否有SQL注入风险
- [ ] 是否有XSS风险
- [ ] 密码是否加密
- [ ] 是否有权限问题

### 5. 执行测试

```bash
# 运行单元测试
npm test

# 记录结果
passed=$(npm test 2>&1 | grep "passed" | awk '{print $1}')
failed=$(npm test 2>&1 | grep "failed" | awk '{print $1}')
```

### 6. 汇总问题

```bash
bugs=()

# 示例：发现3个问题
bugs+=({
  "id": 1,
  "severity": "high",
  "location": "src/auth/login.js:45",
  "description": "密码未加密存储"
})

bugs+=({
  "id": 2,
  "severity": "medium",
  "location": "src/auth/register.js:23",
  "description": "缺少输入验证"
})

bugs+=({
  "id": 3,
  "severity": "low",
  "location": "src/auth/login.js:67",
  "description": "错误处理不完整"
})
```

### 7. 决定下一步

**如果有问题：**
```bash
# 调用create-issue技能
call_skill "create-issue" "{
  \"bugs\": $(echo "${bugs[@]}" | jq -R .)
}"
```

**如果无问题：**
```bash
# 标记为审查通过
call_skill "verify-fix" "{
  \"approved\": true
}"
```

---

_墨汁儿的技能：审查代码 🦊_
