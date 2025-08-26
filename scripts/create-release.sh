#!/bin/bash

# Script tạo GitHub Release tự động
# Sử dụng: ./scripts/create-release.sh [version] [release_notes]

set -e

# Đọc version từ argument hoặc package.json
VERSION=${1:-$(node -p "require('./package.json').version")}
RELEASE_NOTES=${2:-"SevenChat ${VERSION} - Cải tiến và sửa lỗi."}

echo "Creating GitHub Release for version: $VERSION"

# Load environment variables
if [ -f "env.build" ]; then
    echo "Loading environment variables from env.build..."
    export $(cat env.build | grep -v '^#' | xargs)
fi

# Kiểm tra GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) chưa được cài đặt"
    echo "Cài đặt: brew install gh"
    exit 1
fi

# Kiểm tra đăng nhập GitHub
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Chưa đăng nhập GitHub CLI"
    echo "Chạy: gh auth login"
    exit 1
fi

# Kiểm tra files tồn tại
ZIP_FILE="dist/SevenChat-${VERSION}-mac.zip"
DMG_FILE="dist/SevenChat-${VERSION}-mac.dmg"
RELEASES_JSON="dist/releases.json"

if [ ! -f "$ZIP_FILE" ]; then
    echo "❌ Error: File $ZIP_FILE không tồn tại"
    echo "Chạy build trước: ./scripts/build-macos.sh $VERSION"
    exit 1
fi

if [ ! -f "$DMG_FILE" ]; then
    echo "❌ Error: File $DMG_FILE không tồn tại"
    echo "Chạy build trước: ./scripts/build-macos.sh $VERSION"
    exit 1
fi

if [ ! -f "$RELEASES_JSON" ]; then
    echo "❌ Error: File $RELEASES_JSON không tồn tại"
    echo "Chạy build trước: ./scripts/build-macos.sh $VERSION"
    exit 1
fi

echo "✅ All required files found"

# Tạo release notes file
RELEASE_NOTES_FILE="dist/release-notes.md"
cat > "$RELEASE_NOTES_FILE" <<EOF
# SevenChat ${VERSION}

${RELEASE_NOTES}

## Downloads

- **macOS Universal**: [SevenChat-${VERSION}-mac.dmg](${DMG_FILE})
- **Auto Update**: App sẽ tự động cập nhật khi có phiên bản mới

## Installation

1. Tải file .dmg
2. Mở và kéo SevenChat vào Applications
3. Chạy lần đầu (có thể cần allow trong Security & Privacy)

## Auto Update

App sẽ tự động kiểm tra cập nhật mỗi giờ. Khi có phiên bản mới:
1. App sẽ tải update tự động
2. Hiển thị thông báo có update sẵn sàng
3. Bấm "Restart" để cài đặt update

## Changelog

- Cải tiến giao diện
- Sửa lỗi và tối ưu hiệu suất
- Cập nhật dependencies
EOF

# Tạo GitHub Release
echo "🚀 Creating GitHub Release..."
gh release create "v${VERSION}" \
    --title "SevenChat ${VERSION}" \
    --notes-file "$RELEASE_NOTES_FILE" \
    --draft=false \
    --prerelease=false

# Upload assets
echo "📤 Uploading assets..."
gh release upload "v${VERSION}" \
    "$ZIP_FILE" \
    "$DMG_FILE" \
    "$RELEASES_JSON" \
    --clobber

echo "✅ GitHub Release created successfully!"
echo "🔗 Release URL: https://github.com/seven-gitt/sevenchat-desktop/releases/tag/v${VERSION}"
echo ""
echo "📋 Auto update sẽ hoạt động từ:"
echo "   https://github.com/seven-gitt/sevenchat-desktop/releases/latest/download/"
echo ""
echo "📝 Files uploaded:"
echo "   - $ZIP_FILE (auto update)"
echo "   - $DMG_FILE (manual install)"
echo "   - $RELEASES_JSON (update metadata)"
