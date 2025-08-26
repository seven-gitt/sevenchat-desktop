#!/bin/bash

# Script build macOS với auto update support
# Sử dụng: ./scripts/build-macos.sh [version]

set -e

# Đọc version từ argument hoặc package.json
VERSION=${1:-$(node -p "require('./package.json').version")}
echo "Building SevenChat version: $VERSION"

# Load environment variables
if [ -f "env.build" ]; then
    echo "Loading environment variables from env.build..."
    export $(cat env.build | grep -v '^#' | xargs)
fi

# Kiểm tra các biến môi trường cần thiết
if [ -z "$APPLE_ID" ] || [ "$APPLE_ID" = "your-apple-id@example.com" ]; then
    echo "❌ Error: Vui lòng cập nhật APPLE_ID trong file env.build"
    exit 1
fi

if [ -z "$APPLE_APP_SPECIFIC_PASSWORD" ] || [ "$APPLE_APP_SPECIFIC_PASSWORD" = "your-app-specific-password" ]; then
    echo "❌ Error: Vui lòng cập nhật APPLE_APP_SPECIFIC_PASSWORD trong file env.build"
    exit 1
fi

echo "✅ Environment variables loaded successfully"
echo "Apple Team ID: $APPLE_TEAM_ID"
echo "Apple ID: $APPLE_ID"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf dist/ node_modules/ lib/

# Install dependencies
echo "📦 Installing dependencies..."
yarn install --frozen-lockfile

# Build TypeScript
echo "🔨 Building TypeScript..."
yarn run build:ts

# Build resources
echo "📁 Building resources..."
yarn run build:res

# Build native modules
echo "🔧 Building native modules..."
yarn run build:native:universal

# Build macOS app
echo "🍎 Building macOS app..."
yarn run build:universal --publish=never

# Kiểm tra file output
ZIP_FILE="dist/SevenChat-${VERSION}-mac.zip"
DMG_FILE="dist/SevenChat-${VERSION}-mac.dmg"

if [ -f "$ZIP_FILE" ]; then
    echo "✅ Build completed successfully!"
    echo "📦 ZIP file: $ZIP_FILE"
    echo "💾 DMG file: $DMG_FILE"
    
    # Tạo releases.json cho auto update
    echo "📝 Creating releases.json for auto update..."
    cat > dist/releases.json <<EOF
{
  "currentRelease": "${VERSION}",
  "name": "${VERSION}",
  "url": "https://github.com/seven-gitt/sevenchat-desktop/releases/download/v${VERSION}/SevenChat-${VERSION}-mac.zip",
  "notes": "SevenChat ${VERSION} - Cải tiến và sửa lỗi.",
  "pub_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    echo "📋 Files ready for GitHub Release:"
    echo "   - $ZIP_FILE (cho auto update)"
    echo "   - $DMG_FILE (cho manual install)"
    echo "   - dist/releases.json (cho auto update)"
    
    echo ""
    echo "🚀 Next steps:"
    echo "1. Tạo GitHub Release với tag v${VERSION}"
    echo "2. Upload $ZIP_FILE và dist/releases.json vào Release"
    echo "3. App sẽ tự động check update từ: https://github.com/seven-gitt/sevenchat-desktop/releases/latest/download/"
    
else
    echo "❌ Build failed! File $ZIP_FILE not found."
    exit 1
fi
