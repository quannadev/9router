# Requires PowerShell 5+
$ErrorActionPreference = "Stop"

$BASE_URL = "https://coding.gapowork.vn/v1"
$SETTINGS_DIR = "$env:USERPROFILE\.claude"
$SETTINGS_FILE = "$SETTINGS_DIR\settings.json"

Write-Host "=== GapoWork - Claude Code Setup ===" -ForegroundColor Cyan
Write-Host ""

# Prompt for API key
$API_KEY = Read-Host "Nhập API key của bạn"
if ([string]::IsNullOrWhiteSpace($API_KEY)) {
    Write-Error "Lỗi: API key không được để trống."
    exit 1
}

# Check and install Claude CLI
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "'claude' không được tìm thấy. Đang cài đặt..."
    try {
        npm install -g @anthropic-ai/claude-code
    } catch {
        Write-Error "Lỗi: Cần có 'npm' để cài đặt claude. Vui lòng cài đặt Node.js và npm."
        exit 1
    }
} else {
    Write-Host "Claude CLI đã được cài đặt."
}

# Create directory if it doesn't exist
if (-not (Test-Path $SETTINGS_DIR)) {
    New-Item -ItemType Directory -Path $SETTINGS_DIR | Out-Null
}

# Backup existing settings
if (Test-Path $SETTINGS_FILE) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    Copy-Item $SETTINGS_FILE "$SETTINGS_FILE.bak.$timestamp"
    Write-Host "Đã sao lưu cài đặt hiện tại tới $SETTINGS_FILE.bak.$timestamp"
}

# Merge/write settings.json
$cfg = @{}
if (Test-Path $SETTINGS_FILE) {
    try {
        $content = Get-Content $SETTINGS_FILE -Raw
        if ($content) {
            $cfg = $content | ConvertFrom-Json -AsHashtable
        }
    } catch {
        Write-Host "Không thể đọc file cài đặt hiện tại, sẽ tạo một file mới."
    }
}
if (-not $cfg.ContainsKey("env")) { $cfg["env"] = @{} }
$cfg["env"]["ANTHROPIC_BASE_URL"] = $BASE_URL
$cfg["env"]["ANTHROPIC_AUTH_TOKEN"] = $API_KEY
$cfg["env"]["ANTHROPIC_DEFAULT_OPUS_MODEL"] = "code-full"
$cfg["env"]["ANTHROPIC_DEFAULT_SONNET_MODEL"] = "code-flash"
$cfg["env"]["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = "code-flash"

$cfg | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS_FILE -Encoding UTF8

Write-Host ""
Write-Host "Hoàn tất! Cấu hình đã được lưu vào $SETTINGS_FILE" -ForegroundColor Green
Write-Host "Chạy 'claude' để bắt đầu sử dụng."
