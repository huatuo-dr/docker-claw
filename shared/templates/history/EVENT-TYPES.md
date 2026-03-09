# 事件类型定义

## 事件通用结构

```json
{
  "event_id": "EVT-{timestamp}-{random}",
  "ts": "2024-12-15T10:00:00Z",
  "agent": "gangzi",
  "event": "task_created",
  "phase": "initialized",
  "data": {}
}
```

## 刚子（gangzi）事件

| 事件 | 阶段 | 说明 | data字段 |
|-----|------|------|---------|
| `project_created` | - | 创建项目 | `{project_id, name}` |
| `task_created` | initialized | 创建任务 | `{task_id, task_name, branch}` |
| `task_started` | developing | 启动任务 | `{task_id}` |
| `task_completed` | completed | 完成任务 | `{task_id, duration}` |
| `task_failed` | failed | 任务失败 | `{task_id, error}` |
| `heartbeat_check` | *any* | 心跳检查 | `{status_summary}` |
| `exception_detected` | *any* | 检测到异常 | `{exception_type, details}` |
| `archive_started` | archiving | 开始归档 | `{task_id}` |
| `archive_completed` | archived | 归档完成 | `{task_id, merged_to}` |

## 煎饼（jianbing）事件

| 事件 | 阶段 | 说明 | data字段 |
|-----|------|------|---------|
| `pull_milestone` | initialized | 拉取milestone | `{task_id, branch}` |
| `start_developing` | developing | 开始开发 | `{task_id}` |
| `commit_created` | developing | 创建commit | `{commit_sha, message}` |
| `push_code` | developing | 推送代码 | `{task_id, commits_count}` |
| `issue_checked` | waiting_issue | 检查Issue | `{has_issue, issue_number}` |
| `start_fixing` | fixing | 开始修复 | `{task_id, issue_number}` |
| `fix_pushed` | fixing | 推送修复 | `{task_id, issue_number, commit_sha}` |
| `all_milestones_done` | waiting_review | 全部完成 | `{task_id, total_commits}` |

## 墨汁儿（mozhi）事件

| 事件 | 阶段 | 说明 | data字段 |
|-----|------|------|---------|
| `check_commits` | waiting_review | 检查commit | `{task_id, new_commits}` |
| `start_review` | reviewing | 开始审查 | `{task_id}` |
| `review_passed` | completed | 审查通过 | `{task_id}` |
| `issue_created` | waiting_issue | 创建Issue | `{task_id, issue_number, bugs_count}` |
| `verify_fix` | verifying | 验证修复 | `{task_id, issue_number}` |
| `fix_verified` | completed | 修复验证通过 | `{task_id, issue_number}` |
| `issue_timeout_warning` | waiting_issue | Issue超时警告 | `{task_id, issue_number, comments_count}` |
| `issue_timeout` | exception | Issue超时 | `{task_id, issue_number, comments_count}` |

## 阶段流转

```
initialized → developing → waiting_review → reviewing → completed
                 ↓              ↓              ↓
            waiting_issue → fixing → verifying → completed
                 ↓              ↓
            exception ← exception ←
```

## 阶段说明

| 阶段 | 说明 |
|-----|------|
| initialized | 任务已创建，等待开始 |
| developing | 煎饼开发中 |
| waiting_review | 开发完成，等待墨汁儿审查 |
| reviewing | 墨汁儿审查中 |
| waiting_issue | 发现Bug，创建Issue，等待煎饼修复 |
| fixing | 煎饼修复Bug中 |
| verifying | 墨汁儿验证修复中 |
| completed | 任务完成 |
| exception | 异常状态 |
| archiving | 归档中 |
| archived | 已归档 |
