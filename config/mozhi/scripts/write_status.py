#!/usr/bin/env python3
"""Write mozhi-status.json."""

import argparse
import json
import os
from datetime import datetime, timezone


def main():
    parser = argparse.ArgumentParser(description="Write mozhi-status.json")
    parser.add_argument("--phase", required=True, help="Current phase")
    parser.add_argument("--repo", default="", help="Repo name")
    parser.add_argument("--branch", default="", help="Branch name")
    parser.add_argument("--review-round", type=int, default=0, help="Review round number")
    parser.add_argument("--passed", type=int, default=0, help="Passed test count")
    parser.add_argument("--failed", type=int, default=0, help="Failed test count")
    parser.add_argument("--test-cases", type=int, default=0, help="Total test cases")
    parser.add_argument("--clear-task", action="store_true", help="Set current_task to null")
    parser.add_argument("--status-file", default="", help="Override status file path")

    args = parser.parse_args()
    now = datetime.now(timezone.utc).isoformat()

    if args.status_file:
        status_file = args.status_file
    elif args.repo and args.branch:
        branch_safe = args.branch.replace("/", "-")
        status_file = f"/shared/{args.repo}/{branch_safe}/mozhi-status.json"
    elif args.clear_task:
        print("ERROR: --clear-task requires --status-file or --repo + --branch")
        raise SystemExit(1)
    else:
        print("ERROR: need --repo + --branch or --status-file")
        raise SystemExit(1)

    os.makedirs(os.path.dirname(status_file), exist_ok=True)

    existing = {}
    if os.path.exists(status_file):
        with open(status_file, "r", encoding="utf-8") as f:
            existing = json.load(f)

    existing_detail = existing.get("phase_detail", {}) if isinstance(existing, dict) else {}
    existing_stats = existing.get("statistics", {}) if isinstance(existing, dict) else {}

    if args.clear_task:
        current_task = None
        phase_detail = {
            "started_at": existing_detail.get("started_at"),
            "target_commit": existing_detail.get("target_commit"),
            "last_checked_commit": existing_detail.get("last_checked_commit"),
        }
        statistics = {
            "test_cases": 0,
            "passed": 0,
            "failed": 0,
            "review_rounds": 0,
            "tokens_used": existing_stats.get("tokens_used", 0),
            "duration_seconds": existing_stats.get("duration_seconds", 0),
        }
    else:
        current_task = {
            "repo": args.repo,
            "branch": args.branch,
        }
        phase_detail = {
            "started_at": existing_detail.get("started_at") or now,
            "target_commit": existing_detail.get("target_commit"),
            "last_checked_commit": existing_detail.get("last_checked_commit"),
        }
        statistics = {
            "test_cases": args.test_cases,
            "passed": args.passed,
            "failed": args.failed,
            "review_rounds": args.review_round,
            "tokens_used": existing_stats.get("tokens_used", 0),
            "duration_seconds": existing_stats.get("duration_seconds", 0),
        }

    status = {
        "agent": "mozhi",
        "phase": args.phase,
        "current_task": current_task,
        "phase_detail": phase_detail,
        "statistics": statistics,
        "last_update": now,
        "heartbeat": now,
    }

    with open(status_file, "w", encoding="utf-8") as f:
        json.dump(status, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Status written: {status_file} (phase={args.phase})")


if __name__ == "__main__":
    main()
