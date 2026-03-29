#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
PYTHON_BIN="${PYTHON_BIN:-python3}"
ENV_EXAMPLE="$SCRIPT_DIR/.env.example"
ENV_FILE="$SCRIPT_DIR/.env"
RUN_SCRIPT="$SCRIPT_DIR/run_news_digest.sh"
PLIST_SOURCE="$SCRIPT_DIR/com.jacob.internationalnewsdigest.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_TARGET="$LAUNCH_AGENTS_DIR/com.jacob.internationalnewsdigest.plist"
LABEL="com.jacob.internationalnewsdigest"

check_env_requirements() {
  local missing=()

  if [[ ! -f "$ENV_FILE" ]]; then
    echo "[WARN] .env not found: $ENV_FILE"
    return
  fi

  set -a
  source "$ENV_FILE"
  set +a

  [[ -n "${NEWS_DIGEST_SMTP_HOST:-}" ]] || missing+=("NEWS_DIGEST_SMTP_HOST")
  [[ -n "${NEWS_DIGEST_SMTP_PORT:-}" ]] || missing+=("NEWS_DIGEST_SMTP_PORT")
  [[ -n "${NEWS_DIGEST_SMTP_USER:-}" ]] || missing+=("NEWS_DIGEST_SMTP_USER")
  [[ -n "${NEWS_DIGEST_SMTP_PASSWORD:-}" ]] || missing+=("NEWS_DIGEST_SMTP_PASSWORD")
  [[ -n "${NEWS_DIGEST_SENDER:-}" ]] || missing+=("NEWS_DIGEST_SENDER")
  [[ -n "${NEWS_DIGEST_RECIPIENTS:-}" ]] || missing+=("NEWS_DIGEST_RECIPIENTS")

  local provider="${NEWS_DIGEST_TRANSLATION_PROVIDER:-google}"
  if [[ "$provider" == "google" ]]; then
    [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]] || missing+=("GOOGLE_APPLICATION_CREDENTIALS")
    [[ -n "${GOOGLE_CLOUD_PROJECT:-}" ]] || missing+=("GOOGLE_CLOUD_PROJECT")
    if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" && ! -f "${GOOGLE_APPLICATION_CREDENTIALS}" ]]; then
      missing+=("GOOGLE_APPLICATION_CREDENTIALS(file_not_found)")
    fi
  elif [[ "$provider" == "openai" ]]; then
    [[ -n "${OPENAI_API_KEY:-}" ]] || missing+=("OPENAI_API_KEY")
  else
    missing+=("NEWS_DIGEST_TRANSLATION_PROVIDER(unsupported:$provider)")
  fi

  if (( ${#missing[@]} > 0 )); then
    echo
    echo "[WARN] Missing or invalid configuration detected:"
    for item in "${missing[@]}"; do
      echo "  - $item"
    done
  else
    echo
    echo "[INFO] .env validation passed"
  fi
}

echo "[1/6] Checking Python"
command -v "$PYTHON_BIN" >/dev/null 2>&1 || {
  echo "[ERROR] python3 not found"
  exit 1
}

echo "[2/6] Creating virtual environment"
if [[ ! -d "$VENV_DIR" ]]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

echo "[3/6] Installing dependencies"
"$VENV_DIR/bin/pip" install -r "$SCRIPT_DIR/requirements.txt"

echo "[4/6] Preparing environment file"
if [[ ! -f "$ENV_FILE" ]]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  echo "[INFO] Created .env from template: $ENV_FILE"
else
  echo "[INFO] Existing .env found: $ENV_FILE"
fi

echo "[5/6] Installing launchd job"
chmod +x "$RUN_SCRIPT"
mkdir -p "$LAUNCH_AGENTS_DIR"
cp "$PLIST_SOURCE" "$PLIST_TARGET"
launchctl bootout "gui/$(id -u)" "$PLIST_TARGET" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_TARGET"
launchctl enable "gui/$(id -u)/$LABEL"

echo "[6/6] Done"
check_env_requirements
echo
echo "Next steps:"
echo "1. Edit $ENV_FILE"
echo "2. Fill SMTP and Google Translation credentials"
echo "3. Run a manual test:"
echo "   set -a && source $ENV_FILE && set +a && $VENV_DIR/bin/python $SCRIPT_DIR/news_digest.py --translate-zh --send-email --recipient 363349082@qq.com"
echo "4. Check launchd status:"
echo "   launchctl print gui/$(id -u)/$LABEL"
