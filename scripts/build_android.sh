#!/bin/bash
# ================================================================================
# Void Hunter - Android Build Script
# Godot 4.3 自动化Android构建脚本
# ================================================================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="Void Hunter"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
ANDROID_BUILD_DIR="${BUILD_DIR}/android"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BUILD_LOG="${BUILD_DIR}/logs/android_build_${TIMESTAMP}.log"

# Godot配置 (根据实际安装路径修改)
# macOS
GODOT_EDITOR="/Applications/Godot.app/Contents/MacOS/Godot"
# Linux
# GODOT_EDITOR="/usr/bin/godot"
# Windows (Git Bash)
# GODOT_EDITOR="/c/Program Files/Godot/Godot_v4.3-stable_win64.exe"

# Android SDK配置 (需要设置)
# 请根据实际安装路径修改
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
ANDROID_BUILD_TOOLS_VERSION="34.0.0"
ANDROID_PLATFORM="android-34"

# 签名配置 (发布版本需要)
KEYSTORE_PATH="${PROJECT_DIR}/export/android_template/void_hunter.keystore"
KEYSTORE_PASSWORD=""
KEY_ALIAS="void_hunter"
KEY_PASSWORD=""

# 构建配置
BUILD_TYPE="${1:-release}"  # release, debug, 或 aab
TARGET_ARCHS="arm64-v8a,armeabi-v7a"  # 目标架构
TARGET_SIZE_MB=100  # 目标大小（MB）
MIN_SDK_VERSION=26  # Android 8.0
TARGET_SDK_VERSION=34  # Android 14

# 版本信息
VERSION_CODE="${VERSION_CODE:-1}"
VERSION_NAME="${VERSION_NAME:-0.1.0}"

# ================================================================================
# 辅助函数
# ================================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$BUILD_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$BUILD_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$BUILD_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$BUILD_LOG"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
    echo "[STEP] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$BUILD_LOG"
}

check_dependencies() {
    log_info "检查依赖..."

    # 检查Godot编辑器
    if [ ! -f "$GODOT_EDITOR" ]; then
        if command -v godot4 &> /dev/null; then
            GODOT_EDITOR="godot4"
        elif command -v godot &> /dev/null; then
            GODOT_EDITOR="godot"
        else
            log_error "找不到Godot编辑器！"
            exit 1
        fi
    fi
    log_success "Godot编辑器: $GODOT_EDITOR"

    # 检查Android SDK
    if [ ! -d "$ANDROID_SDK_ROOT" ]; then
        # 尝试常见位置
        if [ -d "$HOME/Library/Android/sdk" ]; then
            ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
        elif [ -d "$HOME/Android/Sdk" ]; then
            ANDROID_SDK_ROOT="$HOME/Android/Sdk"
        else
            log_error "找不到Android SDK！"
            log_info "请设置 ANDROID_SDK_ROOT 环境变量"
            log_info "或安装Android Studio并下载SDK"
            exit 1
        fi
    fi
    log_success "Android SDK: $ANDROID_SDK_ROOT"

    # 检查Android Build Tools
    BUILD_TOOLS_DIR="${ANDROID_SDK_ROOT}/build-tools/${ANDROID_BUILD_TOOLS_VERSION}"
    if [ ! -d "$BUILD_TOOLS_DIR" ]; then
        log_warning "未找到Android Build Tools ${ANDROID_BUILD_TOOLS_VERSION}"
        log_info "安装命令: sdkmanager \"build-tools;${ANDROID_BUILD_TOOLS_VERSION}\""
    fi

    # 检查Android Platform
    PLATFORM_DIR="${ANDROID_SDK_ROOT}/platforms/${ANDROID_PLATFORM}"
    if [ ! -d "$PLATFORM_DIR" ]; then
        log_warning "未找到Android Platform ${ANDROID_PLATFORM}"
        log_info "安装命令: sdkmanager \"platforms;${ANDROID_PLATFORM}\""
    fi

    # 检查Java/JDK
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
        log_success "Java版本: $(java -version 2>&1 | head -n 1)"
    else
        log_error "未找到Java！请安装JDK 11或更高版本"
        exit 1
    fi

    # 检查keytool (用于签名)
    if ! command -v keytool &> /dev/null; then
        log_warning "未找到keytool，将无法创建签名密钥"
    fi

    # 检查zipalign和apksigner
    if [ -f "${BUILD_TOOLS_DIR}/zipalign" ]; then
        ZIPALIGN="${BUILD_TOOLS_DIR}/zipalign"
        log_success "找到zipalign"
    fi

    if [ -f "${BUILD_TOOLS_DIR}/apksigner" ]; then
        APKSIGNER="${BUILD_TOOLS_DIR}/apksigner"
        log_success "找到apksigner"
    fi
}

setup_directories() {
    log_info "设置构建目录..."

    mkdir -p "$BUILD_DIR"
    mkdir -p "$ANDROID_BUILD_DIR"
    mkdir -p "${BUILD_DIR}/logs"
    mkdir -p "${BUILD_DIR}/temp"
    mkdir -p "${ANDROID_BUILD_DIR}/apk"
    mkdir -p "${ANDROID_BUILD_DIR}/aab"

    log_success "构建目录已创建"
}

clean_build() {
    log_info "清理旧的构建文件..."

    if [ -d "$ANDROID_BUILD_DIR" ]; then
        rm -rf "${ANDROID_BUILD_DIR:?}"/*
        mkdir -p "${ANDROID_BUILD_DIR}/apk"
        mkdir -p "${ANDROID_BUILD_DIR}/aab"
    fi

    log_success "清理完成"
}

setup_keystore() {
    if [ "$BUILD_TYPE" = "release" ] || [ "$BUILD_TYPE" = "aab" ]; then
        log_info "检查签名密钥..."

        if [ ! -f "$KEYSTORE_PATH" ]; then
            log_warning "未找到签名密钥: $KEYSTORE_PATH"
            log_info "创建新的签名密钥..."

            # 提示用户输入信息
            read -p "请输入密钥库密码 (留空使用默认): " KEYSTORE_PASSWORD
            if [ -z "$KEYSTORE_PASSWORD" ]; then
                KEYSTORE_PASSWORD="void_hunter_2024"
            fi

            read -p "请输入密钥密码 (留空使用默认): " KEY_PASSWORD
            if [ -z "$KEY_PASSWORD" ]; then
                KEY_PASSWORD="void_hunter_2024"
            fi

            # 创建密钥库目录
            mkdir -p "$(dirname "$KEYSTORE_PATH")"

            # 生成密钥库
            keytool -genkeypair -v \
                -keystore "$KEYSTORE_PATH" \
                -alias "$KEY_ALIAS" \
                -keyalg RSA \
                -keysize 2048 \
                -validity 10000 \
                -storepass "$KEYSTORE_PASSWORD" \
                -keypass "$KEY_PASSWORD" \
                -dname "CN=Void Hunter, OU=Game Development, O=Void Hunter Team, L=Beijing, ST=Beijing, C=CN"

            log_success "签名密钥已创建: $KEYSTORE_PATH"
            log_warning "请妥善保管此密钥文件，丢失后将无法更新应用！"
        else
            log_success "找到签名密钥: $KEYSTORE_PATH"

            if [ -z "$KEYSTORE_PASSWORD" ]; then
                read -sp "请输入密钥库密码: " KEYSTORE_PASSWORD
                echo ""
            fi

            if [ -z "$KEY_PASSWORD" ]; then
                read -sp "请输入密钥密码: " KEY_PASSWORD
                echo ""
            fi
        fi
    fi
}

export_android() {
    log_step "开始Android导出 (${BUILD_TYPE})..."

    cd "$PROJECT_DIR"

    # 确定导出模式
    local export_flags=""
    local output_file=""

    case "$BUILD_TYPE" in
        debug)
            export_flags="--export-debug"
            output_file="${ANDROID_BUILD_DIR}/apk/void_hunter_debug.apk"
            ;;
        release)
            export_flags="--export-release"
            output_file="${ANDROID_BUILD_DIR}/apk/void_hunter_release_unsigned.apk"
            ;;
        aab)
            export_flags="--export-release"
            output_file="${ANDROID_BUILD_DIR}/aab/void_hunter.aab"
            ;;
        *)
            log_error "未知的构建类型: $BUILD_TYPE"
            exit 1
            ;;
    esac

    # 设置环境变量
    export ANDROID_SDK_ROOT
    export ANDROID_HOME="$ANDROID_SDK_ROOT"

    # 执行导出
    log_info "执行Godot导出命令..."

    "$GODOT_EDITOR" --headless --quit-after 100 \
        $export_flags "Android" "$output_file" \
        2>&1 | tee -a "$BUILD_LOG"

    # 检查导出是否成功
    if [ -f "$output_file" ]; then
        log_success "Android导出完成: $output_file"
    else
        log_error "Android导出失败！"
        exit 1
    fi

    EXPORTED_FILE="$output_file"
}

sign_apk() {
    if [ "$BUILD_TYPE" = "release" ]; then
        log_step "签名APK..."

        UNSIGNED_APK="${ANDROID_BUILD_DIR}/apk/void_hunter_release_unsigned.apk"
        ALIGNED_APK="${ANDROID_BUILD_DIR}/apk/void_hunter_aligned.apk"
        SIGNED_APK="${ANDROID_BUILD_DIR}/apk/void_hunter_release.apk"

        # Zipalign
        if [ -f "$ZIPALIGN" ]; then
            log_info "执行zipalign优化..."
            "$ZIPALIGN" -v -p 4 "$UNSIGNED_APK" "$ALIGNED_APK"
            log_success "Zipalign完成"
        else
            log_warning "跳过zipalign (未找到工具)"
            ALIGNED_APK="$UNSIGNED_APK"
        fi

        # 签名
        if [ -f "$APKSIGNER" ] && [ -f "$KEYSTORE_PATH" ]; then
            log_info "执行APK签名..."
            "$APKSIGNER" sign \
                --ks "$KEYSTORE_PATH" \
                --ks-key-alias "$KEY_ALIAS" \
                --ks-pass "pass:$KEYSTORE_PASSWORD" \
                --key-pass "pass:$KEY_PASSWORD" \
                --out "$SIGNED_APK" \
                "$ALIGNED_APK"

            log_success "APK签名完成"

            # 验证签名
            log_info "验证APK签名..."
            "$APKSIGNER" verify -v "$SIGNED_APK"
            log_success "签名验证通过"

            # 删除临时文件
            rm -f "$UNSIGNED_APK" "$ALIGNED_APK"

            EXPORTED_FILE="$SIGNED_APK"
        else
            log_warning "跳过签名 (未找到apksigner或密钥库)"
            mv "$ALIGNED_APK" "${ANDROID_BUILD_DIR}/apk/void_hunter_release.apk"
            EXPORTED_FILE="${ANDROID_BUILD_DIR}/apk/void_hunter_release.apk"
        fi
    fi
}

optimize_build() {
    log_step "优化构建..."

    local build_file="$EXPORTED_FILE"

    if [ -f "$build_file" ]; then
        # 获取文件大小
        FILE_SIZE=$(du -m "$build_file" | cut -f1)
        log_info "构建文件大小: ${FILE_SIZE}MB"

        if [ "$FILE_SIZE" -gt "$TARGET_SIZE_MB" ]; then
            log_warning "构建大小超过目标 (${TARGET_SIZE_MB}MB)"
            log_warning "考虑以下优化措施："
            log_warning "  - 减少纹理分辨率"
            log_warning "  - 使用ASTC/ETC2纹理压缩"
            log_warning "  - 优化音频文件"
            log_warning "  - 移除未使用的资源"
            log_warning "  - 只保留必要的CPU架构"
        else
            log_success "构建大小符合目标 (<${TARGET_SIZE_MB}MB)"
        fi

        # 分析APK内容
        if command -v unzip &> /dev/null; then
            log_info "APK内容概览:"
            unzip -l "$build_file" | head -30
        fi
    fi
}

generate_build_info() {
    log_info "生成构建信息..."

    BUILD_INFO_FILE="${ANDROID_BUILD_DIR}/build_info.json"

    cat > "$BUILD_INFO_FILE" << EOF
{
    "project": "$PROJECT_NAME",
    "version": {
        "code": $VERSION_CODE,
        "name": "$VERSION_NAME"
    },
    "build_type": "$BUILD_TYPE",
    "build_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "platform": "android",
    "android": {
        "min_sdk": $MIN_SDK_VERSION,
        "target_sdk": $TARGET_SDK_VERSION,
        "architectures": "$TARGET_ARCHS"
    },
    "godot_version": "$($GODOT_EDITOR --version 2>/dev/null || echo 'unknown')",
    "git_commit": "$(cd "$PROJECT_DIR" && git rev-parse HEAD 2>/dev/null || echo 'unknown')",
    "git_branch": "$(cd "$PROJECT_DIR" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
}
EOF

    log_success "构建信息已生成: $BUILD_INFO_FILE"
}

install_on_device() {
    if [ "$BUILD_TYPE" = "debug" ]; then
        log_info "检查连接的设备..."

        if command -v adb &> /dev/null; then
            DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l)

            if [ "$DEVICES" -gt 0 ]; then
                log_info "发现 $DEVICES 个设备"
                adb devices

                read -p "是否安装到设备? (y/n): " INSTALL_CHOICE

                if [ "$INSTALL_CHOICE" = "y" ] || [ "$INSTALL_CHOICE" = "Y" ]; then
                    log_info "安装APK到设备..."
                    adb install -r "$EXPORTED_FILE"
                    log_success "安装完成"

                    read -p "是否启动应用? (y/n): " LAUNCH_CHOICE

                    if [ "$LAUNCH_CHOICE" = "y" ] || [ "$LAUNCH_CHOICE" = "Y" ]; then
                        log_info "启动应用..."
                        adb shell am start -n com.voidhunter.game/com.godot.game.GodotApp
                    fi
                fi
            else
                log_info "未发现连接的设备"
                log_info "请确保："
                log_info "  1. 设备已通过USB连接"
                log_info "  2. 设备已启用USB调试"
                log_info "  3. 已授权此电脑进行调试"
            fi
        else
            log_warning "未找到adb工具"
        fi
    fi
}

# ================================================================================
# 主流程
# ================================================================================

main() {
    echo ""
    echo "========================================"
    echo "  $PROJECT_NAME - Android Build Script"
    echo "========================================"
    echo ""

    # 初始化日志
    mkdir -p "${BUILD_DIR}/logs"
    echo "Build started at $(date)" > "$BUILD_LOG"

    # 执行构建步骤
    check_dependencies
    setup_directories
    clean_build
    setup_keystore
    export_android

    if [ "$BUILD_TYPE" = "release" ]; then
        sign_apk
    fi

    optimize_build
    generate_build_info
    install_on_device

    # 构建完成
    echo ""
    echo "========================================"
    log_success "构建完成！"
    echo "========================================"
    echo ""
    echo "输出文件: $EXPORTED_FILE"
    echo "构建日志: $BUILD_LOG"
    echo ""

    # 显示最终文件
    log_info "构建文件:"
    if [ "$BUILD_TYPE" = "aab" ]; then
        ls -lh "${ANDROID_BUILD_DIR}/aab/"
    else
        ls -lh "${ANDROID_BUILD_DIR}/apk/"
    fi

    echo ""
    log_info "后续步骤:"
    case "$BUILD_TYPE" in
        debug)
            echo "  - 使用 adb install 安装到设备"
            echo "  - 上传到内部测试平台"
            ;;
        release)
            echo "  - 上传到Google Play Console"
            echo "  - 上传到其他应用商店"
            echo "  - 分发给测试用户"
            ;;
        aab)
            echo "  - 上传到Google Play Console"
            echo "  - AAB是Google Play要求的格式"
            ;;
    esac
    echo ""
}

# 运行主函数
main "$@"
