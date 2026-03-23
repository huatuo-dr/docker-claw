#!/usr/bin/env python3
"""Read and update task.json for mozhi workflows."""

import json
import sys
from datetime import datetime, timezone


def now_iso():
    return datetime.now(timezone.utc).isoformat()


def load_task(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        return json.load(f)


def save_task(filepath, task):
    task.setdefault("audit", {})
    task["audit"]["updated_at"] = now_iso()
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(task, f, ensure_ascii=False, indent=2)
        f.write("\n")


def task_path_from_args(args):
    for arg in reversed(args):
        if not arg.startswith("--"):
            return arg
    return "/workspace/task.json"


def append_reviewer_note(task, message):
    task.setdefault("reviewer", {})
    task["reviewer"].setdefault("notes", [])
    task["reviewer"]["notes"].append({
        "at": now_iso(),
        "message": message,
    })
    task["reviewer"]["updated_at"] = now_iso()


def set_reviewer_status(task, status):
    task.setdefault("reviewer", {})
    task["reviewer"]["status"] = status
    task["reviewer"]["updated_at"] = now_iso()


def set_review_summary(task, result, comment):
    task.setdefault("review", {})
    task["review"]["summary"] = {
        "result": result,
        "comment": comment,
        "updated_at": now_iso(),
    }


def replace_review_issues(task, issues):
    task.setdefault("review", {})
    task["review"]["issues"] = issues


def set_round(task, round_num):
    task.setdefault("workflow", {})
    task["workflow"]["round"] = round_num


def get_pending_issues(task):
    return [
        issue for issue in task.get("review", {}).get("issues", [])
        if issue.get("status") == "open"
    ]


def main():
    args = sys.argv[1:]
    filepath = task_path_from_args(args)

    developer_status_only = "--developer-status-only" in args
    reviewer_status_only = "--reviewer-status-only" in args
    review_result_only = "--review-result-only" in args
    round_only = "--round-only" in args
    title_only = "--title-only" in args
    pending_issues_only = "--pending-issues-only" in args

    new_reviewer_status = None
    if "--set-reviewer-status" in args:
        idx = args.index("--set-reviewer-status")
        new_reviewer_status = args[idx + 1]

    reviewer_note = None
    if "--append-reviewer-note" in args:
        idx = args.index("--append-reviewer-note")
        reviewer_note = args[idx + 1]

    summary_result = None
    summary_comment = None
    if "--set-review-summary" in args:
        idx = args.index("--set-review-summary")
        summary_result = args[idx + 1]
        summary_comment = args[idx + 2]

    issues_json = None
    if "--replace-review-issues" in args:
        idx = args.index("--replace-review-issues")
        issues_json = args[idx + 1]

    new_round = None
    if "--set-round" in args:
        idx = args.index("--set-round")
        new_round = int(args[idx + 1])

    try:
        task = load_task(filepath)
    except FileNotFoundError:
        if developer_status_only or reviewer_status_only or review_result_only or title_only:
            print("not_found")
        elif round_only:
            print("0")
        elif pending_issues_only:
            print("[]")
        else:
            print(json.dumps({"error": f"{filepath} not found"}, ensure_ascii=False))
        sys.exit(1)

    if new_reviewer_status is not None:
        set_reviewer_status(task, new_reviewer_status)
        save_task(filepath, task)
        return

    if reviewer_note is not None:
        append_reviewer_note(task, reviewer_note)
        save_task(filepath, task)
        return

    if summary_result is not None:
        set_review_summary(task, summary_result, summary_comment)
        save_task(filepath, task)
        return

    if issues_json is not None:
        replace_review_issues(task, json.loads(issues_json))
        save_task(filepath, task)
        return

    if new_round is not None:
        set_round(task, new_round)
        save_task(filepath, task)
        return

    if developer_status_only:
        print(task.get("developer", {}).get("status", "unknown"))
    elif reviewer_status_only:
        print(task.get("reviewer", {}).get("status", "unknown"))
    elif review_result_only:
        summary = task.get("review", {}).get("summary")
        print(summary.get("result", "pending") if summary else "pending")
    elif round_only:
        print(task.get("workflow", {}).get("round", 0))
    elif title_only:
        print(task.get("task", {}).get("title", ""))
    elif pending_issues_only:
        print(json.dumps(get_pending_issues(task), ensure_ascii=False))
    else:
        print(json.dumps(task, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
