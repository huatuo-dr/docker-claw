# Docker-Claw 项目开发工作流

本文档介绍本仓库的标准开发流程，确保项目可追溯、可维护。

---

## 工作流程概览

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  1. 创建里程碑   │ → │  2. 执行并验证   │ → │  3. 归档完成    │
│   milestones.md │    │   提交 commit   │    │  移动到编号文件  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 详细步骤

### 步骤 1: 创建里程碑文档

**位置**: 项目根目录 `milestones.md`

**内容要求**:
- 需求概述
- 任务拆分（里程碑 1、2、3...）
- 每个任务的验证方法
- 待确认事项

**示例结构**:
```markdown
# XXX 项目里程碑文档

## 项目概述
简要描述项目目标和背景

---

## 里程碑 1: XXX
**目标**: 具体目标描述

### 任务
1. 任务 A
2. 任务 B

### 验证机制
```bash
# 验证命令
command --check
```

### 产物
- 文件 1
- 文件 2

**状态**: ⬜ 待开始

---

## 里程碑 2: XXX
...
```

**交付**: 通过飞书发送给 K 哥审阅

---

### 步骤 2: 执行并验证

**流程**:
1. 根据 milestones.md 执行任务
2. 每个里程碑完成后，更新文档中的状态：
   - `⬜ 待开始` → `🔄 进行中` → `✅ 已完成`
3. 验证通过后，提交 commit：
   ```bash
   git add .
   git commit -m "M1: 描述 - 简要说明"
   ```

**Commit 规范**:
- 格式: `M[n]: [描述] - [简要说明]`
- 示例: `M1: 创建容器 - mozhi-claw-container 启动成功`

---

### 步骤 3: 归档完成

**触发条件**: milestones.md 中所有里程碑状态为 `✅ 已完成`

**操作**:
1. 确定序号（查看 milestones/ 目录下已有文件）
2. 移动并重命名文件：
   ```bash
   mv milestones.md milestones/XX-name_milestones.md
   ```
   - `XX`: 两位序号（01, 02, 03...）
   - `name`: 项目/助手名称（如 mozhi, jianbing）
3. 提交 commit：
   ```bash
   git add milestones/XX-name_milestones.md
   git commit -m "整理项目结构：将 milestones.md 移至 milestones/XX-name_milestones.md"
   ```

---

## 目录结构规范

```
docker-claw/
├── milestones/              # 已完成的里程碑文档
│   ├── 01-mozhi_milestones.md
│   ├── 02-jianbing_milestones.md
│   └── ...
├── config/                  # 配置文件
│   ├── [助手名称]/         # 各助手专属配置
│   │   ├── SOUL.md
│   │   ├── IDENTITY.md
│   │   ├── USER.md
│   │   └── AGENTS.md
│   └── ...
├── scripts/                 # 启动脚本
│   ├── start.sh
│   └── start-[助手名称].sh
├── docs/                    # 文档
│   └── workflow.md         # 本文件
├── Dockerfile              # 镜像构建
└── .gitignore
```

---

## 助手配置规范

每个 AI 助手需要以下配置文件：

| 文件 | 用途 |
|------|------|
| `SOUL.md` | 性格、价值观、行为准则 |
| `IDENTITY.md` | 基础身份信息（名字、emoji等） |
| `USER.md` | 关于 K 哥的信息 |
| `AGENTS.md` | 工作指南 |

**部署位置**:
- 本地: `config/[助手名称]/`
- 容器内: `/app/.openclaw/.openclaw/workspace/`

---

## 最佳实践

1. **先审阅后执行**: milestones.md 必须经过 K 哥审阅后再开始执行
2. **小步提交**: 每个里程碑完成后立即提交 commit，不要累积
3. **验证留痕**: 将验证命令的输出保留在 commit message 或文档中
4. **及时归档**: 项目完成后立即归档 milestones.md，保持根目录整洁
5. **复用镜像**: 多个助手可以复用同一个 Docker 镜像，只需创建不同容器

---

## 示例：创建新助手的工作流程

```bash
# 1. 创建里程碑文档（根目录）
vim milestones.md
# → 编写任务拆分和验证方法
# → 飞书通知 K 哥审阅

# 2. 审阅通过后开始执行
# M1: 创建容器
vim scripts/start-newbot.sh
./scripts/start-newbot.sh
git add scripts/start-newbot.sh
git commit -m "M1: 创建新容器 - newbot-claw-container 启动成功"

# M2: 配置身份
vim config/newbot/SOUL.md
git add config/newbot/
git commit -m "M2: 配置新助手身份 - 性格描述"

# M3: 配置模型
# 配置大模型 API
git add config/newbot/models.json
git commit -m "M3: 配置XXX模型 - API配置完成"

# M4: 对话测试
git add -A
git commit -m "M4: 对话测试通过 - 身份识别正确"

# 3. 归档
mv milestones.md milestones/03-newbot_milestones.md
git add milestones/
git commit -m "整理项目结构：将 milestones.md 移至 milestones/03-newbot_milestones.md"
```

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-03-04 | 初始版本 |

---

_本文档遵循 Docker-Claw 项目工作流规范_
