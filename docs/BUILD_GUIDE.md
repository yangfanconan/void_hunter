# Void Hunter - 构建指南

**版本**: 1.0.0
**作者**: Void Hunter Team
**最后更新**: 2024

---

## 目录

1. [Godot安装](#1-godot安装)
2. [导出模板配置](#2-导出模板配置)
3. [WebGL构建步骤](#3-webgl构建步骤)
4. [Android构建步骤](#4-android构建步骤)
5. [iOS构建步骤](#5-ios构建步骤)
6. [桌面平台构建](#6-桌面平台构建)
7. [签名和发布](#7-签名和发布)
8. [自动化构建](#8-自动化构建)

---

## 1. Godot安装

### 1.1 下载 Godot

访问 [Godot 官方下载页面](https://godotengine.org/download)：

| 平台 | 文件 | 说明 |
|------|------|------|
| Windows | `Godot_v4.x.x_stable_win64.exe` | 标准版 |
| macOS | `Godot_v4.x.x_stable_macos.universal.zip` | Universal Binary |
| Linux | `Godot_v4.x.x_stable_linux.x86_64.zip` | 需添加执行权限 |

### 1.2 安装步骤

#### Windows

```powershell
# 下载后直接运行，或解压到指定目录
# 建议添加到 PATH 环境变量
```

#### macOS

```bash
# 解压
unzip Godot_v4.x.x_stable_macos.universal.zip

# 移动到应用程序目录
mv Godot.app /Applications/

# 首次运行可能需要允许未知开发者
# 系统偏好设置 > 安全性与隐私 > 允许
```

#### Linux

```bash
# 解压
unzip Godot_v4.x.x_stable_linux.x86_64.zip

# 添加执行权限
chmod +x Godot_v4.x.x_stable_linux.x86_64

# 移动到合适位置
sudo mv Godot_v4.x.x_stable_linux.x86_64 /usr/local/bin/godot

# 或者创建桌面快捷方式
```

### 1.3 验证安装

```bash
# 检查版本
godot --version
# 或
godot4 --version

# 输出应该类似于:
# 4.2.1.stable.official
```

---

## 2. 导出模板配置

### 2.1 下载导出模板

1. 打开 Godot 编辑器
2. 进入 `Editor > Manage Export Templates`
3. 点击 "Download and Install"
4. 选择对应版本（与编辑器版本一致）

### 2.2 命令行下载

```bash
# 使用 Godot 命令行下载模板
godot --install-export-templates

# 或手动下载后放置到:
# Windows: %APPDATA%\Godot\export_templates\4.x.x.stable\
# macOS: ~/Library/Application Support/Godot/export_templates/4.x.x.stable/
# Linux: ~/.local/share/godot/export_templates/4.x.x.stable/
```

### 2.3 验证模板安装

```
已安装的模板应该包含:
├── 4.x.x.stable/
│   ├── android_release.apk
│   ├── android_debug.apk
│   ├── web_release.zip
│   ├── web_debug.zip
│   ├── linux_release.x86_64
│   ├── linux_debug.x86_64
│   ├── macos_release.zip
│   ├── macos_debug.zip
│   ├── windows_release_64.exe
│   └── windows_debug_64.exe
```

---

## 3. WebGL构建步骤

### 3.1 配置 WebGL 导出

1. 打开项目，进入 `Project > Export`
2. 点击 "Add" 选择 "Web"
3. 配置导出选项：

| 选项 | 推荐值 | 说明 |
|------|--------|------|
| Export Type | Release | 发布版本 |
| VRAM Texture Compression | For Desktop | 桌面浏览器 |
| HTML Shell File | 默认 | 可自定义页面 |
| Head Include | 按需 | 自定义头部内容 |

### 3.2 导出设置

```gdscript
# project.godot 中的相关配置
[rendering]

renderer/rendering_method="forward_plus"  # 或 "mobile" 以获得更好的兼容性
anti_aliasing/quality/msaa_2d=2
anti_aliasing/quality/msaa_3d=2

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/size/mode=2
window/size/resizable=true
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

### 3.3 执行导出

#### 使用编辑器

1. `Project > Export`
2. 选择 Web 预设
3. 点击 "Export Project"
4. 选择输出目录
5. 等待导出完成

#### 使用命令行

```bash
# 导出 WebGL 版本
godot --headless --export-release "Web" ./build/web/

# 输出文件:
# build/web/
# ├── index.html
# ├── index.js
# ├── index.wasm
# ├── index.pck
# └── *.png (图标等资源)
```

### 3.4 测试 WebGL 构建

```bash
# 需要使用 HTTP 服务器，不能直接打开 HTML 文件

# 使用 Python
cd build/web
python -m http.server 8000
# 访问 http://localhost:8000

# 使用 Node.js (需要安装 http-server)
npx http-server build/web -p 8000

# 使用 Godot 内置服务器
godot --path . --server 8000
```

### 3.5 WebGL 优化

```gdscript
# 针对 WebGL 的优化配置

[rendering]

# 使用移动渲染器提高兼容性
renderer/rendering_method="mobile"

# 减少内存使用
textures/vram_compression/import_etc2_astc=true

# 限制最大纹理大小
textures/default_texture_filter=1

[display]

# 启用触摸支持
input_devices/pointing/emulate_touch_from_mouse=true
```

---

## 4. Android构建步骤

### 4.1 环境准备

#### 安装 JDK

```bash
# 推荐使用 JDK 17
# Windows: 下载并安装 Oracle JDK 或 OpenJDK
# macOS:
brew install openjdk@17

# Linux (Ubuntu):
sudo apt install openjdk-17-jdk

# 验证安装
java -version
# 应显示: openjdk version "17.x.x"
```

#### 安装 Android SDK

1. 下载 [Android Studio](https://developer.android.com/studio)
2. 安装并运行 Android Studio
3. 进入 `Tools > SDK Manager`
4. 安装:
   - Android SDK Platform 33 (或更高)
   - Android SDK Build-Tools 33
   - Android SDK Command-line Tools
   - NDK (Side by side) - 选择最新版本
   - CMake

#### 配置环境变量

```bash
# ~/.bashrc 或 ~/.zshrc

# Android SDK 路径
export ANDROID_HOME=$HOME/Android/Sdk  # Linux
# export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
# export ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk  # Windows

export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/build-tools/33.0.0
```

### 4.2 Godot Android 配置

1. 打开 `Editor > Editor Settings > Export > Android`
2. 配置以下路径：

| 设置 | 值 |
|------|-----|
| Android SDK Path | `/path/to/Android/Sdk` |
| Debug Keystore | (自动生成或自定义) |
| Debug Keystore User | `androiddebugkey` |
| Debug Keystore Password | `android` |

### 4.3 创建导出预设

1. `Project > Export > Add > Android`
2. 配置主要选项：

| 选项 | 推荐值 | 说明 |
|------|--------|------|
| Package Name | `com.yourcompany.voidhunter` | 反向域名格式 |
| Version Code | 1 | 递增的整数 |
| Version Name | `1.0.0` | 显示版本号 |
| Minimum SDK | 21 | Android 5.0 |
| Target SDK | 33 | Android 13 |
| Architectures | arm64-v8a, armeabi-v7a | 支持的CPU架构 |
| Keystore | (发布时配置) | 签名密钥库 |

### 4.4 配置权限

```gdscript
# project.godot
[android]

permissions/internet=true
permissions/access_network_state=true
permissions/vibrate=true
```

### 4.5 执行导出

```bash
# 导出 Debug APK
godot --headless --export-debug "Android" ./build/android/void_hunter_debug.apk

# 导出 Release APK (需要签名)
godot --headless --export-release "Android" ./build/android/void_hunter_release.apk

# 导出 AAB (Google Play 格式)
godot --headless --export-release "Android AAB" ./build/android/void_hunter.aab
```

### 4.6 测试 APK

```bash
# 安装到连接的设备
adb install ./build/android/void_hunter_debug.apk

# 查看日志
adb logcat -s godot

# 卸载
adb uninstall com.yourcompany.voidhunter
```

---

## 5. iOS构建步骤

### 5.1 环境要求

- macOS 操作系统
- Xcode 14.0 或更高版本
- Apple Developer 账户 (发布需要)

### 5.2 安装 Xcode

```bash
# 从 App Store 安装 Xcode
# 或使用 xcode-select
xcode-select --install

# 接受许可协议
sudo xcodebuild -license accept
```

### 5.3 配置 iOS 导出

1. `Project > Export > Add > iOS`
2. 配置选项：

| 选项 | 值 | 说明 |
|------|-----|------|
| Bundle Identifier | `com.yourcompany.voidhunter` | 应用标识 |
| Version | `1.0.0` | 显示版本 |
| Build Number | 1 | 递增整数 |
| Team ID | (从开发者账户获取) | Apple Team ID |
| Orientation | Landscape | 横屏游戏 |

### 5.4 执行导出

```bash
# 导出 Xcode 项目
godot --headless --export-release "iOS" ./build/ios/

# 这会生成一个 Xcode 项目
# build/ios/
# ├── VoidHunter.xcodeproj
# └── VoidHunter/
```

### 5.5 使用 Xcode 构建

1. 打开生成的 `.xcodeproj` 文件
2. 选择目标设备或 "Any iOS Device"
3. 配置签名证书
4. `Product > Archive` 创建归档
5. `Window > Organizer` 分发应用

---

## 6. 桌面平台构建

### 6.1 Windows

#### 配置

```gdscript
# project.godot
[application]

config/name="Void Hunter"
config/description="A roguelike survivor game"
config/version="1.0.0"

[windows]

# 启用高DPI支持
dpi_aware=true
# 控制台窗口 (调试时可启用)
console_wrapper=false
```

#### 导出

```bash
# 导出 Windows 版本
godot --headless --export-release "Windows Desktop" ./build/windows/void_hunter.exe

# 输出:
# build/windows/
# ├── void_hunter.exe
# ├── void_hunter.pck
# └── (可选) .console.exe (调试版本)
```

### 6.2 macOS

#### 配置

```gdscript
# project.godot
[application]

# macOS 特定配置
config/macos_native_icon="res://icon.icns"

[macos]

# 应用类别
export/category="public.app-category.games"
# 签名信息
codesign/identity=""
notarization/notarization=false
```

#### 导出

```bash
# 导出 macOS 应用
godot --headless --export-release "macOS" ./build/macos/void_hunter.dmg

# 或导出 .app
godot --headless --export-release "macOS" ./build/macos/VoidHunter.app
```

#### 代码签名 (发布)

```bash
# 签名应用
codesign --force --deep --sign "Developer ID Application: Your Name" VoidHunter.app

# 验证签名
codesign --verify --deep --strict VoidHunter.app

# 公证 (需要 Apple Developer)
xcrun notarytool submit VoidHunter.zip --apple-id your@email.com --password app-specific-password --team-id TEAMID
```

### 6.3 Linux

#### 配置

```gdscript
# project.godot
[linux]

# 图标
export/icon="res://icon.png"
```

#### 导出

```bash
# 导出 Linux 版本
godot --headless --export-release "Linux/X11" ./build/linux/void_hunter

# 添加执行权限
chmod +x ./build/linux/void_hunter

# 创建 .desktop 文件 (可选)
cat > void_hunter.desktop << EOF
[Desktop Entry]
Name=Void Hunter
Exec=/path/to/void_hunter
Icon=/path/to/icon.png
Type=Application
Categories=Game;
EOF
```

---

## 7. 签名和发布

### 7.1 Android 签名

#### 创建密钥库

```bash
keytool -keyalg RSA -genkeypair -alias void_hunter \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -keystore void_hunter.keystore \
    -storepass YOUR_STORE_PASSWORD \
    -keypass YOUR_KEY_PASSWORD

# 输入信息:
# CN=Your Name, OU=Your Organization, O=Your Company,
# L=Your City, ST=Your State, C=Your Country
```

#### 配置签名

```gdscript
# 在 Godot 导出预设中配置
# Project > Export > Android > Keystore

Keystore: /path/to/void_hunter.keystore
Keystore Password: YOUR_STORE_PASSWORD
Key Alias: void_hunter
Key Password: YOUR_KEY_PASSWORD
```

### 7.2 iOS 签名

1. 在 [Apple Developer](https://developer.apple.com) 创建:
   - App ID
   - Development/Distribution Certificate
   - Provisioning Profile

2. 在 Xcode 中配置:
   - 选择 Team
   - 选择 Provisioning Profile
   - 配置 Capabilities

### 7.3 代码签名验证

#### Android

```bash
# 验证 APK 签名
apksigner verify --print-certs void_hunter_release.apk

# 查看 APK 信息
aapt dump badging void_hunter_release.apk
```

#### iOS

```bash
# 验证 IPA 签名
codesign -dvvv VoidHunter.app
```

### 7.4 发布检查清单

- [ ] 版本号已更新
- [ ] 移除调试代码
- [ ] 配置正确的签名
- [ ] 测试所有功能
- [ ] 检查权限配置
- [ ] 验证应用图标
- [ ] 准备商店截图和描述

---

## 8. 自动化构建

### 8.1 GitHub Actions

创建 `.github/workflows/build.yml`：

```yaml
name: Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.2.1
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup
      run: |
        mkdir -v -p ~/.local/share/godot/export_templates
        mv /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable
      env:
        GODOT_VERSION: 4.2.1
    
    - name: Build WebGL
      run: |
        mkdir -p build/web
        godot --headless --export-release "Web" build/web/index.html
    
    - name: Build Windows
      run: |
        mkdir -p build/windows
        godot --headless --export-release "Windows Desktop" build/windows/void_hunter.exe
    
    - name: Build Linux
      run: |
        mkdir -p build/linux
        godot --headless --export-release "Linux/X11" build/linux/void_hunter
        chmod +x build/linux/void_hunter
    
    - name: Upload Artifacts
      uses: actions/upload-artifact@v4
      with:
        name: builds
        path: build/

  deploy-web:
    needs: build
    runs-on: ubuntu-latest
    steps:
    - uses: actions/download-artifact@v4
      with:
        name: builds
        path: build/
    
    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./build/web
```

### 8.2 构建脚本

创建 `scripts/build.sh`：

```bash
#!/bin/bash

# Void Hunter 构建脚本

VERSION=$(cat VERSION)
BUILD_DIR="./build"
GODOT_CMD="godot"

echo "=== Void Hunter Build Script ==="
echo "Version: $VERSION"
echo "Build Directory: $BUILD_DIR"

# 清理旧构建
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# 构建 WebGL
echo "Building WebGL..."
mkdir -p $BUILD_DIR/web
$GODOT_CMD --headless --export-release "Web" $BUILD_DIR/web/index.html

# 构建 Windows
echo "Building Windows..."
mkdir -p $BUILD_DIR/windows
$GODOT_CMD --headless --export-release "Windows Desktop" $BUILD_DIR/windows/void_hunter.exe

# 构建 Linux
echo "Building Linux..."
mkdir -p $BUILD_DIR/linux
$GODOT_CMD --headless --export-release "Linux/X11" $BUILD_DIR/linux/void_hunter
chmod +x $BUILD_DIR/linux/void_hunter

# 构建 macOS
echo "Building macOS..."
mkdir -p $BUILD_DIR/macos
$GODOT_CMD --headless --export-release "macOS" $BUILD_DIR/macos/VoidHunter.app

# 打包
echo "Creating archives..."
cd $BUILD_DIR
zip -r void_hunter_web_v$VERSION.zip web/
zip -r void_hunter_windows_v$VERSION.zip windows/
zip -r void_hunter_linux_v$VERSION.zip linux/
zip -r void_hunter_macos_v$VERSION.zip macos/

echo "=== Build Complete ==="
echo "Artifacts in: $BUILD_DIR"
ls -la $BUILD_DIR/*.zip
```

### 8.3 版本管理

创建 `VERSION` 文件：

```
1.0.0
```

在 `project.godot` 中引用：

```gdscript
[application]

config/version="1.0.0"
```

自动化版本更新脚本：

```bash
#!/bin/bash
# scripts/bump_version.sh

NEW_VERSION=$1
CURRENT_VERSION=$(cat VERSION)

# 更新 VERSION 文件
echo $NEW_VERSION > VERSION

# 更新 project.godot
sed -i "s/config\/version=\"$CURRENT_VERSION\"/config\/version=\"$NEW_VERSION\"/" project.godot

echo "Version bumped: $CURRENT_VERSION -> $NEW_VERSION"
```

---

## 附录

### A. 常见问题

**Q: 导出时提示缺少模板？**
A: 确保已下载对应版本的导出模板。

**Q: Android 构建失败？**
A: 检查 ANDROID_HOME 环境变量和 SDK 路径配置。

**Q: WebGL 运行缓慢？**
A: 尝试使用 Mobile 渲染器，减少纹理大小。

**Q: iOS 签名失败？**
A: 确保 Provisioning Profile 包含正确的 App ID。

### B. 构建产物大小优化

| 优化项 | 方法 | 预期效果 |
|--------|------|----------|
| 纹理压缩 | 启用 VRAM 压缩 | 减少 50-70% |
| 音频压缩 | 使用 OGG 格式 | 减少 60-80% |
| 移除未使用资源 | 检查 Orphan 资源 | 减少冗余 |
| 3D 优化 | 简化网格 | 按需 |

### C. 性能测试

```bash
# 使用 Godot 内置分析器
godot --profile

# WebGL 性能测试
# Chrome DevTools > Performance
```
