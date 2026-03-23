# 墨汁儿 Heartbeat 任务

cd /workspace

# 克隆/更新 task-publish-repo
if [ ! -d "task-publish-repo" ]; then
  git clone git@github.com:huatuo-dr/task-publish-repo.git
fi

cd task-publish-repo
git fetch origin
git checkout master
git pull origin master

# 读取任务配置
eval $(python3 /scripts/read_task_config.py)

# 克隆/更新开发仓库
cd /workspace
if [ ! -d "$REPO_NAME" ]; then
  git clone "$REPO" "$REPO_NAME"
fi

cd $REPO_NAME
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"

# 读取 task.json 状态
if [ -f "task.json" ]; then
  DEV_STATUS=$(python3 /scripts/parse_task.py --developer-status-only task.json)
  REVIEW_STATUS=$(python3 /scripts/parse_task.py --reviewer-status-only task.json)
  REVIEW_RESULT=$(python3 /scripts/parse_task.py --review-result-only task.json)
  ROUND=$(python3 /scripts/parse_task.py --round-only task.json)
  echo "当前开发者状态: $DEV_STATUS"
  echo "当前审查者状态: $REVIEW_STATUS"
  echo "当前审查结果: $REVIEW_RESULT"
  echo "当前轮次: $ROUND"
else
  echo "No task.json found, waiting for task"
fi
