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

# === 5. read milestone.md and decide action ===
if [ -f "milestone.md" ]; then
  DEV_STATUS=$(python3 /scripts/parse_milestone.py --status-only milestone.md)
  echo "当前开发状态: $DEV_STATUS"

  case "$DEV_STATUS" in
    "待开发")
      echo "ACTION: start develop"
      ;;
    "可归档")
      echo "ACTION: start archive"
      ;;
    *修复中*)
      echo "ACTION: continue fix"
      ;;
    *)
      echo "ACTION: none (status=$DEV_STATUS)"
      ;;
  esac
else
  echo "No milestone.md found, waiting for task"
fi
