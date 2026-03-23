#!/usr/bin/env python3
"""Read and update task.json for jianbing workflows.

Usage:
    python3 parse_task.py [task_path]
    python3 parse_task.py --developer-status-only [task_path]
    python3 parse_task.py --reviewer-status-only [task_path]
    python3 parse_task.py --review-result-only [task_path]
    python3 parse_task.py --title-only [task_path]
    python3 parse_task.py --pending-only [task_path]
    python3 parse_task.py --goal 1 [task_path]
    python3 parse_task.py --set-milestone-status 1:done [task_path]
    python3 parse_task.py --set-developer-status 开发中 [task_path]
    python3 parse_task.py --set-round 1 [task_path]
    python3 parse_task.py --set-archived true [task_path]
    python3 parse_task.py --append-developer-note "开始开发" [task_path]
    python3 parse_task.py --round-only [task_path]
"""

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


def set_developer_status(task, status):
    task.setdefault("developer", {})
    task["developer"]["status"] = status
    task["developer"]["updated_at"] = now_iso()


def set_round(task, round_num):
    task.setdefault("workflow", {})
    task["workflow"]["round"] = round_num


def set_archived(task, archived):
    task.setdefault("workflow", {})
    task["workflow"]["archived"] = archived
    if archived:
        task.setdefault("audit", {})
        task["audit"]["archived_at"] = now_iso()


def append_developer_note(task, message):
    task.setdefault("developer", {})
    task["developer"].setdefault("notes", [])
    task["developer"]["notes"].append({
        "at": now_iso(),
        "message": message,
    })
    task["developer"]["updated_at"] = now_iso()


def set_milestone_status(task, milestone_id, new_status):
    for milestone in task.get("milestones", []):
        if milestone.get("id") == milestone_id:
            milestone["status"] = new_status
            return True
    return False


def pending_ids(task):
    result = []
    for milestone in task.get("milestones", []):
        if milestone.get("status") != "done":
            result.append(milestone.get("id"))
    return result


def goal_for(task, milestone_id):
    for milestone in task.get("milestones", []):
        if milestone.get("id") == milestone_id:
            return milestone.get("goal", "")
    return ""


def main():
    args = sys.argv[1:]
    filepath = task_path_from_args(args)

    developer_status_only = "--developer-status-only" in args
    reviewer_status_only = "--reviewer-status-only" in args
    review_result_only = "--review-result-only" in args
    title_only = "--title-only" in args
    pending_only = "--pending-only" in args
    round_only = "--round-only" in args

    goal_num = None
    if "--goal" in args:
        idx = args.index("--goal")
        goal_num = int(args[idx + 1])

    milestone_update = None
    if "--set-milestone-status" in args:
        idx = args.index("--set-milestone-status")
        milestone_update = args[idx + 1]

    new_developer_status = None
    if "--set-developer-status" in args:
        idx = args.index("--set-developer-status")
        new_developer_status = args[idx + 1]

    new_round = None
    if "--set-round" in args:
        idx = args.index("--set-round")
        new_round = int(args[idx + 1])

    new_archived = None
    if "--set-archived" in args:
        idx = args.index("--set-archived")
        raw = args[idx + 1].lower()
        if raw not in ("true", "false"):
            print("ERROR: --set-archived must be true or false", file=sys.stderr)
            sys.exit(1)
        new_archived = raw == "true"

    developer_note = None
    if "--append-developer-note" in args:
        idx = args.index("--append-developer-note")
        developer_note = args[idx + 1]

    try:
        task = load_task(filepath)
    except FileNotFoundError:
        if developer_status_only or reviewer_status_only or review_result_only or title_only:
            print("not_found")
        elif pending_only or goal_num is not None:
            print("")
        elif round_only:
            print("0")
        else:
            print(json.dumps({"error": f"{filepath} not found"}, ensure_ascii=False))
        sys.exit(1)

    if milestone_update:
        milestone_id_str, new_status = milestone_update.split(":", 1)
        updated = set_milestone_status(task, int(milestone_id_str), new_status)
        if not updated:
            print(f"ERROR: milestone {milestone_id_str} not found", file=sys.stderr)
            sys.exit(1)
        save_task(filepath, task)
        return

    if new_developer_status is not None:
        set_developer_status(task, new_developer_status)
        save_task(filepath, task)
        return

    if new_round is not None:
        set_round(task, new_round)
        save_task(filepath, task)
        return

    if new_archived is not None:
        set_archived(task, new_archived)
        save_task(filepath, task)
        return

    if developer_note is not None:
        append_developer_note(task, developer_note)
        save_task(filepath, task)
        return

    if developer_status_only:
        print(task.get("developer", {}).get("status", "unknown"))
    elif reviewer_status_only:
        print(task.get("reviewer", {}).get("status", "unknown"))
    elif review_result_only:
        summary = task.get("review", {}).get("summary")
        print(summary.get("result", "pending") if summary else "pending")
    elif title_only:
        print(task.get("task", {}).get("title", ""))
    elif pending_only:
        print(" ".join(str(item) for item in pending_ids(task)))
    elif goal_num is not None:
        print(goal_for(task, goal_num))
    elif round_only:
        print(task.get("workflow", {}).get("round", 0))
    else:
        print(json.dumps(task, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
