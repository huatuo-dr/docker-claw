# 刚子 Heartbeat 任务

cd /workspace

if [ ! -d "task-publish-repo" ]; then
  git clone git@github.com:huatuo-dr/task-publish-repo.git
fi

cd task-publish-repo
git fetch origin
git checkout master
git pull origin master

if [ ! -f "task-config.json" ]; then
  echo "No task-config.json found"
  exit 0
fi

REPO=$(jq -r '.repo' task-config.json)
BRANCH=$(jq -r '.branch' task-config.json)
REPO_NAME=$(basename "$REPO" .git)

if [[ -z "$REPO" || -z "$BRANCH" || "$REPO" == "null" || "$BRANCH" == "null" ]]; then
  echo "task-config.json 缺少 repo 或 branch"
  exit 0
fi

cd /workspace
if [ ! -d "$REPO_NAME" ]; then
  git clone "$REPO" "$REPO_NAME"
fi

cd "$REPO_NAME"
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"

if [ ! -f "task.json" ]; then
  echo "No task.json found"
  exit 0
fi

echo "当前任务: $(jq -r '.task.title' task.json)"
echo "开发者状态: $(jq -r '.developer.status' task.json)"
echo "审查者状态: $(jq -r '.reviewer.status' task.json)"
echo "审查结果: $(jq -r '.review.summary.result // \"pending\"' task.json)"
echo "当前轮次: $(jq -r '.workflow.round' task.json)"
echo "归档状态: $(jq -r '.workflow.archived' task.json)"
