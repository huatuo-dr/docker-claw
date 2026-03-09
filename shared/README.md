# Shared 目录说明

本目录用于三个 AI 助手（刚子、煎饼、墨汁儿）之间的状态共享和通信。

---

## 目录结构

```
shared/
├── config.json              # 全局配置（当前任务、Git信息等）
├── status/                  # Agent状态目录
│   ├── summary.json         # 任务汇总状态
│   ├── gangzi.json          # 刚子的状态
│   ├── jianbing.json        # 煎饼的状态
│   └── mozhi.json           # 墨汁儿的状态
├── issues/                  # Issue追踪目录
│   ├── 123.json             # Issue #123 的详细信息
│   ├── 124.json             # Issue #124 的详细信息
│   └── 123_failed.json      # Issue #123 失败报告（如果15轮未解决）
├── locks/                   # 锁文件目录（防止并发冲突）
│   ├── jianbing.lock        # 煎饼操作锁
│   └── mozhi.lock           # 墨汁儿操作锁
└── logs/                    # 日志目录
    ├── gangzi.log           # 刚子的日志
    ├── jianbing.log         # 煎饼的日志
    └── mozhi.log            # 墨汁儿的日志
```

---

## 文件说明

### 1. config.json - 全局配置

**用途：** 存储当前任务的基本信息

**读写权限：**
- 刚子：读写
- 煎饼：只读
- 墨汁儿：只读

**更新时机：**
- 刚子启动任务时
- 刚子结束任务时
- 刚子批准归档时

**示例：**
```json
{
  "version": "1.0",
  "status": "in_progress",
  "current_task": {
    "id": "task-001",
    "name": "用户认证功能",
    "github_repo": "https://github.com/yourname/yourrepo",
    "main_branch": "main",
    "target_branch": "feature/task-001",
    "milestone_file": "milestone.md",
    "labels": ["task-001", "review"],
    "started_at": "2026-03-09T09:00:00Z",
    "created_by": "gangzi"
  },
  "cron_jobs": {
    "jianbing": "job-jianbing-001",
    "mozhi": "job-mozhi-001"
  },
  "archive_triggered": false,
  "archive_approved_by": null,
  "archive_approved_at": null
}
```

---

### 2. status/summary.json - 任务汇总状态

**用途：** 刚子用于生成进度报告

**读写权限：**
- 刚子：读写
- 煎饼：只读
- 墨汁儿：只读

**更新时机：**
- 刚子每次Heartbeat时
- Agent状态变化时

**示例：**
```json
{
  "task_id": "task-001",
  "task_name": "用户认证功能",
  "status": "in_progress",
  "started_at": "2026-03-09T09:00:00Z",
  "elapsed_seconds": 7200,
  "agents": {
    "gangzi": {
      "phase": "监控中",
      "health": "ok",
      "last_heartbeat": "2026-03-09T11:05:00Z"
    },
    "jianbing": {
      "phase": "等待Issue",
      "health": "ok",
      "last_heartbeat": "2026-03-09T11:08:00Z"
    },
    "mozhi": {
      "phase": "审查中",
      "health": "ok",
      "last_heartbeat": "2026-03-09T11:10:00Z"
    }
  },
  "progress": {
    "milestone_completed": 3,
    "milestone_total": 5,
    "issue_number": 123,
    "issue_url": "https://github.com/.../issues/123",
    "issue_comments": 4,
    "issue_max_comments": 15,
    "issue_warning_threshold": 12
  },
  "next_notification": "2026-03-09T11:20:00Z",
  "last_notification": "2026-03-09T11:10:00Z"
}
```

---

### 3. status/jianbing.json - 煎饼的状态

**用途：** 煎饼记录自己的工作状态，刚子读取用于监控

**读写权限：**
- 煎饼：读写
- 刚子：只读
- 墨汁儿：只读

**更新时机：**
- 煎饼阶段变化时
- 煎饼提交commit时
- 煎饼push代码时
- 煎饼处理Issue时

**阶段列表：**
1. `等待需求` - 空闲状态
2. `开发需求` - 正在开发
3. `等待Issue` - 已push，等待墨汁儿审查
4. `处理Issue` - 正在处理Issue
5. `等待归档指令` - 审查通过，等待刚子通知
6. `归档中` - 正在归档

---

### 4. status/mozhi.json - 墨汁儿的状态

**用途：** 墨汁儿记录自己的工作状态，刚子读取用于监控

**读写权限：**
- 墨汁儿：读写
- 刚子：只读
- 煎饼：只读

**更新时机：**
- 墨汁儿阶段变化时
- 墨汁儿审查代码时
- 墨汁儿创建Issue时
- 墨汁儿验证修复时

**阶段列表：**
1. `测试设计` - 设计测试计划
2. `等待开发提交` - 等待煎饼push
3. `审查中` - 正在审查代码
4. `生成审查意见` - 正在整理问题
5. `等待Issue回复` - 等待煎饼回复
6. `验证修复` - 验证煎饼的修复
7. `审查成功` - 审查通过
8. `审查失败` - 15轮未解决

---

### 5. issues/{number}.json - Issue追踪文件

**用途：** 墨汁儿记录Issue的详细信息

**读写权限：**
- 墨汁儿：读写
- 刚子：只读（用于异常处理）
- 煎饼：只读（用于查看问题）

**更新时机：**
- 墨汁儿创建Issue时
- 墨汁儿验证修复时
- Issue comments变化时

**内容包含：**
- Issue基本信息
- Bug列表及状态
- 时间线
- Comments计数

---

### 6. locks/{agent}.lock - 操作锁

**用途：** 防止Git操作冲突

**使用方式：**
```bash
# 煎饼操作前
if [ ! -f /shared/locks/jianbing.lock ]; then
  touch /shared/locks/jianbing.lock
  
  # 执行Git操作
  git pull
  git commit
  git push
  
  # 释放锁
  rm /shared/locks/jianbing.lock
fi
```

---

## 通信协议

### 1. 刚子 → 煎饼/墨汁儿

**方式：** 通过 config.json 和各自的状态文件

**流程：**
```
刚子更新 config.json → 煎饼/墨汁儿Cron检测到变化 → 执行相应操作
```

### 2. 煎饼/墨汁儿 → 刚子

**方式：** 通过各自的状态文件

**流程：**
```
煎饼/墨汁儿更新状态文件 → 刚子Heartbeat读取 → 生成报告
```

### 3. 煎饼 ↔ 墨汁儿

**方式：** 通过 GitHub Issues

**流程：**
```
墨汁儿创建Issue → 煎饼处理Issue → GitHub Issue评论 → 墨汁儿验证
```

---

## 异常处理

### 1. Agent离线检测

**判定标准：** Heartbeat超过15分钟未更新

**处理流程：**
```
刚子检测到Agent离线 → 通知K哥 → 等待K哥指令
```

### 2. Issue超时

**判定标准：** Issue comments ≥ 15

**处理流程：**
```
墨汁儿检测到超时 → 生成失败报告 → 通知刚子 → 刚子通知K哥
```

### 3. Git冲突

**判定标准：** Git操作返回冲突错误

**处理流程：**
```
煎饼/墨汁儿检测到冲突 → 通知刚子 → 刚子通知K哥 → K哥手动解决
```

---

## 最佳实践

### 1. 文件读写

**原子操作：**
```bash
# 写入临时文件，然后重命名
echo "$content" > /shared/status/jianbing.json.tmp
mv /shared/status/jianbing.json.tmp /shared/status/jianbing.json
```

### 2. 锁机制

**超时释放：**
```bash
# 如果锁超过5分钟，强制释放
if [ -f /shared/locks/jianbing.lock ]; then
  lock_age=$(($(date +%s) - $(date -r /shared/locks/jianbing.lock +%s)))
  if [ $lock_age -gt 300 ]; then
    rm /shared/locks/jianbing.lock
  fi
fi
```

### 3. 日志记录

**格式：**
```
[2026-03-09 11:00:00] [INFO] 煎饼: 开始开发需求
[2026-03-09 11:05:00] [INFO] 煎饼: 提交commit - M1: 创建用户模型
[2026-03-09 11:10:00] [WARN] 墨汁儿: Issue #123 comments已达 12/15
```

---

## 初始化

运行初始化脚本创建目录和默认文件：

```bash
./scripts/init-shared.sh
```

---

_本目录是三个AI助手协作的核心基础设施_
