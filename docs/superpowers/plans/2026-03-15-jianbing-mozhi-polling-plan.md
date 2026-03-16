# 煎饼和墨汁儿轮询 task-publish-repo 实现计划

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现煎饼和墨汁儿每分钟轮询 task-publish-repo，根据 task-config.json 中的 repo/branch 信息克隆仓库，并根据 milestone.md 中的状态各自开展工作。

**Architecture:** 煎饼和墨汁儿各自通过 Heartbeat 定时任务轮询 task-publish-repo，获取任务信息后 clone/pull 开发仓库，读取 milestone.md 中的开发/测试状态，分别执行对应操作。

**Tech Stack:** OpenClaw, Git, Docker, milestone.md

---

## Chunk 1: 更新 milestone.md 模板

### Task 1: 更新 milestone 模板

**Files:**
- Modify: `shared/templates/milestone.template.md:1-24`

- [ ] **Step 1: 备份并更新 milestone 模板**

将现有的 milestone.template.md 更新为新的格式：

```markdown
# Milestone: {version}

## 状态: {总状态}

## 任务列表 (刚子负责)
- [ ] 任务1: 描述xxx
- [ ] 任务2: 描述yyy

---

## 开发状态 (煎饼负责)
- **状态**: 待开发
- **当前分支**: {branch}
- **开发记录**:
  - [2026-03-15 10:00] 收到任务

---

## 测试状态 (墨汁儿负责)
- **状态**: 待开发
- **测试记录**:
  - [2026-03-15 10:00] 收到任务
```

- [ ] **Step 2: 提交更改**

```bash
git add shared/templates/milestone.template.md
git commit -m "docs: 更新 milestone 模板，拆分开发/测试状态"
```

---

## Chunk 2: 更新煎饼配置

### Task 2: 更新煎饼 SOUL.md

**Files:**
- Modify: `config/jianbing/SOUL.md:1-294`

- [ ] **Step 1: 更新煎饼状态定义**

在 SOUL.md 中找到"状态文件"部分，更新为：

```markdown
## 状态定义

煎饼有以下状态：
- **待开发** - 等待任务，监控中
- **开发中** - 正在开发
- **开发完成** - 待一轮测试
- **修复中** - 第N轮修复中
- **待测试** - 等待墨汁儿测试
- **可归档** - 测试通过，等待归档
```

- [ ] **Step 2: 更新工作流程部分**

更新"工作方式"部分，添加轮询逻辑说明：

```markdown
### 轮询任务阶段（Heartbeat 1分钟）

**重要：只在空闲时执行**

```
1. fetch + pull task-publish-repo (master)
2. 读取 task-config.json 获取 repo + branch
3. 如果 repo/branch 变化:
   - 删除旧仓库目录
   - clone 新仓库
   否则:
   - pull 最新代码
4. 读取 milestone.md
5. 根据开发状态执行:
   - 待开发: 开始开发 → 状态=开发中
   - 开发中: 继续开发
   - 待测试: 继续等待（不操作）
   - 修复中: 继续修复 → 状态=待测试
   - 可归档: 执行归档操作
```
```

- [ ] **Step 3: 更新边界部分**

确保边界说明包含：
- 不会擅自修改 milestone.md 中的测试状态
- 只会更新开发状态

- [ ] **Step 4: 提交更改**

```bash
git add config/jianbing/SOUL.md
git commit -m "config: 煎饼添加轮询逻辑和状态定义"
```

---

### Task 3: 更新煎饼 HEARTBEAT.md

**Files:**
- Modify: `config/jianbing/HEARTBEAT.md:1-6`

- [ ] **Step 1: 添加 Heartbeat 任务**

更新 HEARTBEAT.md 添加轮询任务：

```markdown
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
```

- [ ] **Step 2: 提交更改**

```bash
git add config/jianbing/HEARTBEAT.md
git commit -m "config: 煎饼添加 Heartbeat 轮询任务"
```

---

## Chunk 3: 更新墨汁儿配置

### Task 4: 更新墨汁儿 SOUL.md

**Files:**
- Modify: `config/mozhi/SOUL.md:1-208`

- [ ] **Step 1: 更新墨汁儿状态定义**

在 SOUL.md 中找到状态文件部分，更新为：

```markdown
## 状态定义

墨汁儿有以下状态：
- **待开发** - 等待任务，监控中
- **用例开发中** - 编写测试用例中
- **用例完成** - 等待开发完成
- **测试中** - 第N轮测试中
- **测试完成** - 第N轮测试完成，等待修复
- **测试通过** - 全部测试通过
```

- [ ] **Step 2: 更新工作流程部分**

更新"我的工作方式"部分，添加轮询逻辑：

```markdown
### 轮询任务阶段（Heartbeat 1分钟）

**重要：只在空闲时执行**

```
1. fetch + pull task-publish-repo (master)
2. 读取 task-config.json 获取 repo + branch
3. 如果 repo/branch 变化:
   - 删除旧仓库目录
   - clone 新仓库
   否则:
   - pull 最新代码
4. 读取 milestone.md
5. 根据测试状态执行:
   - 待开发: 开始编写用例 → 状态=用例开发中
   - 用例开发中: 继续编写用例 → 状态=用例完成
   - 用例完成: 等待开发完成（不操作）
   - 测试中: 继续测试 → 状态=测试完成
   - 测试完成: 等待修复（不操作）
   - 测试通过: 不操作
```
```

- [ ] **Step 3: 更新边界部分**

确保边界说明包含：
- 不会擅自修改 milestone.md 中的开发状态
- 只会更新测试状态

- [ ] **Step 4: 提交更改**

```bash
git add config/mozhi/SOUL.md
git commit -m "config: 墨汁儿添加轮询逻辑和状态定义"
```

---

### Task 5: 更新墨汁儿 HEARTBEAT.md

**Files:**
- Modify: `config/mozhi/HEARTBEAT.md:1-6`

- [ ] **Step 1: 添加 Heartbeat 任务**

更新 HEARTBEAT.md 添加轮询任务：

```markdown
# HEARTBEAT.md

# 墨汁儿 Heartbeat 任务（每1分钟执行）

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

6. **根据测试状态执行**

   - 如果状态是"待开发"：
     - 开始编写测试用例
     - 更新 milestone.md 中的测试状态为"用例开发中"
     - 添加测试记录

   - 如果状态是"用例开发中"：
     - 继续编写用例
     - 完成后更新状态为"用例完成"

   - 如果状态是"用例完成"：
     - 检查煎饼的开发状态
     - 如果煎饼状态是"开发完成"，则开始测试
     - 更新测试状态为"测试中"

   - 如果状态是"测试中"：
     - 继续测试
     - 完成后更新状态为"测试完成"

   - 如果状态是"测试完成"：
     - 检查煎饼的修复状态
     - 如果煎饼还在"修复中"，等待
     - 如果煎饼不再修复，更新为"测试通过"

   - 如果状态是"测试通过"：
     - 不操作

### 注意事项
- 每次操作前先 git pull --rebase 防冲突
- 如果遇到冲突，停止操作并通知刚子
- 更新 milestone.md 后要提交并 push
- 测试用例应该保存到 test/ 目录
```

- [ ] **Step 2: 提交更改**

```bash
git add config/mozhi/HEARTBEAT.md
git commit -m "config: 墨汁儿添加 Heartbeat 轮询任务"
```

---

## Chunk 4: 测试验证

### Task 6: 验证实现

**Files:**
- Test: 手动测试

- [ ] **Step 1: 启动容器**

```bash
docker-compose restart jianbing mozhi
```

- [ ] **Step 2: 检查容器日志**

```bash
docker logs jianbing-claw-container
docker logs mozhi-claw-container
```

- [ ] **Step 3: 手动触发 Heartbeat**

```bash
# 触发煎饼
docker exec jianbing-claw-container openclaw agent --local --agent main --message "heartbeat"

# 触发墨汁儿
docker exec mozhi-claw-container openclaw agent --local --agent main --message "heartbeat"
```

- [ ] **Step 4: 检查工作空间**

```bash
docker exec jianbing-claw-container ls -la /workspace
docker exec mozhi-claw-container ls -la /workspace
```

- [ ] **Step 5: 提交验证结果**

```bash
git add .
git commit -m "test: 验证轮询功能"
```

---

## 总结

修改的文件：
1. `shared/templates/milestone.template.md` - 更新模板格式
2. `config/jianbing/SOUL.md` - 添加状态定义和轮询说明
3. `config/jianbing/HEARTBEAT.md` - 添加轮询任务
4. `config/mozhi/SOUL.md` - 添加状态定义和轮询说明
5. `config/mozhi/HEARTBEAT.md` - 添加轮询任务
