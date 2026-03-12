#!/bin/bash
# entrypoint.sh - 容器启动时自动配置 OpenClaw

set -e

echo "========== 容器启动初始化 =========="

# 获取 Agent 名称和模型
AGENT_NAME=${AGENT_NAME:-unknown}
MODEL=${OPENCLAW_MODEL:-}
echo "Agent: $AGENT_NAME"
echo "Model: $MODEL"

# Gateway 读取的配置文件位置（由于 HOME=/app）
OPENCLAW_CONFIG="/app/.openclaw/openclaw.json"
AGENT_AUTH="/app/.openclaw/agents/main/agent/auth-profiles.json"

# 确保目录存在
mkdir -p /app/.openclaw/agents/main/agent

# 根据 Agent 类型配置模型
if [ "$AGENT_NAME" = "jianbing" ]; then
    echo "配置煎饼的模型..."

    # MiniMax API Key
    if [ -n "$MINIMAX_API_KEY" ]; then
        echo "配置 MiniMax API Key..."

        # 获取模型ID
        MODEL_ID=${MODEL:-MiniMax-M2.5}

        # 创建临时配置文件
        cat > "$OPENCLAW_CONFIG" << EOF
{
  "meta": {
    "lastTouchedVersion": "2026.3.8",
    "lastTouchedAt": "2026-03-12T07:00:00.000Z"
  },
  "wizard": {
    "lastRunAt": "2026-03-12T07:00:00.000Z",
    "lastRunVersion": "2026.3.8",
    "lastRunCommand": "configure",
    "lastRunMode": "local"
  },
  "models": {
    "mode": "merge",
    "providers": {
      "minimax": {
        "baseUrl": "https://api.minimax.chat/v1",
        "api": "openai-completions",
        "models": [
          {
            "id": "MiniMax-M2.5",
            "name": "MiniMax M2.5",
            "reasoning": true,
            "input": ["text"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 245000,
            "maxTokens": 8192,
            "api": "openai-completions"
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "minimax/MiniMax-M2.5"
      },
      "models": {
        "minimax/MiniMax-M2.5": {
          "alias": "Minimax"
        }
      }
    }
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto",
    "restart": true,
    "ownerDisplay": "raw"
  },
  "gateway": {
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "AUTO_GENERATED_TOKEN"
    }
  }
}
EOF

        # 创建 agent auth-profiles.json (使用正确的格式)
        cat > "$AGENT_AUTH" << EOF
{
  "version": 1,
  "profiles": {
    "minimax:default": {
      "type": "api_key",
      "provider": "minimax",
      "key": "$MINIMAX_API_KEY"
    }
  },
  "lastGood": {
    "minimax": "minimax:default"
  },
  "usageStats": {}
}
EOF

        echo "模型配置完成: minimax/MiniMax-M2.5"
    fi

elif [ "$AGENT_NAME" = "mozhi" ]; then
    echo "配置墨汁儿的模型..."

    # 智谱 API Key
    if [ -n "$ZHIPU_API_KEY" ]; then
        echo "配置智谱 API Key..."

        # 获取模型ID
        MODEL_ID=${MODEL:-glm-5}

        # 解析模型提供商和模型ID
        if [[ "$MODEL_ID" == *"/"* ]]; then
            PROVIDER=$(echo "$MODEL_ID" | cut -d'/' -f1)
            MODEL_NAME=$(echo "$MODEL_ID" | cut -d'/' -f2)
        else
            PROVIDER="zhipu"
            MODEL_NAME="$MODEL_ID"
        fi

        echo "使用模型: $PROVIDER/$MODEL_NAME"

        # 创建临时配置文件
        cat > "$OPENCLAW_CONFIG" << EOF
{
  "meta": {
    "lastTouchedVersion": "2026.3.8",
    "lastTouchedAt": "2026-03-12T07:00:00.000Z"
  },
  "wizard": {
    "lastRunAt": "2026-03-12T07:00:00.000Z",
    "lastRunVersion": "2026.3.8",
    "lastRunCommand": "configure",
    "lastRunMode": "local"
  },
  "models": {
    "mode": "merge",
    "providers": {
      "${PROVIDER}": {
        "baseUrl": "https://open.bigmodel.cn/api/paas/v4",
        "api": "openai-completions",
        "models": [
          {
            "id": "${MODEL_NAME}",
            "name": "GLM-5",
            "reasoning": true,
            "input": ["text", "image"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 128000,
            "maxTokens": 8192,
            "api": "openai-completions"
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "${PROVIDER}/${MODEL_NAME}"
      },
      "models": {
        "${PROVIDER}/${MODEL_NAME}": {
          "alias": "GLM"
        }
      }
    }
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto",
    "restart": true,
    "ownerDisplay": "raw"
  },
  "gateway": {
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "AUTO_GENERATED_TOKEN"
    }
  }
}
EOF

        # 创建 agent auth-profiles.json (使用正确的格式)
        cat > "$AGENT_AUTH" << EOF
{
  "version": 1,
  "profiles": {
    "${PROVIDER}:default": {
      "type": "api_key",
      "provider": "${PROVIDER}",
      "key": "$ZHIPU_API_KEY"
    }
  },
  "lastGood": {
    "${PROVIDER}": "${PROVIDER}:default"
  },
  "usageStats": {}
}
EOF

        echo "模型配置完成: ${PROVIDER}/${MODEL_NAME}"
    fi
fi

echo "========== 初始化完成，启动 Gateway =========="

# 执行原始命令
exec "$@"
