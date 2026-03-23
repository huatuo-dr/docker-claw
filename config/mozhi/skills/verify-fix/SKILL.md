---
name: verify-fix
description: 验证修复并更新task.json中的审查结果
triggers:
  - manual: true
---

# Verify Fix Skill

## 执行步骤

### 1. 拉取最新代码

```bash
eval $(python3 /scripts/read_task_config.py)
cd "/workspace/$REPO_NAME"
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"
```

### 2. 重新执行 review

```bash
call_skill "review"
```

---

_墨汁儿的技能：验证修复 🦊_
