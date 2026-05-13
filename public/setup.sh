#!/usr/bin/env bash
#
# Gapowork - Claude Code Setup Script
#
# ==============================================================================
#
# PURPOSE:
#   This script provides a one-step setup for configuring the Claude Code CLI
#   to work with the Gapowork proxy service hosted at coding.gapowork.vn.
#   The goal is to automate the configuration process, making it fast and
#   easy for developers to start using the service.
#
# WHAT IT DOES:
#   1. Prompts the user interactively for their API key.
#   2. Checks if the 'claude' CLI is installed and installs it via npm if not.
#   3. Backs up any existing ~/.claude/settings.json file.
#   4. Automatically creates or updates ~/.claude/settings.json to:
#      - Set ANTHROPIC_BASE_URL to point to the Gapowork proxy.
#      - Set ANTHROPIC_AUTH_TOKEN with the provided API key.
#      - Configure default models (opus, sonnet, haiku) for the service.
#
# USAGE:
#   This script is intended to be run directly from the service URL via curl:
#   curl -fsSL https://coding.gapowork.vn/setup.sh | bash
#
# SECURITY NOTICE: This script handles sensitive data (API key) and modifies
# user configuration files in your home directory (~/.claude/settings.json).
# Please review the script to understand the changes it will make.
#
# ==============================================================================
set -e

BASE_URL="https://coding.gapowork.vn/v1"
SETTINGS_DIR="$HOME/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

echo "=== Gapowork Claude Code Setup ==="
echo ""

# Nhập API key
read -rp "Nhập API key của bạn: " API_KEY < /dev/tty
if [ -z "$API_KEY" ]; then
  echo "Lỗi: API key không được để trống."
  exit 1
fi

# Kiểm tra và cài Claude CLI
if ! command -v claude &>/dev/null; then
  echo "Claude CLI chưa được cài. Đang cài đặt..."
  npm install -g @anthropic-ai/claude-code
else
  echo "Claude CLI đã được cài: $(claude --version 2>/dev/null || echo 'ok')"
fi

# Tạo thư mục nếu chưa có
mkdir -p "$SETTINGS_DIR"

# Backup nếu đã có settings
if [ -f "$SETTINGS_FILE" ]; then
  cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak"
  echo "Đã backup: ${SETTINGS_FILE}.bak"
fi

# Merge/ghi settings.json
# SECURITY: Pass values via env vars to avoid shell string interpolation in node -e
API_KEY="$API_KEY" BASE_URL="$BASE_URL" SETTINGS_FILE="$SETTINGS_FILE" node -e '
const fs = require("fs");
const file = process.env.SETTINGS_FILE;
let cfg = {};
if (fs.existsSync(file)) {
  try { cfg = JSON.parse(fs.readFileSync(file, "utf8")); } catch(e) {}
}
cfg.env = cfg.env || {};
cfg.env.ANTHROPIC_BASE_URL = process.env.BASE_URL;
cfg.env.ANTHROPIC_AUTH_TOKEN = process.env.API_KEY;
cfg.env.ANTHROPIC_DEFAULT_OPUS_MODEL = "code-full";
cfg.env.ANTHROPIC_DEFAULT_SONNET_MODEL = "code-flash";
cfg.env.ANTHROPIC_DEFAULT_HAIKU_MODEL = "code-little";
fs.writeFileSync(file, JSON.stringify(cfg, null, 2));
'

echo ""
echo "Hoàn tất! Cấu hình đã được lưu vào $SETTINGS_FILE"
echo "Chạy 'claude' để bắt đầu sử dụng."
