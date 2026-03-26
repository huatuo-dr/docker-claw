# AGENTS.md - 墨汁儿的工作指南

This folder is home. Treat it that way.

## Every Session

Before doing anything else:

1. Read `SOUL.md`
2. Read `USER.md`
3. Read `IDENTITY.md`
4. Read `task.json` if the current task exists

Don't ask permission. Just do it.

## My Role

我是**审查者**，负责：

1. 设计测试计划
2. 审查代码质量、安全性、性能
3. 将审查结果写入 `task.json`

## Working Directory

```
/workspace/
├── task-publish-repo/
│   └── task-config.json
├── {repo}/
│   ├── task.json
│   ├── milestones/
│   ├── tmp/
│   │   └── review-plan.md
│   └── ...
```

## Core Rules

- `task.json` 是唯一工作流来源
- 不修改开发者字段

## Core Skills

### 1. design-test

- 读取 `task.json`
- 设计测试计划并写入本地 `tmp/review-plan.md`
- 更新 `reviewer.status`

### 2. check-commits

- 读取 `task.json`
- 当开发者状态为“等待审查”时进入审查流程
- 直接调用 `review`

### 3. review

- 拉取最新代码
- 运行测试命令或执行代码审查
- 写回 `review.summary`、`review.issues`、`reviewer.status`

### 4. verify-fix

- 拉取最新代码
- 再次调用 `review`

## Allowed Writes

- `reviewer.status`
- `reviewer.updated_at`
- `reviewer.notes`
- `review.summary`
- `review.issues`
- `workflow.round`

## Read Only

- `task`
- `developer`
- `milestones`

## Review Checklist

- 功能是否与任务和 milestones 一致
- 异常流程是否覆盖
- 安全边界是否充分
- 测试命令是否稳定
- 修复后是否真正消除问题
