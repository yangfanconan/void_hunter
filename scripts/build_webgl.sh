#!/bin/bash
# ================================================================================
# Void Hunter - WebGL Build Script
# Godot 4.3 自动化WebGL构建脚本
# ================================================================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="Void Hunter"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
WEBGL_BUILD_DIR="${BUILD_DIR}/webgl"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BUILD_LOG="${BUILD_DIR}/logs/webgl_build_${TIMESTAMP}.log"

# Godot配置 (根据实际安装路径修改)
# macOS
GODOT_EDITOR="/Applications/Godot.app/Contents/MacOS/Godot"
# Linux
# GODOT_EDITOR="/usr/bin/godot"
# Windows (Git Bash)
# GODOT_EDITOR="/c/Program Files/Godot/Godot_v4.3-stable_win64.exe"

# 构建配置
BUILD_TYPE="${1:-release}"  # release 或 debug
COMPRESS_OUTPUT=true        # 是否压缩输出
TARGET_SIZE_MB=50          # 目标大小（MB）

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

check_dependencies() {
    log_info "检查依赖..."

    # 检查Godot编辑器
    if [ ! -f "$GODOT_EDITOR" ]; then
        # 尝试在PATH中查找
        if command -v godot4 &> /dev/null; then
            GODOT_EDITOR="godot4"
        elif command -v godot &> /dev/null; then
            GODOT_EDITOR="godot"
        else
            log_error "找不到Godot编辑器！"
            log_info "请修改脚本中的 GODOT_EDITOR 变量或安装Godot到PATH"
            exit 1
        fi
    fi

    log_success "Godot编辑器: $GODOT_EDITOR"

    # 检查压缩工具
    if [ "$COMPRESS_OUTPUT" = true ]; then
        if command -v brotli &> /dev/null; then
            COMPRESS_CMD="brotli"
            log_success "找到Brotli压缩工具"
        elif command -v gzip &> /dev/null; then
            COMPRESS_CMD="gzip"
            log_warning "未找到Brotli，使用gzip压缩"
        else
            log_warning "未找到压缩工具，跳过压缩"
            COMPRESS_OUTPUT=false
        fi
    fi
}

setup_directories() {
    log_info "设置构建目录..."

    mkdir -p "$BUILD_DIR"
    mkdir -p "$WEBGL_BUILD_DIR"
    mkdir -p "${BUILD_DIR}/logs"
    mkdir -p "${BUILD_DIR}/temp"

    log_success "构建目录已创建"
}

clean_build() {
    log_info "清理旧的构建文件..."

    if [ -d "$WEBGL_BUILD_DIR" ]; then
        rm -rf "${WEBGL_BUILD_DIR:?}"/*
    fi

    log_success "清理完成"
}

export_webgl() {
    log_info "开始WebGL导出 (${BUILD_TYPE})..."

    cd "$PROJECT_DIR"

    # 构建导出命令
    EXPORT_FLAGS=""
    if [ "$BUILD_TYPE" = "release" ]; then
        EXPORT_FLAGS="--export-release"
    else
        EXPORT_FLAGS="--export-debug"
    fi

    # 执行导出
    log_info "执行Godot导出命令..."

    "$GODOT_EDITOR" --headless --quit-after 100 \
        $EXPORT_FLAGS "WebGL" "$WEBGL_BUILD_DIR/index.html" \
        2>&1 | tee -a "$BUILD_LOG"

    # 检查导出是否成功
    if [ -f "$WEBGL_BUILD_DIR/index.html" ]; then
        log_success "WebGL导出完成"
    else
        log_error "WebGL导出失败！"
        exit 1
    fi
}

optimize_build() {
    log_info "优化构建文件..."

    cd "$WEBGL_BUILD_DIR"

    # 获取构建大小
    BUILD_SIZE=$(du -sm . | cut -f1)
    log_info "当前构建大小: ${BUILD_SIZE}MB"

    # 压缩WASM和资源文件
    if [ "$COMPRESS_OUTPUT" = true ]; then
        log_info "压缩文件..."

        case $COMPRESS_CMD in
            brotli)
                # 使用Brotli压缩（更好的压缩率）
                find . -type f \( -name "*.wasm" -o -name "*.js" -o -name "*.pck" \) -exec brotli -f -k {} \;
                ;;
            gzip)
                # 使用gzip压缩
                find . -type f \( -name "*.wasm" -o -name "*.js" -o -name "*.pck" \) -exec gzip -f -k {} \;
                ;;
        esac

        log_success "文件压缩完成"
    fi

    # 检查最终大小
    FINAL_SIZE=$(du -sm . | cut -f1)
    log_info "最终构建大小: ${FINAL_SIZE}MB (压缩前)"

    if [ "$FINAL_SIZE" -gt "$TARGET_SIZE_MB" ]; then
        log_warning "构建大小超过目标 (${TARGET_SIZE_MB}MB)"
        log_warning "考虑以下优化措施："
        log_warning "  - 减少纹理分辨率"
        log_warning "  - 使用VRAM压缩纹理格式"
        log_warning "  - 优化音频文件大小"
        log_warning "  - 移除未使用的资源"
    fi
}

copy_custom_template() {
    log_info "应用自定义HTML模板..."

    TEMPLATE_DIR="${PROJECT_DIR}/export/web_template"

    if [ -d "$TEMPLATE_DIR" ]; then
        # 备份原始文件
        if [ -f "$WEBGL_BUILD_DIR/index.html" ]; then
            cp "$WEBGL_BUILD_DIR/index.html" "$WEBGL_BUILD_DIR/index_original.html"
        fi

        # 复制自定义模板
        if [ -f "${TEMPLATE_DIR}/index.html" ]; then
            cp "${TEMPLATE_DIR}/index.html" "$WEBGL_BUILD_DIR/index.html"
            log_success "自定义HTML模板已应用"
        fi

        if [ -f "${TEMPLATE_DIR}/style.css" ]; then
            cp "${TEMPLATE_DIR}/style.css" "$WEBGL_BUILD_DIR/"
        fi

        if [ -f "${TEMPLATE_DIR}/loader.js" ]; then
            cp "${TEMPLATE_DIR}/loader.js" "$WEBGL_BUILD_DIR/"
        fi
    else
        log_info "未找到自定义模板，使用默认模板"
    fi
}

generate_build_info() {
    log_info "生成构建信息..."

    BUILD_INFO_FILE="$WEBGL_BUILD_DIR/build_info.json"

    cat > "$BUILD_INFO_FILE" << EOF
{
    "project": "$PROJECT_NAME",
    "version": "$(grep 'config/version=' "${PROJECT_DIR}/project.godot" | cut -d'"' -f2)",
    "build_type": "$BUILD_TYPE",
    "build_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "platform": "webgl",
    "godot_version": "$($GODOT_EDITOR --version 2>/dev/null || echo 'unknown')",
    "git_commit": "$(cd "$PROJECT_DIR" && git rev-parse HEAD 2>/dev/null || echo 'unknown')",
    "git_branch": "$(cd "$PROJECT_DIR" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
}
EOF

    log_success "构建信息已生成: $BUILD_INFO_FILE"
}

create_server_config() {
    log_info "创建服务器配置文件..."

    # 创建 .htaccess 用于Apache服务器
    cat > "$WEBGL_BUILD_DIR/.htaccess" << 'EOF'
# 启用压缩
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/css application/javascript application/wasm
</IfModule>

# 启用Brotli预压缩
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{HTTP:Accept-Encoding} br
    RewriteCond %{REQUEST_FILENAME}.br -f
    RewriteRule ^(.*)$ $1.br [L]
</IfModule>

# 设置正确的MIME类型
<IfModule mod_mime.c>
    AddType application/wasm .wasm
    AddType application/javascript .js
    AddType text/html .html
</IfModule>

# 启用缓存
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType application/wasm "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType text/html "access plus 1 hour"
</IfModule>

# 安全头
<IfModule mod_headers.c>
    Header set X-Content-Type-Options "nosniff"
    Header set X-Frame-Options "SAMEORIGIN"
    Header set X-XSS-Protection "1; mode=block"
</IfModule>
EOF

    # 创建 _headers 用于Netlify/Cloudflare
    cat > "$WEBGL_BUILD_DIR/_headers" << 'EOF'
/*
  X-Content-Type-Options: nosniff
  X-Frame-Options: SAMEORIGIN
  X-XSS-Protection: 1; mode=block

/*.wasm
  Content-Type: application/wasm
  Cache-Control: public, max-age=31536000, immutable

/*.js
  Content-Type: application/javascript
  Cache-Control: public, max-age=2592000

/*.pck
  Content-Type: application/octet-stream
  Cache-Control: public, max-age=31536000, immutable
EOF

    # 创建 vercel.json 用于Vercel部署
    cat > "$WEBGL_BUILD_DIR/vercel.json" << 'EOF'
{
  "headers": [
    {
      "source": "/(.*)\\.wasm",
      "headers": [
        { "key": "Content-Type", "value": "application/wasm" },
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    },
    {
      "source": "/(.*)\\.js",
      "headers": [
        { "key": "Content-Type", "value": "application/javascript" },
        { "key": "Cache-Control", "value": "public, max-age=2592000" }
      ]
    }
  ]
}
EOF

    log_success "服务器配置文件已创建"
}

# ================================================================================
# 主流程
# ================================================================================

main() {
    echo ""
    echo "========================================"
    echo "  $PROJECT_NAME - WebGL Build Script"
    echo "========================================"
    echo ""

    # 初始化日志
    mkdir -p "${BUILD_DIR}/logs"
    echo "Build started at $(date)" > "$BUILD_LOG"

    # 执行构建步骤
    check_dependencies
    setup_directories
    clean_build
    export_webgl
    copy_custom_template
    optimize_build
    generate_build_info
    create_server_config

    # 构建完成
    echo ""
    echo "========================================"
    log_success "构建完成！"
    echo "========================================"
    echo ""
    echo "输出目录: $WEBGL_BUILD_DIR"
    echo "构建日志: $BUILD_LOG"
    echo ""

    # 显示构建文件
    log_info "构建文件列表:"
    ls -lh "$WEBGL_BUILD_DIR"

    echo ""
    log_info "测试命令:"
    echo "  cd $WEBGL_BUILD_DIR && python3 -m http.server 8080"
    echo "  然后访问: http://localhost:8080"
    echo ""
}

# 运行主函数
main "$@"
