#!/bin/bash
# ================================================================================
# Void Hunter - Build All Platforms
# 一键构建所有平台的脚本
# ================================================================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="Void Hunter"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MAIN_LOG="${BUILD_DIR}/logs/build_all_${TIMESTAMP}.log"

# 构建选项
BUILD_WEBGL=true
BUILD_ANDROID=true
BUILD_WINDOWS=false  # 默认关闭，跨平台需要特定环境
BUILD_LINUX=false
BUILD_MACOS=false
CLEAN_BUILD=false
BUILD_TYPE="release"

# ================================================================================
# 辅助函数
# ================================================================================

log_header() {
    echo ""
    echo -e "${MAGENTA}========================================${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}========================================${NC}"
    echo ""
    echo "========================================" >> "$MAIN_LOG"
    echo "  $1" >> "$MAIN_LOG"
    echo "========================================" >> "$MAIN_LOG"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$MAIN_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$MAIN_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$MAIN_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$MAIN_LOG"
}

show_help() {
    echo ""
    echo "Void Hunter - Build All Platforms"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --webgl         构建 WebGL 版本"
    echo "  --android       构建 Android 版本"
    echo "  --windows       构建 Windows 版本"
    echo "  --linux         构建 Linux 版本"
    echo "  --macos         构建 macOS 版本"
    echo "  --all           构建所有平台"
    echo "  --clean         构建前清理"
    echo "  --debug         Debug 构建"
    echo "  --release       Release 构建（默认）"
    echo "  --help          显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --webgl --android        # 构建 WebGL 和 Android"
    echo "  $0 --all --release          # Release 构建所有平台"
    echo "  $0 --webgl --clean --debug  # Debug 构建 WebGL，先清理"
    echo ""
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --webgl)
                BUILD_WEBGL=true
                shift
                ;;
            --android)
                BUILD_ANDROID=true
                shift
                ;;
            --windows)
                BUILD_WINDOWS=true
                shift
                ;;
            --linux)
                BUILD_LINUX=true
                shift
                ;;
            --macos)
                BUILD_MACOS=true
                shift
                ;;
            --all)
                BUILD_WEBGL=true
                BUILD_ANDROID=true
                BUILD_WINDOWS=true
                BUILD_LINUX=true
                BUILD_MACOS=true
                shift
                ;;
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --debug)
                BUILD_TYPE="debug"
                shift
                ;;
            --release)
                BUILD_TYPE="release"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

setup_directories() {
    log_info "设置构建目录..."

    mkdir -p "$BUILD_DIR"
    mkdir -p "${BUILD_DIR}/logs"
    mkdir -p "${BUILD_DIR}/webgl"
    mkdir -p "${BUILD_DIR}/android"
    mkdir -p "${BUILD_DIR}/windows"
    mkdir -p "${BUILD_DIR}/linux"
    mkdir -p "${BUILD_DIR}/macos"
    mkdir -p "${BUILD_DIR}/temp"

    log_success "构建目录已创建"
}

clean_all_builds() {
    if [ "$CLEAN_BUILD" = true ]; then
        log_info "清理所有构建文件..."

        rm -rf "${BUILD_DIR}/webgl"/*
        rm -rf "${BUILD_DIR}/android"/*
        rm -rf "${BUILD_DIR}/windows"/*
        rm -rf "${BUILD_DIR}/linux"/*
        rm -rf "${BUILD_DIR}/macos"/*
        rm -rf "${BUILD_DIR}/temp"/*

        log_success "清理完成"
    fi
}

build_webgl() {
    if [ "$BUILD_WEBGL" = true ]; then
        log_header "构建 WebGL 版本"

        local start_time=$(date +%s)

        if [ -f "${PROJECT_DIR}/scripts/build_webgl.sh" ]; then
            cd "$PROJECT_DIR"
            bash scripts/build_webgl.sh "$BUILD_TYPE" 2>&1 | tee -a "$MAIN_LOG"

            local end_time=$(date +%s)
            local duration=$((end_time - start_time))

            if [ -d "${BUILD_DIR}/webgl" ] && [ "$(ls -A ${BUILD_DIR}/webgl 2>/dev/null)" ]; then
                log_success "WebGL 构建完成 (耗时: ${duration}秒)"

                # 显示构建大小
                local size=$(du -sh "${BUILD_DIR}/webgl" | cut -f1)
                log_info "构建大小: $size"
            else
                log_error "WebGL 构建失败"
                return 1
            fi
        else
            log_error "找不到构建脚本: scripts/build_webgl.sh"
            return 1
        fi
    fi
}

build_android() {
    if [ "$BUILD_ANDROID" = true ]; then
        log_header "构建 Android 版本"

        local start_time=$(date +%s)

        if [ -f "${PROJECT_DIR}/scripts/build_android.sh" ]; then
            cd "$PROJECT_DIR"
            bash scripts/build_android.sh "$BUILD_TYPE" 2>&1 | tee -a "$MAIN_LOG"

            local end_time=$(date +%s)
            local duration=$((end_time - start_time))

            if [ -d "${BUILD_DIR}/android" ] && [ "$(ls -A ${BUILD_DIR}/android 2>/dev/null)" ]; then
                log_success "Android 构建完成 (耗时: ${duration}秒)"

                # 显示构建大小
                if [ "$BUILD_TYPE" = "aab" ]; then
                    local size=$(du -sh "${BUILD_DIR}/android/aab" 2>/dev/null | cut -f1)
                    log_info "AAB 大小: $size"
                else
                    local size=$(du -sh "${BUILD_DIR}/android/apk" 2>/dev/null | cut -f1)
                    log_info "APK 大小: $size"
                fi
            else
                log_error "Android 构建失败"
                return 1
            fi
        else
            log_error "找不到构建脚本: scripts/build_android.sh"
            return 1
        fi
    fi
}

build_windows() {
    if [ "$BUILD_WINDOWS" = true ]; then
        log_header "构建 Windows 版本"

        log_warning "Windows 构建需要在 Windows 环境或使用交叉编译工具"

        # 检查Godot编辑器
        if ! command -v godot4 &> /dev/null && [ ! -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
            log_error "找不到Godot编辑器"
            return 1
        fi

        local GODOT_EDITOR="godot4"
        if [ -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
            GODOT_EDITOR="/Applications/Godot.app/Contents/MacOS/Godot"
        fi

        local export_flag="--export-release"
        if [ "$BUILD_TYPE" = "debug" ]; then
            export_flag="--export-debug"
        fi

        cd "$PROJECT_DIR"

        "$GODOT_EDITOR" --headless --quit-after 100 \
            $export_flag "Windows Desktop" "${BUILD_DIR}/windows/void_hunter.exe" \
            2>&1 | tee -a "$MAIN_LOG"

        if [ -f "${BUILD_DIR}/windows/void_hunter.exe" ]; then
            log_success "Windows 构建完成"
        else
            log_error "Windows 构建失败"
            return 1
        fi
    fi
}

build_linux() {
    if [ "$BUILD_LINUX" = true ]; then
        log_header "构建 Linux 版本"

        # 检查Godot编辑器
        if ! command -v godot4 &> /dev/null && [ ! -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
            log_error "找不到Godot编辑器"
            return 1
        fi

        local GODOT_EDITOR="godot4"
        if [ -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
            GODOT_EDITOR="/Applications/Godot.app/Contents/MacOS/Godot"
        fi

        local export_flag="--export-release"
        if [ "$BUILD_TYPE" = "debug" ]; then
            export_flag="--export-debug"
        fi

        cd "$PROJECT_DIR"

        "$GODOT_EDITOR" --headless --quit-after 100 \
            $export_flag "Linux/X11" "${BUILD_DIR}/linux/void_hunter.x86_64" \
            2>&1 | tee -a "$MAIN_LOG"

        if [ -f "${BUILD_DIR}/linux/void_hunter.x86_64" ]; then
            log_success "Linux 构建完成"
        else
            log_error "Linux 构建失败"
            return 1
        fi
    fi
}

build_macos() {
    if [ "$BUILD_MACOS" = true ]; then
        log_header "构建 macOS 版本"

        # 检查Godot编辑器
        if ! command -v godot4 &> /dev/null && [ ! -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
            log_error "找不到Godot编辑器"
            return 1
        fi

        local GODOT_EDITOR="godot4"
        if [ -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
            GODOT_EDITOR="/Applications/Godot.app/Contents/MacOS/Godot"
        fi

        local export_flag="--export-release"
        if [ "$BUILD_TYPE" = "debug" ]; then
            export_flag="--export-debug"
        fi

        cd "$PROJECT_DIR"

        "$GODOT_EDITOR" --headless --quit-after 100 \
            $export_flag "macOS" "${BUILD_DIR}/macos/void_hunter.zip" \
            2>&1 | tee -a "$MAIN_LOG"

        if [ -f "${BUILD_DIR}/macos/void_hunter.zip" ]; then
            log_success "macOS 构建完成"
        else
            log_error "macOS 构建失败"
            return 1
        fi
    fi
}

generate_build_report() {
    log_header "生成构建报告"

    local report_file="${BUILD_DIR}/build_report_${TIMESTAMP}.txt"

    cat > "$report_file" << EOF
========================================
Void Hunter - Build Report
========================================

构建时间: $(date)
构建类型: $BUILD_TYPE
项目版本: $(grep 'config/version=' "${PROJECT_DIR}/project.godot" | cut -d'"' -f2 || echo "unknown")
Git提交: $(cd "$PROJECT_DIR" && git rev-parse HEAD 2>/dev/null || echo "unknown")
Git分支: $(cd "$PROJECT_DIR" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

----------------------------------------
构建结果:
----------------------------------------

EOF

    # WebGL
    if [ "$BUILD_WEBGL" = true ]; then
        echo "WebGL:" >> "$report_file"
        if [ -d "${BUILD_DIR}/webgl" ] && [ "$(ls -A ${BUILD_DIR}/webgl 2>/dev/null)" ]; then
            echo "  状态: 成功" >> "$report_file"
            echo "  大小: $(du -sh ${BUILD_DIR}/webgl | cut -f1)" >> "$report_file"
            echo "  位置: ${BUILD_DIR}/webgl/" >> "$report_file"
        else
            echo "  状态: 失败或未构建" >> "$report_file"
        fi
        echo "" >> "$report_file"
    fi

    # Android
    if [ "$BUILD_ANDROID" = true ]; then
        echo "Android:" >> "$report_file"
        if [ -d "${BUILD_DIR}/android" ] && [ "$(ls -A ${BUILD_DIR}/android 2>/dev/null)" ]; then
            echo "  状态: 成功" >> "$report_file"
            if [ "$BUILD_TYPE" = "aab" ]; then
                echo "  AAB大小: $(du -sh ${BUILD_DIR}/android/aab 2>/dev/null | cut -f1)" >> "$report_file"
            else
                echo "  APK大小: $(du -sh ${BUILD_DIR}/android/apk 2>/dev/null | cut -f1)" >> "$report_file"
            fi
            echo "  位置: ${BUILD_DIR}/android/" >> "$report_file"
        else
            echo "  状态: 失败或未构建" >> "$report_file"
        fi
        echo "" >> "$report_file"
    fi

    # Windows
    if [ "$BUILD_WINDOWS" = true ]; then
        echo "Windows:" >> "$report_file"
        if [ -f "${BUILD_DIR}/windows/void_hunter.exe" ]; then
            echo "  状态: 成功" >> "$report_file"
            echo "  大小: $(du -sh ${BUILD_DIR}/windows/void_hunter.exe | cut -f1)" >> "$report_file"
            echo "  位置: ${BUILD_DIR}/windows/" >> "$report_file"
        else
            echo "  状态: 失败或未构建" >> "$report_file"
        fi
        echo "" >> "$report_file"
    fi

    # Linux
    if [ "$BUILD_LINUX" = true ]; then
        echo "Linux:" >> "$report_file"
        if [ -f "${BUILD_DIR}/linux/void_hunter.x86_64" ]; then
            echo "  状态: 成功" >> "$report_file"
            echo "  大小: $(du -sh ${BUILD_DIR}/linux/void_hunter.x86_64 | cut -f1)" >> "$report_file"
            echo "  位置: ${BUILD_DIR}/linux/" >> "$report_file"
        else
            echo "  状态: 失败或未构建" >> "$report_file"
        fi
        echo "" >> "$report_file"
    fi

    # macOS
    if [ "$BUILD_MACOS" = true ]; then
        echo "macOS:" >> "$report_file"
        if [ -f "${BUILD_DIR}/macos/void_hunter.zip" ]; then
            echo "  状态: 成功" >> "$report_file"
            echo "  大小: $(du -sh ${BUILD_DIR}/macos/void_hunter.zip | cut -f1)" >> "$report_file"
            echo "  位置: ${BUILD_DIR}/macos/" >> "$report_file"
        else
            echo "  状态: 失败或未构建" >> "$report_file"
        fi
        echo "" >> "$report_file"
    fi

    echo "----------------------------------------" >> "$report_file"
    echo "构建日志: ${BUILD_DIR}/logs/" >> "$report_file"
    echo "========================================" >> "$report_file"

    log_success "构建报告已生成: $report_file"

    # 显示报告
    cat "$report_file"
}

# ================================================================================
# 主流程
# ================================================================================

main() {
    # 解析参数
    parse_arguments "$@"

    # 显示标题
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Void Hunter - Build All Platforms  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""

    log_info "构建类型: $BUILD_TYPE"
    log_info "构建平台: WebGL=$BUILD_WEBGL, Android=$BUILD_ANDROID, Windows=$BUILD_WINDOWS, Linux=$BUILD_LINUX, macOS=$BUILD_MACOS"
    echo ""

    # 初始化日志
    mkdir -p "${BUILD_DIR}/logs"
    echo "Build started at $(date)" > "$MAIN_LOG"

    local start_time=$(date +%s)
    local build_failed=false

    # 执行构建
    setup_directories
    clean_all_builds

    # WebGL构建
    if ! build_webgl; then
        build_failed=true
    fi

    # Android构建
    if ! build_android; then
        build_failed=true
    fi

    # Windows构建
    if ! build_windows; then
        build_failed=true
    fi

    # Linux构建
    if ! build_linux; then
        build_failed=true
    fi

    # macOS构建
    if ! build_macos; then
        build_failed=true
    fi

    # 生成报告
    generate_build_report

    # 计算总耗时
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))

    # 显示结果
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    if [ "$build_failed" = true ]; then
        echo -e "${CYAN}║           构建完成 (有错误)             ║${NC}"
    else
        echo -e "${CYAN}║           所有构建完成成功!             ║${NC}"
    fi
    echo -e "${CYAN}║     总耗时: ${total_duration}秒                       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""

    log_info "构建日志: $MAIN_LOG"
    log_info "输出目录: $BUILD_DIR"
    echo ""

    if [ "$build_failed" = true ]; then
        exit 1
    fi
}

# 运行主函数
main "$@"
