# Docker-Claw 🤖🐶🦊

> 基于 OpenClaw 的多 Agent 协作开发系统

## 📖 项目简介

Docker-Claw 是一个多 Agent 协作系统，通过三个**相互独立**的角色，实现从需求到代码交付的自动化流程。每个角色只通过 `task.json` 共享工作流事实，彼此不直接通信。

### 🎭 三个独立角色

| 角色 | 代号 | 职责 | 运行环境 |
|------|------|------|----------|
| 🤖 **观察者** | 刚子 | 观察任务进度、汇总信息、向负责人汇报 | 宿主机 |
| 🐶 **开发者** | 煎饼 | 读取需求、编写代码、修复问题、归档 | Docker 容器 |
| 🦊 **审查者** | 墨汁儿 | 代码审查、测试验证、记录审查意见 | Docker 容器 |

### ✨ 核心特性

- ✅ **Agent 独立** — 每个 Agent 独立工作，不感知其他 Agent 的存在
- ✅ **文件驱动** — 通过 `task.json` 协作，无直接通信
- ✅ **容器化部署** — 开发者和审查者运行在 Docker 容器中
- ✅ **Heartbeat 轮询** — 各 Agent 自主轮询任务状态
- ✅ **全流程自动化** — 从需求到归档的完整自动化

---

## 🚀 快速开始

### 前置要求

- [Docker](https://www.docker.com/) 20.10+
- [Git](https://git-scm.com/) 2.30+
- [Node.js](https://nodejs.org/) 22+（负责人需要）
- [OpenClaw CLI](https://github.com/openclaw/openclaw)

### 1. 克隆项目

```bash
git clone https://github.com/yourname/docker-claw.git
cd docker-claw
```

### 2. 配置环境变量

```bash
cp .env.example .env
vim .env
```

**必需配置：**
```bash
GITHUB_TOKEN=ghp_your_github_token_here
JIANBING_API_KEY=your_minimax_api_key
MOZHI_API_KEY=your_zhipu_api_key
```

### 3. 启动容器

```bash
docker-compose up -d
```

### 4. 验证

```bash
docker exec jianbing-claw-container openclaw agent --local --agent main --message "你是谁"
docker exec mozhi-claw-container openclaw agent --local --agent main --message "你是谁"
```

---

## 🔄 工作流程

```
负责人创建 task.json → 开发者开发 → 审查者测试
                                 ↕ (通过 task.json 交互)
                           审查者记录意见 → 开发者修复
                                 ↓
                           审查通过 → 开发者归档
```

### 状态流转

```
待开发 → 开发中 → 等待审查 → 修复中 → 等待审查 → 审查通过 → 归档中 → 已完成
```

### 各阶段说明

| 阶段 | 谁操作 | 做什么 |
|------|--------|--------|
| 待开发 | 负责人 | 创建 `task.json`，发布到开发仓库 |
| 开发中 | 开发者 | 读取 `task.json`，编写代码，commit + push |
| 等待审查 | 审查者 | 审查代码，在 `task.json` 中记录审查意见 |
| 修复中 | 开发者 | 根据审查意见修复，commit + push |
| 审查通过 | 审查者 | 将 `review.summary.result` 更新为 `passed` |
| 归档中 | 开发者 | 移动 `task.json` 到 `milestones/` 目录，push |

### 工作流文件

系统运行时只依赖两个文件：

1. **task-config.json** — 位于 `task-publish-repo`，用于定位仓库和分支
2. **task.json** — 位于开发仓库，记录需求、开发状态、审查意见

---

## 🏗️ 项目结构

```
docker-claw/
├── config/                          # Agent 配置目录
│   ├── jianbing/                    # 开发者配置
│   │   ├── SOUL.md                  # 人格定义
│   │   ├── AGENTS.md                # 工作指南
│   │   ├── IDENTITY.md              # 身份信息
│   │   ├── HEARTBEAT.md             # 轮询脚本
│   │   ├── USER.md                  # 用户信息
│   │   ├── scripts/                 # Python 工具脚本
│   │   │   ├── read_task_config.py  # 读取任务配置
│   │   │   └── parse_task.py        # 读写 task.json
│   │   └── skills/                  # 技能
│   │       ├── develop/             # 开发功能
│   │       └── archive/             # 归档任务
│   ├── mozhi/                       # 审查者配置
│   └── gangzi/                      # 观察者配置
│
├── shared/                          # 共享目录
│   ├── templates/                   # 模板文件
│   │   └── task.template.json       # task.json 模板
│   └── schema/
│       └── task.schema.json         # task.json schema
│
├── scripts/                         # 启动脚本
│   └── entrypoint.sh               # 容器入口脚本
│
├── Dockerfile                       # 容器镜像
├── docker-compose.yml               # 容器编排
├── .env.example                     # 环境变量模板
└── README.md
```

### 关于 task.json

`task.json` 是各角色协作的核心文件：

- **负责人**创建，定义任务和里程碑
- **开发者**读写开发状态和进度
- **审查者**读写审查状态和问题列表
- 归档后移动到 `milestones/` 目录

---

## ⚙️ 各角色配置

### 🐶 开发者（煎饼）

| 项目 | 说明 |
|------|------|
| 运行环境 | Docker 容器 |
| 模型 | MiniMax M2.5 |
| 轮询方式 | Heartbeat 轮询 task-publish-repo |
| 技能 | `develop`（开发）、`archive`（归档） |
| 脚本工具 | `read_task_config.py`、`parse_task.py` |

### 🦊 审查者（墨汁儿）

| 项目 | 说明 |
|------|------|
| 运行环境 | Docker 容器 |
| 模型 | 智谱 GLM-5 |
| 轮询方式 | Heartbeat 轮询开发仓库 |
| 职责 | 代码审查、测试验证、在 `task.json` 中记录审查意见 |

### 🤖 观察者（刚子）

| 项目 | 说明 |
|------|------|
| 运行环境 | 宿主机 |
| 职责 | 观察任务进度、汇总状态、向负责人汇报 |

---

## 🐛 故障排查

### 容器无法启动

```bash
docker logs jianbing-claw-container
docker logs mozhi-claw-container
docker exec jianbing-claw-container env | grep GITHUB
```

### Git 操作失败

```bash
ssh -T git@github.com
docker exec -it jianbing-claw-container bash
git config --list
```

---

## 🔧 常用命令

```bash
# 触发开发者
docker exec jianbing-claw-container openclaw agent --local --agent main --message "..."

# 触发审查者
docker exec mozhi-claw-container openclaw agent --local --agent main --message "..."

# 重新部署
docker rm -f jianbing-claw-container mozhi-claw-container
docker-compose up -d
```

---

## 📄 许可证

本项目采用 MIT 许可证

---

**维护者：** K哥
