#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="/Users/Jacob/international_news_digest"
VENV_PYTHON="$SCRIPT_DIR/.venv/bin/python"
LOG_DIR="$SCRIPT_DIR/logs"
ENV_FILE="$SCRIPT_DIR/.env"

mkdir -p "$LOG_DIR"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

exec "$VENV_PYTHON" "$SCRIPT_DIR/news_digest.py" \
  --timezone Asia/Shanghai \
  --output-dir "$SCRIPT_DIR/output" \
  --send-email \
  --translate-zh \
  >> "$LOG_DIR/news_digest.log" 2>&1
