# SKILL.md - 合并到主干分支

## 触发条件

K哥确认合并后触发。

## 执行步骤

### 1. 获取分支信息

```bash
config=$(cat /shared/config.json)
branch=$(echo "$config" | jq -r '.current_task.branch')
```

### 2. 合并到 master

```bash
cd /workspace/test-task-repo

# 切换到 master 分支
git checkout master

# 获取最新代码
git fetch origin
git pull --rebase origin master

# 合并分支
git merge {branch} --no-ff -m "合并: {branch}"

# 推送到远程
git push origin master
```

### 3. 不删除开发分支（按用户要求）

```bash
# 【重要】不删除开发分支，保留供用户检查
# 如果用户需要删除，会另行通知
```

### 4. 更新状态

```bash
cat > /shared/config.json <<EOF
{
  "version": "1.0",
  "status": "completed",
  "current_task": null,
  "archive_triggered": false
}
EOF
```

### 5. 通知完成

```
✅ 合并完成！

已将 {branch} 合并到 master 分支。

开发分支已保留，您可以在需要时手动删除。

当前状态：等待新任务 📋
```

---

## 输出

- 代码已合并到 master
- 状态已更新
