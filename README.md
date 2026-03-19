# Docker-Claw 🤖🐶🦊

> 基于 OpenClaw 的多 Agent 协作开发系统

## 📖 项目简介

Docker-Claw 是一个多 Agent 协作系统，通过三个**相互独立**的 AI 角色，实现从需求到代码交付的自动化流程。每个 Agent 只通过文件（`milestone.md` 和状态文件）暴露信息，彼此不感知对方的存在。

### 🎭 三个独立角色

| 角色 | 代号 | 职责 | 运行环境 |
|------|------|------|----------|
| 🤖 **负责人** | 刚子 | 任务调度、状态监控、分支合并 | 宿主机 |
| 🐶 **开发者** | 煎饼 | 读取需求、编写代码、修复问题、归档 | Docker 容器 |
| 🦊 **审查员** | 墨汁儿 | 代码审查、测试验证、记录审查意见 | Docker 容器 |

### ✨ 核心特性

- ✅ **Agent 独立** — 每个 Agent 独立工作，不感知其他 Agent 的存在
- ✅ **文件驱动** — 通过 `milestone.md` 和状态文件协作，无直接通信
- ✅ **容器化部署** — 开发者和审查员运行在 Docker 容器中
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
用户提需求 → 负责人创建 milestone.md → 开发者开发 → 审查员测试
                                          ↕ (通过 milestone.md 交互)
                                    审查员记录意见 → 开发者修复
                                          ↓
                                    审查通过 → 开发者归档 → 负责人合并分支
```

### 状态流转

```
待开发 → 开发中 → 等待第1轮测试 → 第1轮测试修复中 → 等待第2轮测试 → ... → 可归档 → 执行归档 → 等待任务
```

### 各阶段说明

| 阶段 | 谁操作 | 做什么 |
|------|--------|--------|
| 待开发 | 负责人 | 创建 milestone.md，发布到 task-publish-repo |
| 开发中 | 开发者 | 读取 milestone.md，编写代码，commit + push |
| 等待第N轮测试 | 审查员 | 审查代码，在 milestone.md 中记录审查意见 |
| 第N轮测试修复中 | 开发者 | 根据审查意见修复，commit + push |
| 可归档 | 审查员 | 标记测试通过，将状态改为"可归档" |
| 执行归档 | 开发者 | 移动 milestone.md 到 milestones/ 目录，push |
| 分支合并 | 负责人 | 合并开发分支到 main |

### 信息暴露方式

每个 Agent 对外只有两个信息途径：

1. **milestone.md** — 在开发仓库中，记录需求、开发状态、审查意见
2. **状态文件** — `/shared/{repo}/{branch}/xxx-status.json`，记录 Agent 当前阶段

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
│   │   │   ├── write_status.py      # 写状态文件
│   │   │   └── parse_milestone.py   # 解析 milestone
│   │   └── skills/                  # 技能
│   │       ├── develop/             # 开发功能
│   │       └── archive/             # 归档任务
│   ├── mozhi/                       # 审查员配置
│   └── gangzi/                      # 负责人配置
│
├── shared/                          # 共享目录
│   ├── {repo}/{branch}/             # 按仓库/分支组织的状态目录
│   │   ├── jianbing-status.json     # 开发者状态
│   │   └── mozhi-status.json        # 审查员状态
│   └── templates/                   # 模板文件
│       ├── milestone.template.md    # milestone 模板
│       └── jianbing.template.json   # 状态文件模板
│
├── scripts/                         # 启动脚本
│   └── entrypoint.sh               # 容器入口脚本
│
├── Dockerfile                       # 容器镜像
├── docker-compose.yml               # 容器编排
├── .env.example                     # 环境变量模板
└── README.md
```

### 关于 milestone.md

`milestone.md` 是各角色协作的核心文件：

- **负责人**创建，定义任务列表
- **开发者**读写开发状态和进度
- **审查员**读写测试状态和审查意见
- 归档后移动到 `milestones/` 目录

模板中使用角色名（负责人/开发者/审查员），不使用具体 Agent 名称。

---

## ⚙️ 各角色配置

### 🐶 开发者（煎饼）

| 项目 | 说明 |
|------|------|
| 运行环境 | Docker 容器 |
| 模型 | MiniMax M2.5 |
| 轮询方式 | Heartbeat 轮询 task-publish-repo |
| 技能 | `develop`（开发）、`archive`（归档） |
| 状态文件 | `/shared/{repo}/{branch}/jianbing-status.json` |
| 脚本工具 | `read_task_config.py`、`write_status.py`、`parse_milestone.py` |

### 🦊 审查员（墨汁儿）

| 项目 | 说明 |
|------|------|
| 运行环境 | Docker 容器 |
| 模型 | 智谱 GLM-5 |
| 轮询方式 | Heartbeat 轮询开发仓库 |
| 职责 | 代码审查、测试验证、在 milestone.md 中记录审查意见 |

### 🤖 负责人（刚子）

| 项目 | 说明 |
|------|------|
| 运行环境 | 宿主机 |
| 职责 | 任务创建、状态监控、分支合并 |

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

# 触发审查员
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
