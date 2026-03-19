#!/usr/bin/env python3
"""Parse milestone.md and output structured information.

Usage:
    python3 parse_milestone.py [milestone_path]
    python3 parse_milestone.py --status-only [milestone_path]
    python3 parse_milestone.py --pending-only [milestone_path]

Default output (JSON):
    {
        "dev_status": "待开发",
        "test_status": "待开发",
        "milestones": [
            {"number": 1, "title": "创建用户模型", "status": "⬜", "goal": "..."},
            {"number": 2, "title": "实现注册接口", "status": "✅", "goal": "..."}
        ],
        "pending": [1],
        "completed": [2]
    }

--status-only: output only dev_status (plain text, for shell use)
--pending-only: output pending milestone numbers (space-separated, for shell use)
"""

import json
import re
import sys


def parse_milestone(filepath):
    """Parse milestone.md and return structured data."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # extract dev status
    dev_match = re.search(r"## 开发状态.*?\n.*?\*\*状态\*\*:\s*(.+)", content)
    dev_status = dev_match.group(1).strip() if dev_match else "unknown"

    # extract test status
    test_match = re.search(r"## 测试状态.*?\n.*?\*\*状态\*\*:\s*(.+)", content)
    test_status = test_match.group(1).strip() if test_match else "unknown"

    # extract milestones
    milestones = []
    pending = []
    completed = []

    milestone_pattern = re.compile(
        r"## 里程碑\s*(\d+):\s*(.*?)(?:\(.*?\))?\s*\n", re.MULTILINE
    )

    for match in milestone_pattern.finditer(content):
        num = int(match.group(1))
        title = match.group(2).strip()

        # find status marker after this milestone header
        section_start = match.end()
        next_milestone = milestone_pattern.search(content, section_start)
        section_end = next_milestone.start() if next_milestone else len(content)
        section = content[section_start:section_end]

        # detect status
        if "✅" in section:
            status = "✅"
            completed.append(num)
        elif "🔄" in section:
            status = "🔄"
        else:
            status = "⬜"
            pending.append(num)

        # extract goal
        goal_match = re.search(r"\*\*目标\*\*:\s*(.+)", section)
        goal = goal_match.group(1).strip() if goal_match else ""

        milestones.append({
            "number": num,
            "title": title,
            "status": status,
            "goal": goal,
        })

    return {
        "dev_status": dev_status,
        "test_status": test_status,
        "milestones": milestones,
        "pending": pending,
        "completed": completed,
    }


def main():
    status_only = "--status-only" in sys.argv
    pending_only = "--pending-only" in sys.argv

    # find filepath (non-flag argument)
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    filepath = args[0] if args else "/workspace/milestone.md"

    try:
        result = parse_milestone(filepath)
    except FileNotFoundError:
        if status_only:
            print("not_found")
        elif pending_only:
            print("")
        else:
            print(json.dumps({"error": f"{filepath} not found"}, ensure_ascii=False))
        sys.exit(1)

    if status_only:
        print(result["dev_status"])
    elif pending_only:
        print(" ".join(str(n) for n in result["pending"]))
    else:
        print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
