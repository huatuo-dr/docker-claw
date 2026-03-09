---
name: design-test
description: 设计测试计划
triggers:
  - event: new_task
---

# Design Test Skill

## 执行步骤

### 1. 读取milestone.md

```bash
config=$(cat /shared/config.json)
task_id=$(echo "$config" | jq -r '.current_task.id')
task_name=$(echo "$config" | jq -r '.current_task.name')
milestone_file=$(echo "$config" | jq -r '.current_task.milestone_file')

milestone=$(cat /workspace/$milestone_file)
```

### 2. 更新状态

```bash
cat > /shared/status/mozhi.json <<EOF
{
  "agent": "mozhi",
  "phase": "测试设计",
  "current_task": {
    "id": "$task_id",
    "test_plan": "tmp/${task_id}_test_plan.md"
  },
  "phase_detail": {
    "started_at": "$(date -Iseconds)"
  },
  "current_issue": null,
  "statistics": {
    "test_cases": 0,
    "passed": 0,
    "failed": 0,
    "review_rounds": 0,
    "tokens_used": 0,
    "duration_seconds": 0
  },
  "last_update": "$(date -Iseconds)",
  "heartbeat": "$(date -Iseconds)"
}
EOF
```

### 3. 分析需求

**提取关键功能：**
- 功能1: 用户注册
- 功能2: 用户登录
- 功能3: 密码加密

### 4. 设计测试用例

**正常流程：**
```markdown
### 正常流程测试

1. 注册成功
   - 输入: email=test@example.com, password=Test123!
   - 预期: 返回201，用户创建成功

2. 登录成功
   - 输入: email=test@example.com, password=Test123!
   - 预期: 返回200，JWT token
```

**异常流程：**
```markdown
### 异常流程测试

1. 重复注册
   - 输入: 已存在的email
   - 预期: 返回409，邮箱已被注册

2. 登录失败（错误密码）
   - 输入: email=test@example.com, password=wrong
   - 预期: 返回401，密码错误
```

**边界情况：**
```markdown
### 边界情况测试

1. 空邮箱
   - 输入: email="", password=Test123!
   - 预期: 返回400，邮箱不能为空

2. 密码强度不足
   - 输入: email=test@example.com, password=123
   - 预期: 返回400，密码强度不足
```

**安全测试：**
```markdown
### 安全测试

1. SQL注入
   - 输入: email="'; DROP TABLE users;--"
   - 预期: 返回400，输入被拒绝

2. XSS攻击
   - 输入: email="<script>alert('xss')</script>"
   - 预期: 返回400，输入被拒绝

3. 密码明文存储
   - 检查: 数据库中的密码是否加密
   - 预期: 密码使用bcrypt加密
```

### 5. 生成测试文档

```bash
cat > /workspace/tmp/${task_id}_test_plan.md <<EOF
# ${task_name} - 测试计划

## 测试范围

本次测试覆盖用户认证功能，包括：
- 用户注册
- 用户登录
- 密码加密

---

## 正常流程测试 (10个用例)

### 1. 注册成功
**步骤:**
1. 发送POST /api/register
2. Body: {email, password}
3. 检查响应

**预期结果:**
- 状态码: 201
- 响应: {message: "注册成功"}

---

## 异常流程测试 (5个用例)

### 1. 重复注册
...

---

## 边界情况测试 (3个用例)

### 1. 空邮箱
...

---

## 安全测试 (3个用例)

### 1. SQL注入
...

---

**文档版本**: v1.0  
**创建时间**: $(date '+%Y-%m-%d %H:%M:%S')  
**创建者**: 墨汁儿 🦊
EOF
```

### 6. 更新状态

```bash
cat /shared/status/mozhi.json | jq "
  .phase = \"等待开发提交\" |
  .statistics.test_cases = 21 |
  .last_update = \"$(date -Iseconds)\"
" > /shared/status/mozhi.json.tmp

mv /shared/status/mozhi.json.tmp /shared/status/mozhi.json
```

---

_墨汁儿的技能：设计测试 🦊_
