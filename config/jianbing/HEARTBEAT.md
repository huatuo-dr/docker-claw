# 煎饼 Heartbeat 任务

cd /workspace

# === 1. clone/update task-publish-repo ===
if [ ! -d "task-publish-repo" ]; then
  git clone git@github.com:huatuo-dr/task-publish-repo.git
fi

cd task-publish-repo
git fetch origin
git checkout master
git pull origin master

# === 2. read task config (Python handles JSON parsing) ===
eval $(python3 /scripts/read_task_config.py)

# === 3. clone/update dev repo ===
cd /workspace

if [ ! -d "$REPO_NAME" ]; then
  git clone "$REPO" "$REPO_NAME"
fi

cd $REPO_NAME
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"

# === 4. ensure status directory exists ===
mkdir -p "$STATUS_DIR"

# === 5. read task.json and decide action ===
if [ -f "task.json" ]; then
  DEV_STATUS=$(python3 /scripts/parse_task.py --developer-status-only task.json)
  REVIEW_STATUS=$(python3 /scripts/parse_task.py --reviewer-status-only task.json)
  REVIEW_RESULT=$(python3 /scripts/parse_task.py --review-result-only task.json)
  echo "当前开发者状态: $DEV_STATUS"
  echo "当前审查者状态: $REVIEW_STATUS"
  echo "当前审查结果: $REVIEW_RESULT"

  if [ "$REVIEW_RESULT" = "passed" ] || [ "$REVIEW_STATUS" = "审查通过" ]; then
    echo "ACTION: start archive"
  elif [ "$REVIEW_RESULT" = "changes_requested" ] || [ "$REVIEW_STATUS" = "等待修复" ]; then
    echo "ACTION: start develop"
  else
    case "$DEV_STATUS" in
    "待开发"|"开发中"|"修复中")
      echo "ACTION: start develop"
      ;;
    *)
      echo "ACTION: none (status=$DEV_STATUS)"
      ;;
    esac
  fi
else
  echo "No task.json found, waiting for task"
fi
