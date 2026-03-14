# SKILL.md - 执行归档

## 触发条件

K哥确认可以归档后触发。

## 执行步骤

### 1. 获取归档信息

```bash
# 从 config.json 获取任务信息
config=$(cat /shared/config.json)
branch=$(echo "$config" | jq -r '.current_task.branch')
milestone_version=$(echo "$config" | jq -r '.current_task.milestone_version')
```

### 2. 创建归档文件

```bash
cd /workspace/test-task-repo

# 获取序号
next_num=$(ls milestones/ | wc -l | awk '{printf "%02d", $1+1}')

# 移动 milestone.md 到 milestones/ 目录
mkdir -p milestones
mv milestone.md milestones/${next_num}_${milestone_version}.md
```

### 3. 删除原有的 milestone.md

```bash
# milestone.md 已移动，目录中不再有此文件
```

### 4. 自动提交（防冲突）

```bash
# 设置Git用户信息
git config user.name "刚子"
git config user.email "gangzi@docker-claw.local"

# 获取最新代码（防冲突）
git fetch origin
git pull --rebase origin {branch}

# 如果有冲突:
# - 停止提交
# - 报告错误给K哥

# 提交变更
git add .
git commit -m "刚子: 归档 milestone"

# 推送到远程
git push origin {branch}
```

### 5. 询问K哥是否合并

```
归档完成！

已完成：
- ✅ milestone.md 已归档到 milestones/${next_num}_${milestone_version}.md
- ✅ 代码已提交到 {branch} 分支

现在需要您确认：
是否将 {branch} 合并到 master 分支？

回复"合并"或"不合并"
```

---

## 输出

- milestone.md 已归档
- 代码已提交到开发分支
- 等待K哥确认是否合并
