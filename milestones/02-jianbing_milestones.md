# 煎饼 Claw 项目里程碑文档

## 项目概述
复用 mozhi-claw:m2 镜像，创建名为「煎饼」的 AI 助手实例，配置 MiniMax 大模型，并验证对话功能。

---

## 里程碑 1: 项目初始化与容器创建
**目标**: 初始化项目结构并创建煎饼容器

### 任务
1. 创建煎饼配置目录
2. 使用 mozhi-claw:m2 镜像启动容器 jianbing-claw-container
3. 验证容器运行状态

### 验证机制
```bash
docker ps | grep jianbing-claw-container    # 应显示容器运行中
docker exec jianbing-claw-container openclaw --version  # 应输出版本号
```

### 产物
- 容器 jianbing-claw-container (运行中)
- 配置目录: docker-claw/config/jianbing/

**状态**: ⬜ 待开始

---

## 里程碑 2: 创建「煎饼」AI 助手身份
**目标**: 创建名为「煎饼」的助手身份

### 任务
1. 创建 SOUL.md 定义「煎饼」的性格
2. 创建 IDENTITY.md 定义基础信息
3. 创建 USER.md 定义与 K 哥的关系
4. 准备 AGENTS.md 工作指南

### 「煎饼」人设
- **名字**: 煎饼
- **性格**: 成熟稳重、工作认真
- **称呼你**: K 哥
- **Emoji**: 🐶

### 验证机制
```bash
docker exec jianbing-claw-container cat /app/.openclaw/.openclaw/workspace/SOUL.md
docker exec jianbing-claw-container cat /app/.openclaw/.openclaw/workspace/IDENTITY.md
docker exec jianbing-claw-container cat /app/.openclaw/.openclaw/workspace/USER.md
```

### 产物
- config/jianbing/SOUL.md
- config/jianbing/IDENTITY.md
- config/jianbing/USER.md
- config/jianbing/AGENTS.md

**状态**: ⬜ 待开始

---

## 里程碑 3: 配置 MiniMax 大模型
**目标**: 集成 MiniMax AI 模型

### 任务
1. 配置 MiniMax API 密钥 (需要 K 哥提供)
2. 在 OpenClaw 中添加 MiniMax 模型配置
3. 设置 MiniMax 为默认模型
4. 验证模型连通性

### 配置项
```yaml
# 需要配置的模型
provider: minimax
model: minimax-text-01  # 或其他可用模型
api_key: <需要 K 哥提供>
baseUrl: https://api.minimax.chat/v1
```

### 验证机制
```bash
# 模型配置检查
docker exec jianbing-claw-container openclaw models status

# API 连通性测试 (curl)
curl -s https://api.minimax.chat/v1/chat/completions \
  -H "Authorization: Bearer <api_key>" \
  -H "Content-Type: application/json" \
  -d '{"model":"minimax-text-01","messages":[{"role":"user","content":"你好"}]}'
```

### 可能需要 K 哥操作
- [ ] 提供 MiniMax API Key
- [ ] 确认具体模型版本

### 产物
- 配置完成的 MiniMax 模型
- 验证通过的连通性测试

**状态**: ⬜ 待开始

---

## 里程碑 4: 对话测试
**目标**: 验证「煎饼」可以正常对话

### 任务
1. 发送测试消息：「你好，你叫什么名字」
2. 捕获回复内容
3. 验证回复合理性（应体现成熟稳重的性格）
4. 通过飞书发送回复给 K 哥

### 验证机制
```bash
# 对话测试
docker exec jianbing-claw-container openclaw agent --local --agent main \
  -m "你好，你叫什么名字" --timeout 60

# 检查响应：
# - 应回答"我是煎饼"
# - 应使用🐶 emoji
# - 应称呼"K哥"
# - 语气应成熟稳重
```

### 故障处理
- 如果无回复 → 检查模型配置
- 如果报错 → 查看日志
- 如果回复异常 → 检查人设文件

### 产物
- 对话测试记录
- 煎饼的回复（通过飞书发送）

**状态**: ⬜ 待开始

---

## 项目完成清单

- [ ] 容器 jianbing-claw-container 运行正常
- [ ] 「煎饼」人设配置完成（成熟稳重🐶）
- [ ] MiniMax 模型配置完成
- [ ] 对话测试通过（能正确回答身份）
- [ ] 最终 Commit 提交

---

## 备注

### 待 K 哥确认的事项
1. **MiniMax API Key**: 需要在里程碑 3 时提供
2. **MiniMax 模型版本**: 
   - minimax-text-01
   - abab6.5s-chat
   - 或其他

### 风险与应对
| 风险 | 应对策略 |
|------|----------|
| MiniMax API 配置不兼容 | 尝试 OpenAI-compatible 方式配置 |
| 模型响应不符合人设 | 调整 SOUL.md 性格描述 |
| 容器启动失败 | 检查端口冲突和卷挂载 |

---

**文档版本**: v1.0  
**创建时间**: 2026-03-04  
**作者**: 刚子 (Gang Zi) 🤖
