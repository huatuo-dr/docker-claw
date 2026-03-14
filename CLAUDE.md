# Docker-Claw

多 Agent 协作开发系统（刚子+煎饼+墨汁儿）

## 仓库
- 任务发布: huatuo-dr/task-publish-repo (master)
- 开发: huatuo-dr/test-task-repo (task/*)

## 流程
需求 → 刚子创里程碑 → 煎饼开发 → 墨汁儿审查 → 刚子归档 → 用户合并

## 状态
待开发 → 开发中 → 开发完成 → 测试计划完成 → 测试中 → 测试通过 → 可归档 → 已归档

## 规范
- 提交: `{角色}: {描述}` (如 `煎饼: M1: 实现登录`)
- 分支: `task/{名称}`
- 每次提交前 `git pull --rebase` 防冲突
- 归档不删分支，用户手动删除

## 常用
```bash
# 触发煎饼
docker exec jianbing-claw-container openclaw agent --local --agent main --message "..."

# 触发墨汁儿
docker exec mozhi-claw-container openclaw agent --local --agent main --message "..."
```

## 测试规则
当我们测试Agent之间的协作是，期间不能干预或影响Agent，只监控和记录，最后复盘

## 沟通规则
每次回答前，在内容前面加上：【K哥】
