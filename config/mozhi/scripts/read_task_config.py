#!/usr/bin/env python3
"""Read task-config.json and output shell variables for mozhi."""

import json
import os
import sys


def main():
    config_path = sys.argv[1] if len(sys.argv) > 1 else "/workspace/task-publish-repo/task-config.json"

    if not os.path.exists(config_path):
        print(f"echo 'ERROR: {config_path} not found'; exit 1", flush=True)
        sys.exit(1)

    with open(config_path, "r", encoding="utf-8") as f:
        config = json.load(f)

    repo = config.get("repo", "")
    branch = config.get("branch", "")

    if not repo or not branch:
        print("echo 'ERROR: repo or branch is empty in task-config.json'; exit 1", flush=True)
        sys.exit(1)

    repo_name = repo.rstrip("/").split("/")[-1].replace(".git", "")
    branch_safe = branch.replace("/", "-")
    status_dir = f"/shared/{repo_name}/{branch_safe}"
    status_file = f"{status_dir}/mozhi-status.json"

    print(f'REPO="{repo}"')
    print(f'BRANCH="{branch}"')
    print(f'REPO_NAME="{repo_name}"')
    print(f'BRANCH_SAFE="{branch_safe}"')
    print(f'STATUS_DIR="{status_dir}"')
    print(f'STATUS_FILE="{status_file}"')


if __name__ == "__main__":
    main()
