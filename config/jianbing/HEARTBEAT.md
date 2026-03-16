# 煎饼 Heartbeat 任务

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
REPO=$(cat task-config.json | grep -o '"repo"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
BRANCH=$(cat task-config.json | grep -o '"branch"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

# 克隆/更新开发仓库
cd /workspace
REPO_NAME=$(echo $REPO | sed 's|.*/||' | sed 's|\.git||')

if [ ! -d "$REPO_NAME" ]; then
  git clone "$REPO" "$REPO_NAME"
fi

cd $REPO_NAME
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"

# 读取 milestone.md 状态
MILESTONE_STATUS=$(grep -A1 "## 开发状态" milestone.md | grep "状态" | cut -d: -f2 | tr -d ' ')
echo "当前开发状态: $MILESTONE_STATUS"
