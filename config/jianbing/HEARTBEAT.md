# HEARTBEAT.md

# 煎饼 Heartbeat 任务（每1分钟执行）

## 任务：轮询 task-publish-repo

### 执行条件
- 只在 agent 空闲时执行

### 步骤

1. **准备工作目录**
   ```bash
   cd /workspace
   ```

2. **克隆/更新 task-publish-repo**
   ```bash
   # 如果不存在则 clone
   if [ ! -d "task-publish-repo" ]; then
     git clone https://github.com/huatuo-dr/task-publish-repo.git
   fi

   # 进入目录并拉取最新
   cd task-publish-repo
   git fetch origin
   git checkout master
   git pull origin master
   ```

3. **读取任务配置**
   ```bash
   cat task-config.json
   ```

   获取 `repo` 和 `branch` 字段。

4. **克隆/更新开发仓库**
   ```bash
   cd /workspace

   # 从 repo URL 提取仓库名
   REPO_NAME=$(basename $REPO .git)  # 如 test-task-repo

   if [ ! -d "$REPO_NAME" ]; then
     git clone $REPO $REPO_NAME
   fi

   cd $REPO_NAME
   git fetch origin
   git checkout $BRANCH
   git pull origin $BRANCH
   ```

5. **读取 milestone.md**
   ```bash
   cat milestone.md
   ```

6. **根据开发状态执行**

   - 如果状态是"待开发"：
     - 开始开发
     - 更新 milestone.md 中的开发状态为"开发中"
     - 添加开发记录

   - 如果状态是"开发中"：
     - 继续开发（不更新状态）

   - 如果状态是"开发完成"：
     - 继续等待墨汁儿测试（不操作）

   - 如果状态是"修复中"：
     - 继续修复
     - 修复完成后更新状态为"待测试"

   - 如果状态是"可归档"：
     - 执行归档操作

### 注意事项
- 每次操作前先 git pull --rebase 防冲突
- 如果遇到冲突，停止操作并通知刚子
- 更新 milestone.md 后要提交并 push
