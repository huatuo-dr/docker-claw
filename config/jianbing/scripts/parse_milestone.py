#!/usr/bin/env python3
"""Parse milestone.md and output structured information.

Usage:
    python3 parse_milestone.py [milestone_path]
    python3 parse_milestone.py --status-only [milestone_path]
    python3 parse_milestone.py --pending-only [milestone_path]
    python3 parse_milestone.py --goal 1 [milestone_path]
    python3 parse_milestone.py --update-status 1:🔄 [milestone_path]
    python3 parse_milestone.py --set-dev-status "等待第1轮测试" [milestone_path]
    python3 parse_milestone.py --get-test-round [milestone_path]

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

--status-only:      output dev_status (plain text)
--pending-only:     output pending milestone numbers (space-separated)
--goal N:           output goal text for milestone N
--update-status N:S update milestone N status (S: ⬜/🔄/✅)
--set-dev-status S: update dev status field in milestone.md
--get-test-round:   output current test round number (parsed from dev_status)
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


def update_milestone_status(filepath, milestone_num, new_status):
    """Update a milestone's status marker in the file.

    Args:
        milestone_num: milestone number to update
        new_status: one of ⬜/🔄/✅
    """
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    status_map = {"⬜": "⬜ 待开始", "🔄": "🔄 进行中", "✅": "✅ 已完成"}
    all_markers = list(status_map.values())
    new_marker = status_map.get(new_status, new_status)

    # find the milestone section and replace status
    pattern = re.compile(
        rf"(## 里程碑\s*{milestone_num}:.*?\n(?:.*?\n)*?.*?状态.*?:\s*)((?:{'|'.join(re.escape(m) for m in all_markers)}))",
        re.MULTILINE,
    )
    match = pattern.search(content)
    if match:
        content = content[:match.start(2)] + new_marker + content[match.end(2):]
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Milestone {milestone_num} status updated to {new_marker}")
    else:
        print(f"WARNING: could not find status field for milestone {milestone_num}", file=sys.stderr)


def set_dev_status(filepath, new_status):
    """Update the dev status field in milestone.md."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    content = re.sub(
        r"(## 开发状态.*?\n.*?\*\*状态\*\*:\s*).+",
        rf"\g<1>{new_status}",
        content,
    )

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Dev status updated to: {new_status}")


def get_test_round(dev_status):
    """Extract test round number from dev status string.

    Examples:
        "等待第1轮测试" -> 1
        "第2轮测试修复中" -> 2
        "待开发" -> 0
    """
    match = re.search(r"第(\d+)轮", dev_status)
    return int(match.group(1)) if match else 0


def main():
    status_only = "--status-only" in sys.argv
    pending_only = "--pending-only" in sys.argv
    get_round = "--get-test-round" in sys.argv

    # parse --goal N
    goal_num = None
    if "--goal" in sys.argv:
        idx = sys.argv.index("--goal")
        if idx + 1 < len(sys.argv):
            goal_num = int(sys.argv[idx + 1])

    # parse --update-status N:S
    update_spec = None
    if "--update-status" in sys.argv:
        idx = sys.argv.index("--update-status")
        if idx + 1 < len(sys.argv):
            update_spec = sys.argv[idx + 1]

    # parse --set-dev-status S
    new_dev_status = None
    if "--set-dev-status" in sys.argv:
        idx = sys.argv.index("--set-dev-status")
        if idx + 1 < len(sys.argv):
            new_dev_status = sys.argv[idx + 1]

    # find filepath (non-flag argument, skip flag values)
    skip_next = False
    args = []
    for i, a in enumerate(sys.argv[1:], 1):
        if skip_next:
            skip_next = False
            continue
        if a in ("--goal", "--update-status", "--set-dev-status"):
            skip_next = True
            continue
        if not a.startswith("--"):
            args.append(a)
    filepath = args[0] if args else "/workspace/milestone.md"

    # handle write operations (no need to parse full structure)
    if update_spec:
        num_str, status = update_spec.split(":", 1)
        update_milestone_status(filepath, int(num_str), status)
        return

    if new_dev_status:
        set_dev_status(filepath, new_dev_status)
        return

    # parse milestone for read operations
    try:
        result = parse_milestone(filepath)
    except FileNotFoundError:
        if status_only or get_round:
            print("not_found" if status_only else "0")
        elif pending_only or goal_num is not None:
            print("")
        else:
            print(json.dumps({"error": f"{filepath} not found"}, ensure_ascii=False))
        sys.exit(1)

    if status_only:
        print(result["dev_status"])
    elif pending_only:
        print(" ".join(str(n) for n in result["pending"]))
    elif goal_num is not None:
        ms = [m for m in result["milestones"] if m["number"] == goal_num]
        print(ms[0]["goal"] if ms else "")
    elif get_round:
        print(get_test_round(result["dev_status"]))
    else:
        print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
