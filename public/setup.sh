#!/bin/bash
set -e

# Prompt for API key
read -p "Nhập API key của bạn: " API_KEY
if [ -z "$API_KEY" ]; then
    echo "API key không được để trống. Vui lòng chạy lại script và nhập key."
    exit 1
fi

# Check if claude is installed, if not, install it
if ! command -v claude &> /dev/null; then
    echo "'claude' không được tìm thấy. Đang cài đặt..."
    if command -v npm &> /dev/null; then
        npm install -g @anthropic-ai/claude-code
    else
        echo "Lỗi: Cần có 'npm' để cài đặt claude. Vui lòng cài đặt Node.js và npm."
        exit 1
    fi
fi

# Create settings directory if it doesn't exist
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

# Path to the settings file
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Backup existing settings file
if [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak.$(date +%s)"
    echo "Đã sao lưu cài đặt hiện tại tới $SETTINGS_FILE.bak"
fi

# Use Node.js to safely update the JSON settings
node <<EOF
const fs = require('fs');
const path = require('path');

const settingsPath = path.join(process.env.HOME, '.claude', 'settings.json');
let settings = {};

try {
  if (fs.existsSync(settingsPath)) {
    const content = fs.readFileSync(settingsPath, 'utf8');
    if (content.trim()) {
        settings = JSON.parse(content);
    }
  }
} catch (error) {
  console.log('Không thể đọc file cài đặt hiện tại, sẽ tạo một file mới.');
  settings = {};
}

// Ensure env block exists
if (!settings.env) {
    settings.env = {};
}

// Update settings
settings.env.ANTHROPIC_BASE_URL = "https://coding.gapowork.vn/v1";
settings.env.ANTHROPIC_AUTH_TOKEN = "$API_KEY";
settings.env.ANTHROPIC_DEFAULT_OPUS_MODEL = "code-full";
settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL = "code-flash";
settings.env.ANTHROPIC_DEFAULT_HAIKU_MODEL = "code-flash";


try {
  fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
  console.log('Đã cập nhật cài đặt thành công.');
} catch (error) {
  console.error('Lỗi khi ghi file cài đặt:', error);
  process.exit(1);
}
EOF

echo "Hoàn tất! Chạy 'claude' để bắt đầu sử dụng."
