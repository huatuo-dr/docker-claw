# Docker-Claw 配置文件清单

本文档列出所有配置文件的用途和使用方法。

---

## 📁 目录结构

```
docker-claw/
├── config/                          # Agent配置目录
│   ├── gangzi/                      # 刚子（协调者）配置
│   │   ├── SOUL.md                 # 人格和角色
│   │   ├── AGENTS.md               # 工作指南
│   │   ├── HEARTBEAT.md            # 心跳任务（10分钟）
│   │   ├── IDENTITY.md             # 基础身份
│   │   └── USER.md                 # K哥的信息
│   ├── jianbing/                    # 煎饼（开发者）配置
│   │   ├── SOUL.md                 # 人格和角色
│   │   ├── AGENTS.md               # 工作指南
│   │   ├── IDENTITY.md             # 基础身份
│   │   └── USER.md                 # K哥的信息
│   └── mozhi/                       # 墨汁儿（审查者）配置
│       ├── SOUL.md                 # 人格和角色
│       ├── AGENTS.md               # 工作指南
│       ├── IDENTITY.md             # 基础身份
│       └── USER.md                 # K哥的信息
│
├── shared/                          # 共享目录（Agent间通信）
│   ├── README.md                   # 共享目录说明
│   ├── templates/                  # 状态文件模板
│   │   ├── config.template.json
│   │   ├── summary.template.json
│   │   ├── gangzi.template.json
│   │   ├── jianbing.template.json
│   │   └── mozhi.template.json
│   ├── config.json                 # 全局配置（刚子负责）
│   ├── status/                     # 状态目录
│   │   ├── summary.json            # 任务汇总（刚子负责）
│   │   ├── gangzi.json             # 刚子的状态
│   │   ├── jianbing.json           # 煎饼的状态
│   │   └── mozhi.json              # 墨汁儿的状态
│   ├── issues/                     # Issue追踪（墨汁儿负责）
│   └── logs/                       # 日志目录
│
├── scripts/                         # 脚本目录
│   └── init-shared.sh              # 初始化共享目录
│
└── docs/                            # 文档目录
    ├── workflow.md                 # 工作流程
    └── configuration-checklist.md  # 本文件
```

---

## 🔧 刚子的配置文件

### SOUL.md - 人格和角色

**用途：** 定义刚子的人格、角色、工作方式

**关键内容：**
- 核心特质：幽默稳重、细心谨慎、善于协调
- 角色定位：协调者（Coordinator）
- 与K哥、煎饼、墨汁儿的关系
- 工作方式（启动任务、监控进度、处理归档、处理异常）
- 边界和承诺

**使用场景：**
- 刚子每次会话启动时读取
- 了解刚子的角色定位
- 理解刚子的决策逻辑

### AGENTS.md - 工作指南

**用途：** 刚子的详细工作指南

**关键内容：**
- 目录结构
- Memory系统
- 5个核心技能说明
- 通信协议
- Git操作规范
- 最佳实践

**使用场景：**
- 刚子每次会话启动时读取
- 技能实现参考
- 工作流程理解

### HEARTBEAT.md - 心跳任务

**用途：** 刚子的10分钟定时监控任务

**关键内容：**
- 执行前提检查（只在开发状态）
- 3个监控任务（煎饼、墨汁儿、Issue）
- 进度报告生成
- 异常处理（Agent离线、Issue超时）

**使用场景：**
- OpenClaw Heartbeat调用
- 刚子每10分钟执行一次
- 只在 `in_progress` 或 `reviewing` 状态执行

### IDENTITY.md - 基础身份

**用途：** 刚子的基础身份信息

**关键内容：**
- 名字、角色、Emoji
- 职责列表
- 工作方式
- 承诺和特质

**使用场景：**
- 刚子每次会话启动时读取
- 快速了解刚子身份

---

## 🐶 煎饼的配置文件

### SOUL.md - 人格和角色

**用途：** 定义煎饼的人格、角色、工作方式

**关键内容：**
- 核心特质：成熟稳重、工作认真、技术专业
- 角色定位：开发者（Developer）
- Git规范（commit message格式）
- 工作方式（开发阶段、Issue阶段、归档阶段）
- 边界和承诺

**使用场景：**
- 煎饼每次会话启动时读取
- 了解煎饼的角色定位
- 理解煎饼的Git操作规范

### AGENTS.md - 工作指南

**用途：** 煎饼的详细工作指南

**关键内容：**
- 目录结构
- Git规范（commit message、分支策略）
- 4个核心技能说明
- Cron任务（check-issues）
- 通信协议
- 最佳实践

**使用场景：**
- 煎饼每次会话启动时读取
- 技能实现参考
- Git操作规范

### IDENTITY.md - 基础身份

**用途：** 煎饼的基础身份信息

**关键内容：**
- 名字、角色、Emoji
- 职责列表
- 工作方式
- 承诺和特质

**使用场景：**
- 煎饼每次会话启动时读取
- 快速了解煎饼身份

---

## 🦊 墨汁儿的配置文件

### SOUL.md - 人格和角色

**用途：** 定义墨汁儿的人格、角色、工作方式

**关键内容：**
- 核心特质：活泼开朗、善于思考、严格把关
- 角色定位：审查者（Reviewer）
- 工作方式（测试设计、审查阶段、Issue阶段、15轮检测）
- Issue编写规范
- 边界和承诺

**使用场景：**
- 墨汁儿每次会话启动时读取
- 了解墨汁儿的角色定位
- 理解墨汁儿的Issue规范

### AGENTS.md - 工作指南

**用途：** 墨汁儿的详细工作指南

**关键内容：**
- 目录结构
- 审查标准（5个维度）
- 5个核心技能说明
- Cron任务（check-commits）
- Issue管理（生命周期、15轮检测）
- 通信协议
- 最佳实践

**使用场景：**
- 墨汁儿每次会话启动时读取
- 技能实现参考
- 审查标准参考

### IDENTITY.md - 基础身份

**用途：** 墨汁儿的基础身份信息

**关键内容：**
- 名字、角色、Emoji
- 职责列表
- 工作方式
- 承诺和特质

**使用场景：**
- 墨汁儿每次会话启动时读取
- 快速了解墨汁儿身份

---

## 📄 共享状态文件

### config.json - 全局配置

**负责Agent：** 刚子（读写）

**用途：** 存储当前任务的基本信息

**关键字段：**
- `status`: 任务状态（idle, in_progress, completed）
- `current_task`: 当前任务信息
  - `id`: 任务ID
  - `name`: 任务名称
  - `github_repo`: GitHub仓库URL
  - `target_branch`: 目标分支
  - `milestone_file`: milestone文件路径
  - `labels`: Issue标签
- `cron_jobs`: Cron任务ID
- `archive_triggered`: 归档触发标志
- `archive_approved_by`: K哥批准记录

**更新时机：**
- 刚子启动任务时
- 刚子结束任务时
- 刚子批准归档时

### status/summary.json - 任务汇总

**负责Agent：** 刚子（读写）

**用途：** 刚子用于生成进度报告

**关键字段：**
- `task_id`: 任务ID
- `status`: 任务状态
- `agents`: 三个Agent的状态
  - `gangzi`: 刚子的状态
  - `jianbing`: 煎饼的状态
  - `mozhi`: 墨汁儿的状态
- `progress`: 进度信息
  - `milestone_completed`: 已完成的里程碑数
  - `issue_comments`: Issue评论数
  - `issue_max_comments`: 最大评论数（15）

**更新时机：**
- 刚子每次Heartbeat时

### status/jianbing.json - 煎饼的状态

**负责Agent：** 煎饼（读写）

**用途：** 煎饼记录自己的工作状态

**关键字段：**
- `phase`: 当前阶段
  - `等待需求`
  - `开发需求`
  - `等待Issue`
  - `处理Issue`
  - `等待归档指令`
  - `归档中`
- `phase_detail`: 阶段详情
  - `local_commits`: 本地commit数
  - `ready_to_push`: 是否准备好push
- `current_issue`: 当前Issue
- `statistics`: 统计信息
- `heartbeat`: 心跳时间

**更新时机：**
- 煎饼阶段变化时
- 煎饼提交commit时
- 煎饼push代码时
- 煎饼处理Issue时

### status/mozhi.json - 墨汁儿的状态

**负责Agent：** 墨汁儿（读写）

**用途：** 墨汁儿记录自己的工作状态

**关键字段：**
- `phase`: 当前阶段
  - `测试设计`
  - `等待开发提交`
  - `审查中`
  - `生成审查意见`
  - `等待Issue回复`
  - `验证修复`
  - `审查成功`
  - `审查失败`
- `phase_detail`: 阶段详情
  - `target_commit`: 目标commit
  - `last_checked_commit`: 上次检查的commit
- `current_issue`: 当前Issue
- `statistics`: 统计信息
- `heartbeat`: 心跳时间

**更新时机：**
- 墨汁儿阶段变化时
- 墨汁儿审查代码时
- 墨汁儿创建Issue时
- 墨汁儿验证修复时

### issues/{number}.json - Issue追踪

**负责Agent：** 墨汁儿（读写）

**用途：** 墨汁儿记录Issue的详细信息

**关键字段：**
- `issue_number`: Issue编号
- `task_id`: 任务ID
- `bugs`: Bug列表
  - `id`: Bug ID
  - `description`: 描述
  - `severity`: 严重程度（high, medium, low）
  - `status`: 状态（pending, fixed）
- `timeline`: 时间线
- `comments_count`: 评论数
- `max_comments`: 最大评论数（15）
- `status`: Issue状态（open, closed, timeout）

**更新时机：**
- 墨汁儿创建Issue时
- 墨汁儿验证修复时
- Issue comments变化时

---

## 🚀 初始化步骤

### 1. 初始化共享目录

```bash
# 运行初始化脚本
./scripts/init-shared.sh
```

**脚本会创建：**
- `/shared/` 目录结构
- `/shared/status/` 目录
- `/shared/issues/` 目录
- `/shared/locks/` 目录
- `/shared/logs/` 目录
- 所有状态文件（从模板复制）
- 空的日志文件

### 2. 配置GitHub仓库

**编辑 `/shared/config.json`：**
```json
{
  "current_task": {
    "github_repo": "https://github.com/yourname/yourrepo",
    "main_branch": "main",
    "target_branch": "feature/task-001"
  }
}
```

### 3. 配置Agent工作目录

**刚子（宿主机）：**
```bash
# 复制配置文件到OpenClaw工作目录
cp config/gangzi/* ~/.openclaw/workspace/
```

**煎饼（容器）：**
```bash
# 复制配置文件到容器内
docker cp config/jianbing/ jianbing-container:/app/.openclaw/workspace/
```

**墨汁儿（容器）：**
```bash
# 复制配置文件到容器内
docker cp config/mozhi/ mozhi-container:/app/.openclaw/workspace/
```

### 4. 配置Cron任务

**煎饼的Cron：**
```bash
# 刚子创建任务时执行
openclaw cron add \
  --name "Jianbing Check Issues" \
  --cron "*/5 * * * *" \
  --session isolated \
  --message "检查GitHub Issues" \
  --agent jianbing \
  --enabled false
```

**墨汁儿的Cron：**
```bash
# 刚子创建任务时执行
openclaw cron add \
  --name "Mozhi Check Commits" \
  --cron "*/5 * * * *" \
  --session isolated \
  --message "检查代码提交" \
  --agent mozhi \
  --enabled false
```

---

## 📊 状态文件读写权限

| 文件 | 刚子 | 煎饼 | 墨汁儿 |
|------|------|------|--------|
| `/shared/config.json` | 读写 | 只读 | 只读 |
| `/shared/status/summary.json` | 读写 | 只读 | 只读 |
| `/shared/status/gangzi.json` | 读写 | 只读 | 只读 |
| `/shared/status/jianbing.json` | 只读 | 读写 | 只读 |
| `/shared/status/mozhi.json` | 只读 | 只读 | 读写 |
| `/shared/issues/*.json` | 只读 | 只读 | 读写 |

---

## 🔍 常见问题

### Q1: 状态文件什么时候更新？

**A:**
- **config.json**: 刚子启动/结束任务时
- **summary.json**: 刚子Heartbeat时（10分钟）
- **jianbing.json**: 煎饼阶段变化时
- **mozhi.json**: 墨汁儿阶段变化时
- **issues/*.json**: 墨汁儿Issue操作时

### Q2: 如何避免状态文件读写冲突？

**A:** 使用原子操作
```bash
# 先写临时文件，再重命名
echo "$content" > /shared/status/jianbing.json.tmp
mv /shared/status/jianbing.json.tmp /shared/status/jianbing.json
```

### Q3: 如何检测Agent离线？

**A:** 刚子的Heartbeat检查
```bash
# 检查心跳时间
heartbeat=$(cat /shared/status/jianbing.json | jq -r '.heartbeat')
age_seconds=$(( $(date +%s) - $(date -d "$heartbeat" +%s) ))

if [[ $age_seconds -gt 900 ]]; then
  # 超过15分钟，Agent离线
fi
```

### Q4: 15轮Issue如何检测？

**A:** 墨汁儿的Issue管理
```bash
# 检查Issue comments
comments=$(cat /shared/issues/123.json | jq -r '.comments_count')

if [[ $comments -ge 15 ]]; then
  # 触发超时流程
fi
```

### Q5: 归档流程如何触发？

**A:**
1. 墨汁儿审查通过 → 通知刚子
2. 刚子通知K哥 → 等待K哥指令
3. K哥批准 → 刚子更新 `config.json.archive_triggered = true`
4. 刚子通知煎饼 → 煎饼执行归档

---

## 📚 参考文档

- [共享目录说明](../shared/README.md)
- [工作流程](./workflow.md)
- [OpenClaw官方文档](https://github.com/openclaw/openclaw)

---

_本文档由刚子维护，最后更新: 2026-03-09_
