#!/usr/bin/env python3
"""Write jianbing-status.json.

Usage:
    python3 write_status.py --phase "开发中" --repo test-task-repo --branch task/login
    python3 write_status.py --phase "等待任务" --clear-task
    python3 write_status.py --phase "等待第1轮测试" --repo test-task-repo --branch task/login --test-round 1 --commits 3

Options:
    --phase         Required. Current phase.
    --repo          Repo name (omit with --clear-task).
    --branch        Branch name (omit with --clear-task).
    --test-round    Test round number (default: 0).
    --commits       Local commit count (default: 0).
    --clear-task    Set current_task to null.
    --status-file   Override status file path (default: auto-resolved from repo/branch).
"""

import argparse
import json
import os
from datetime import datetime, timezone


def main():
    parser = argparse.ArgumentParser(description="Write jianbing-status.json")
    parser.add_argument("--phase", required=True, help="Current phase")
    parser.add_argument("--repo", default="", help="Repo name")
    parser.add_argument("--branch", default="", help="Branch name")
    parser.add_argument("--test-round", type=int, default=0, help="Test round number")
    parser.add_argument("--commits", type=int, default=0, help="Local commit count")
    parser.add_argument("--clear-task", action="store_true", help="Set current_task to null")
    parser.add_argument("--status-file", default="", help="Override status file path")

    args = parser.parse_args()

    now = datetime.now(timezone.utc).isoformat()

    # resolve status file path
    if args.status_file:
        status_file = args.status_file
    elif args.repo and args.branch:
        branch_safe = args.branch.replace("/", "-")
        status_dir = f"/shared/{args.repo}/{branch_safe}"
        status_file = f"{status_dir}/jianbing-status.json"
    else:
        print("ERROR: need --repo + --branch or --status-file")
        raise SystemExit(1)

    # ensure directory exists
    os.makedirs(os.path.dirname(status_file), exist_ok=True)

    # build status object
    if args.clear_task:
        current_task = None
        phase_detail = {
            "started_at": None,
            "test_round": 0,
            "local_commits": 0,
            "last_push_at": None,
        }
    else:
        current_task = {
            "repo": args.repo,
            "branch": args.branch,
        }
        phase_detail = {
            "started_at": now,
            "test_round": args.test_round,
            "local_commits": args.commits,
            "last_push_at": now if args.phase != "开发中" else None,
        }

    status = {
        "agent": "jianbing",
        "phase": args.phase,
        "current_task": current_task,
        "phase_detail": phase_detail,
        "last_update": now,
        "heartbeat": now,
    }

    with open(status_file, "w", encoding="utf-8") as f:
        json.dump(status, f, ensure_ascii=False, indent=2)

    print(f"Status written: {status_file} (phase={args.phase})")


if __name__ == "__main__":
    main()
