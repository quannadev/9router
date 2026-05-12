#!/usr/bin/env bash
set -e

BASE_URL="https://api.shopaikey.com"
SETTINGS_DIR="$HOME/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

echo "=== ShopAIKey - Claude Code Setup ==="
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
node -e "
const fs = require('fs');
const file = '$SETTINGS_FILE';
let cfg = {};
if (fs.existsSync(file)) {
  try { cfg = JSON.parse(fs.readFileSync(file, 'utf8')); } catch(e) {}
}
cfg.env = cfg.env || {};
cfg.env.ANTHROPIC_BASE_URL = '$BASE_URL';
cfg.env.ANTHROPIC_AUTH_TOKEN = '$API_KEY';
fs.writeFileSync(file, JSON.stringify(cfg, null, 2));
"

echo ""
echo "Hoàn tất! Cấu hình đã được lưu vào $SETTINGS_FILE"
echo "Chạy 'claude' để bắt đầu sử dụng."
