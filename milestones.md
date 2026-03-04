# Docker-Claw 项目里程碑文档

## 项目概述
在 Docker 容器中部署 OpenClaw，创建名为「墨汁儿」的 AI 助手实例，配置智谱 GLM 大模型，并验证对话功能。

---

## 里程碑 1: 项目初始化
**目标**: 初始化 Git 仓库并建立项目结构

### 任务
1. 初始化 Git 仓库
2. 创建 .gitignore 文件
3. 创建项目基础目录结构

### 验证机制
```bash
git status                    # 应显示干净的仓库
git log --oneline             # 应显示初始化 commit
tree -L 2                     # 应显示完整目录结构
```

### 产物
- Git 仓库已初始化
- .gitignore 文件
- 目录结构: docker-claw/{Dockerfile,config/,scripts/,docs/}

**状态**: ⬜ 待开始

---

## 里程碑 2: 创建 Dockerfile
**目标**: 构建基于 Ubuntu 24.04 的 OpenClaw Docker 镜像

### 任务
1. 编写 Dockerfile (Ubuntu 24.04 基础)
2. 安装 Node.js (v22+)
3. 安装 OpenClaw CLI
4. 配置容器启动脚本

### Dockerfile 设计要点
```dockerfile
FROM ubuntu:24.04

# 安装依赖: curl, git, nodejs, npm
# 安装 OpenClaw CLI (npm install -g openclaw)
# 创建工作目录 /app
# 暴露必要端口
# 设置启动命令
```

### 验证机制
```bash
docker build -t docker-claw:m1 .
docker images | grep docker-claw    # 应显示镜像
docker run --rm docker-claw:m1 openclaw --version  # 应输出版本号
```

### 产物
- Dockerfile
- 可运行的 docker-claw:m1 镜像

**状态**: ⬜ 待开始

---

## 里程碑 3: 容器运行与基础配置
**目标**: 启动容器并完成 OpenClaw 基础配置

### 任务
1. 创建 OpenClaw 配置文件模板
2. 创建容器启动脚本
3. 启动容器并挂载配置目录
4. 初始化 OpenClaw 基础配置

### 验证机制
```bash
# 容器运行状态
docker ps | grep docker-claw

# 容器内 OpenClaw 状态
docker exec docker-claw-container openclaw status

# 配置文件存在
docker exec docker-claw-container ls -la /app/.openclaw/
```

### 产物
- scripts/start.sh (容器启动脚本)
- config/ 目录模板
- 运行中的容器 docker-claw-container

**状态**: ⬜ 待开始

---

## 里程碑 4: 配置 AI 助手「墨汁儿」
**目标**: 创建名为「墨汁儿」的助手身份

### 任务
1. 创建 SOUL.md 定义「墨汁儿」的性格
2. 创建 IDENTITY.md 定义基础信息
3. 创建 USER.md 定义与你的关系
4. 准备 AGENTS.md 工作指南

### 「墨汁儿」人设
- **名字**: 墨汁儿
- **性格**: 活泼开朗、善于思考
- **称呼你**: K哥
- **Emoji**: 🦊

### 验证机制
```bash
# 配置文件完整
docker exec docker-claw-container cat /app/.openclaw/SOUL.md
docker exec docker-claw-container cat /app/.openclaw/IDENTITY.md
docker exec docker-claw-container cat /app/.openclaw/USER.md
```

### 产物
- config/SOUL.md
- config/IDENTITY.md
- config/USER.md
- config/AGENTS.md

**状态**: ⬜ 待开始

---

## 里程碑 5: 配置智谱 GLM 大模型
**目标**: 集成智谱 AI GLM 模型

### 任务
1. 配置智谱 API 密钥 (需要 K 哥提供)
2. 在 OpenClaw 中添加 GLM 模型配置
3. 设置 GLM 为默认模型
4. 验证模型连通性

### 配置项
```yaml
# 需要配置的模型
provider: zhipu
model: glm-4
api_key: <需要 K 哥提供>
```

### 验证机制
```bash
# 模型配置检查
docker exec docker-claw-container openclaw models list

# 简单调用测试
docker exec docker-claw-container openclaw chat --model glm-4 "test"
```

### 可能需要 K 哥操作
- [ ] 提供智谱 AI API Key
- [ ] 确认模型选择 (GLM-4 / GLM-4-Plus / 其他)

### 产物
- 配置完成的 GLM 模型
- 验证通过的连通性测试

**状态**: ⬜ 待开始

---

## 里程碑 6: 对话测试
**目标**: 验证「墨汁儿」可以正常对话

### 任务
1. 发送测试消息：「你好，你叫什么名字」
2. 捕获回复内容
3. 验证回复合理性
4. 通过飞书发送回复给 K 哥

### 验证机制
```bash
# 对话测试
docker exec mozhi-claw-container openclaw chat "你好，你叫什么名字"

# 检查响应不为空
# 检查响应包含合理内容
```

### 故障处理
- 如果无回复 → 检查模型配置
- 如果报错 → 查看日志
- 如果回复异常 → 检查人设文件

### 产物
- 对话测试记录
- 墨汁儿的回复（通过飞书发送）

**状态**: ⬜ 待开始

---

## 项目完成清单

- [ ] Git 仓库初始化
- [ ] Dockerfile 创建并构建成功
- [ ] 容器正常运行 (mozhi-claw-container)
- [ ] 「墨汁儿」人设配置完成
- [ ] 智谱 GLM 模型配置完成
- [ ] 对话测试通过
- [ ] 最终 Commit 提交

---

## 备注

### 待 K 哥确认的事项
1. **智谱 API Key**: 需要在里程碑 5 时提供
2. **GLM 模型版本**: GLM-4 / GLM-4-Plus / GLM-4-Flash 等
3. **墨汁儿人设**: 是否需要调整性格描述

### 风险与应对
| 风险 | 应对策略 |
|------|----------|
| Docker 构建失败 | 检查基础镜像和依赖版本 |
| 模型 API 不通 | 验证 Key 和网络，尝试备用模型 |
| 容器无法启动 | 检查端口冲突和权限设置 |
| OpenClaw 配置错误 | 逐步验证配置文件格式 |

---

**文档版本**: v1.0  
**创建时间**: 2026-03-04  
**作者**: 刚子 (Gang Zi) 🤖
