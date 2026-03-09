# milestone.md 生命周期说明

本文档说明 `milestone.md` 文件在整个开发流程中的生命周期。

---

## 📍 文件位置

- **feature 分支**: `/workspace/milestone.md` （项目根目录）
- **main 分支**: 不存在 milestone.md，- **归档后**: `/workspace/milestones/001_xxx.md`

---

## 🔄 完整生命周期

### 阶段1: 创建（刚子）

**执行者**: 刚子（协调者）

**步骤:**
```bash
# 1. 切换到 main 分支
git checkout main
git pull origin main

# 2. 创建 feature 分支
git checkout -b feature/task-001

# 3. 创建 milestone.md
cat > milestone.md <<EOF
# 任务内容...
EOF

# 4. 提交到 feature 分支
git add milestone.md
git commit -m "初始化: 用户认证功能"

# 5. 推送到远程
git push -u origin feature/task-001
```

**结果:**
- ✅ feature/task-001 分支有 milestone.md
- ✅ main 分支没有 milestone.md
- ✅ 远程仓库的 feature/task-001 分支有 milestone.md

---

### 阶段2: 开发（煎饼）

**执行者**: 煎饼（开发者）

**步骤:**
```bash
# 1. 克隆仓库（如果首次）
git clone <repo-url>
cd <repo-name>

# 2. 切换到 feature 分支
git checkout feature/task-001

# 3. 拉取最新代码（获取 milestone.md）
git pull origin feature/task-001

# 4. 读取 milestone.md
cat milestone.md

# 5. 根据 milestone.md 开发
# ... 编写代码 ...

# 6. 本地 commit（多个）
git add .
git commit -m "M1: 创建用户模型"
git commit -m "M2: 实现注册接口"
git commit -m "M3: 实现登录接口"

# 7. 更新 milestone.md 状态
# 编辑 milestone.md: M1 ✅ M2 ✅ M3 ✅

# 8. Push 代码
git push origin feature/task-001
```

**结果:**
- ✅ feature 分支有更新的 milestone.md
- ✅ feature 分支有多个 commit
- ✅ main 分支仍然没有 milestone.md

---

### 阶段3: 审查（墨汁儿）

**执行者**: 墨汁儿（审查者）

**步骤:**
```bash
# 1. 拉取 feature 分支
git pull origin feature/task-001

# 2. 读取 milestone.md（了解需求）
cat milestone.md

# 3. 审查代码
# ... 执行审查 ...

# 4. 如果有问题，#    - 创建 GitHub Issue
#    - 在 Issue 下回复
```

**结果:**
- ✅ feature 分支的 milestone.md 被读取（不修改）
- ✅ GitHub 有 Issue

---

### 阶段4: 修复（煎饼）

**执行者**: 煎饼（开发者）

**步骤:**
```bash
# 1. 拉取 feature 分支
git pull origin feature/task-001

# 2. 修复 Issue 中的问题
# ... 修改代码 ...

# 3. Commit 修复
git add .
git commit -m "Fix: #123 修复问题"

# 4. Push 修复
git push origin feature/task-001

# 5. 在 Issue 下回复
gh issue comment 123 --body "已修复"
```

**结果:**
- ✅ feature 分支有新的 commit
- ✅ Issue 有新回复

---

### 阶段5: 归档（煎饼）

**执行者**: 煎饼（开发者）

**步骤:**
```bash
# 1. 归档 milestone.md
# 获取序号
next_num=$(ls milestones/ | wc -l | awk '{printf "%02d", $1+1}')

# 移动并重命名
mv milestone.md milestones/${next_num}_用户认证功能.md

# 2. 提交归档
git add milestones/
git commit -m "归档: 用户认证功能"

# 3. Push 到 feature 分支
git push origin feature/task-001

# 4. 切换到 main 分支
git checkout main
git pull origin main

# 5. 合并 feature 分支
git merge feature/task-001 --no-ff -m "合并: 用户认证功能"

# 6. Push 到 main
git push origin main

# 7. 删除 feature 分支
git branch -d feature/task-001
git push origin --delete feature/task-001
```

**结果:**
- ✅ main 分支有 `milestones/001_用户认证功能.md`
- ✅ main 分支没有 `milestone.md`
- ✅ feature 分支已删除

---

## 📊 分支状态总结

| 分支 | milestone.md | milestones/ | 说明 |
|------|--------------|------------|------|
| **main** | ❌ 不存在 | ✅ 有归档文件 | 只有归档后的文件 |
| **feature/task-001** | ✅ 存在 | ❌ 无 | 开发中的文件 |
| **归档后** | ❌ 已删除 | ✅ 在 main | feature 分支已删除 |

---

## 🔑 关键点

1. **milestone.md 只在 feature 分支中存在**
   - 刚子创建时立即提交到 feature 分支
   - main 分支永远不会有 milestone.md

2. **煎饼和墨汁儿都工作在 feature 分支**
   - 煎饼开发、提交、修复
   - 墨汁儿审查、创建 Issue
   - 都在同一个 feature 分支上协作

3. **归档时移动到 milestones/ 目录**
   - milestone.md → milestones/001_xxx.md
   - 这样 main 分支就有了历史记录

4. **避免冲突**
   - 刚子：只创建和提交 milestone.md
   - 煎饼：只修改代码和 milestone.md 状态
   - 墨汁儿：只读取 milestone.md（不修改）
   - 分工明确，避免操作冲突

---

## ⚠️ 注意事项

1. **刚子创建 milestone.md 后必须立即 commit**
   - 否则煎饼 pull 时拉不到

2. **不要在 main 分支上操作 milestone.md**
   - main 分支只接收合并
   - milestone.md 的所有操作都在 feature 分支

3. **归档时的 commit 很重要**
   - 移动 milestone.md 后要 commit
   - 这样 main 分支合并后才有归档记录

4. **feature 分支命名规范**
   - `feature/task-001`
   - `feature/task-002`
   - ...

---

_milestone.md 生命周期文档 - 由刚子维护_
