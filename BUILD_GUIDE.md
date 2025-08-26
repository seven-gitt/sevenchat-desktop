# Hướng dẫn Build SevenChat với Auto Update

## Yêu cầu hệ thống

### 1. Cài đặt công cụ cần thiết

```bash
# Xcode Command Line Tools
xcode-select --install

# Homebrew (nếu chưa có)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# GitHub CLI
brew install gh

# Node.js (version 18+)
brew install node

# Yarn
npm install -g yarn
```

### 2. Apple Developer Account

- Cần Apple Developer Program ($99/năm)
- Hoặc Apple Developer Free (có giới hạn)

## Cấu hình môi trường

### 1. Tạo App-specific Password

1. Truy cập https://appleid.apple.com/account/manage
2. Đăng nhập với Apple ID
3. Vào phần "App-specific passwords"
4. Tạo password mới cho "SevenChat Build"
5. Lưu password này (sẽ dùng 1 lần)

### 2. Cập nhật file env.build

```bash
# Mở file env.build và cập nhật thông tin
nano env.build
```

Cập nhật các thông tin sau:

```bash
# Apple ID email (không phải Apple Developer ID)
APPLE_ID=your-apple-id@example.com

# App-specific password vừa tạo
APPLE_APP_SPECIFIC_PASSWORD=your-app-specific-password

# Team ID (đã có sẵn từ certificate)
APPLE_TEAM_ID=C828KUUV54
```

### 3. Đăng nhập GitHub CLI

```bash
gh auth login
# Chọn GitHub.com
# Chọn HTTPS
# Chọn Yes để authenticate Git operations
# Chọn Login with a web browser
# Copy code và paste vào browser
```

## Build và Release

### 1. Build ứng dụng

```bash
# Build với version hiện tại
./scripts/build-macos.sh

# Hoặc build với version cụ thể
./scripts/build-macos.sh 1.1.6
```

Script sẽ:
- Cài đặt dependencies
- Build TypeScript
- Build native modules (universal)
- Ký và notarize ứng dụng
- Tạo file .zip và .dmg
- Tạo file releases.json cho auto update

### 2. Tạo GitHub Release

```bash
# Tạo release với version hiện tại
./scripts/create-release.sh

# Hoặc với version và notes cụ thể
./scripts/create-release.sh 1.1.6 "Sửa lỗi crash và cải tiến UI"
```

Script sẽ:
- Tạo GitHub Release với tag
- Upload file .zip, .dmg và releases.json
- Tạo release notes tự động

## Cấu trúc Auto Update

### 1. URL cấu hình

App đã được cấu hình sẵn trong `config.json`:
```json
{
  "update_base_url": "https://github.com/seven-gitt/sevenchat-desktop/releases/latest/download/"
}
```

### 2. File releases.json

File này được tạo tự động với format:
```json
{
  "currentRelease": "1.1.6",
  "name": "1.1.6", 
  "url": "https://github.com/seven-gitt/sevenchat-desktop/releases/download/v1.1.6/SevenChat-1.1.6-mac.zip",
  "notes": "SevenChat 1.1.6 - Cải tiến và sửa lỗi.",
  "pub_date": "2024-12-25T10:30:00Z"
}
```

### 3. Luồng hoạt động

1. App khởi động → đọc `update_base_url`
2. Mỗi giờ → check update từ URL + `/releases.json`
3. So sánh version → tải .zip nếu có version mới
4. Hiển thị thông báo → user bấm "Restart" để cài đặt

## Troubleshooting

### Lỗi ký ứng dụng

```bash
# Kiểm tra certificates
security find-identity -v -p codesigning

# Kiểm tra team ID
security find-identity -v -p codesigning | grep "Apple Distribution"
```

### Lỗi notarization

```bash
# Kiểm tra notarization status
xcrun notarytool info --apple-id $APPLE_ID --password $APPLE_APP_SPECIFIC_PASSWORD [submission-id]

# Logs chi tiết
xcrun notarytool log --apple-id $APPLE_ID --password $APPLE_APP_SPECIFIC_PASSWORD [submission-id]
```

### Lỗi GitHub CLI

```bash
# Kiểm tra auth status
gh auth status

# Re-login nếu cần
gh auth logout
gh auth login
```

### Lỗi build

```bash
# Clean và rebuild
rm -rf node_modules dist lib
yarn install
./scripts/build-macos.sh
```

## Cập nhật version

### 1. Cập nhật package.json

```bash
# Tăng version
npm version patch  # 1.1.5 -> 1.1.6
npm version minor  # 1.1.5 -> 1.2.0  
npm version major  # 1.1.5 -> 2.0.0
```

### 2. Build và release

```bash
./scripts/build-macos.sh
./scripts/create-release.sh
```

## Lưu ý quan trọng

1. **App-specific password**: Không phải password Apple ID thông thường
2. **Team ID**: Đã có sẵn từ certificate, không cần thay đổi
3. **Universal build**: Tự động build cho Intel + Apple Silicon
4. **Auto update**: Chỉ hoạt động trên macOS và Windows
5. **Notarization**: Cần thiết để macOS cho phép chạy app từ internet

## Kiểm tra Auto Update

1. Cài đặt app từ .dmg
2. Mở app và kiểm tra log:
   ```
   Starting auto update with base URL: https://github.com/seven-gitt/sevenchat-desktop/releases/latest/download/
   Update URL: https://github.com/seven-gitt/sevenchat-desktop/releases/latest/download/releases.json
   ```
3. Tạo release mới với version cao hơn
4. App sẽ tự động phát hiện và tải update
