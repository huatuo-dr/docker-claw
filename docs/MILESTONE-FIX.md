# milestone.md 修改说明

## 修改时间
2026-03-09

## 修改原因
确保 milestone.md 只在 feature 分支中存在，main 分支不会有 milestone.md 文件。

---

## 修改的文件

### 1. `config/gangzi/skills/start-task/SKILL.md`

**修改位置：** 第5步"创建Git分支"

**修改前：**
```bash
# 创建feature分支
git checkout -b feature/${task_id}

# 推送到远程
git push -u origin feature/${task_id}
```

**修改后：**
```bash
# 创建feature分支
git checkout -b feature/${task_id}

# 提交 milestone.md 到 feature 分支
# 注意：milestone.md 已在第3步创建
git add milestone.md
git commit -m "初始化: ${task_name}"

# 推送到远程（milestone.md 会随分支一起推送）
git push -u origin feature/${task_id}
```

**新增说明：**
```markdown
**重要说明：**
- milestone.md 只存在于 feature 分支
- main 分支不会有 milestone.md
- 煎饼 pull feature 分支时能获取到 milestone.md
```

---

### 2. `docs/milestone-lifecycle.md`（新增）

**内容：**
- 完整的 milestone.md 生命周期说明
- 5个阶段的详细流程
- 关键点和注意事项

**作用：**
- 让开发者理解 milestone.md 的完整流程
- 明确各个阶段的职责分工
- 避免操作冲突

---

### 3. `README.md`

**修改位置：** 项目结构部分

**新增内容：**
```markdown
├── workspace/                 # Git仓库（工作空间）
│   ├── milestone.md          # 当前任务（feature分支）
│   └── milestones/           # 归档目录（main分支）
│       ├── 001_xxx.md
│       └── 002_xxx.md
```

**新增说明：**
```markdown
### 📝 关于 milestone.md

**重要说明：**
- `milestone.md` 只存在于 **feature 分支**
- `main` 分支**不会有** `milestone.md`
- 归档后会移动到 `milestones/` 目录
```

---

## 修改效果

### ✅ 达成的目标

1. **milestone.md 只在 feature 分支**
   - 刚子创建后立即 commit
   - 推送到 feature 分支
   - main 分支不会有这个文件

2. **煎饼能正常获取 milestone.md**
   - pull feature 分支时能拉到
   - 可以正常读取和更新

3. **归档流程正确**
   - milestone.md 移动到 milestones/ 目录
   - commit 后合并到 main
   - main 分支有归档记录

4. **流程清晰明了**
   - 新增生命周期文档
   - README 中有明确说明
   - 各阶段职责清晰

---

## 验证清单

### ✅ 创建任务时

- [ ] 刚子切换到 main 分支
- [ ] 刚子创建 feature 分支
- [ ] 刚子创建 milestone.md
- [ ] 刚子 **commit milestone.md**
- [ ] 刚子 push feature 分支
- [ ] feature 分支有 milestone.md
- [ ] main 分支没有 milestone.md

### ✅ 开发任务时

- [ ] 煎饼 checkout feature 分支
- [ ] 煎饼 pull 获取 milestone.md
- [ ] 煎饼能读取 milestone.md
- [ ] 煎饼开发并 commit
- [ ] feature 分支有多个 commit

### ✅ 归档任务时

- [ ] 煎饼 mv milestone.md milestones/001_xxx.md
- [ ] 煎饼 commit 归档
- [ ] 煎饼 checkout main
- [ ] 煎饼 merge feature
- [ ] main 分支有 milestones/001_xxx.md
- [ ] main 分支没有 milestone.md
- [ ] 煎饼删除 feature 分支

---

## 相关文档

- [milestone-lifecycle.md](./milestone-lifecycle.md) - 完整生命周期
- [workflow.md](./workflow.md) - 工作流程
- [configuration-checklist.md](./configuration-checklist.md) - 配置清单

---

_修改完成 - 2026-03-09_
