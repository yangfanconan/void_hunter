#!/bin/bash
# Void Hunter - APK 签名脚本
# 确保签名后清理残留进程

set -e

SDK_PATH="/opt/homebrew/share/android-commandlinetools"
BUILD_TOOLS="$SDK_PATH/build-tools/34.0.0"
KEYSTORE="/Users/yangfan/Library/Application Support/Godot/keystores/debug.keystore"
KEYSTORE_PASS="android"

INPUT_APK="$1"
OUTPUT_APK="${2:-${INPUT_APK%.apk}_signed.apk}"

if [ -z "$INPUT_APK" ]; then
    echo "用法: $0 <输入APK> [输出APK]"
    exit 1
fi

echo "📦 签名 APK: $INPUT_APK"

# 复制 keystore 到临时位置（避免路径中的空格问题）
TEMP_KEYSTORE="/tmp/debug.keystore"
cp "$KEYSTORE" "$TEMP_KEYSTORE"

# 对齐
echo "🔄 对齐中..."
"$BUILD_TOOLS/zipalign" -f -v 4 "$INPUT_APK" "${INPUT_APK%.apk}_aligned.apk" 2>&1 | tail -2

# 签名（使用 timeout 确保不会卡住）
echo "✍️ 签名中..."
timeout 30 "$BUILD_TOOLS/apksigner" sign \
    --ks "$TEMP_KEYSTORE" \
    --ks-pass "pass:$KEYSTORE_PASS" \
    --out "$OUTPUT_APK" \
    "${INPUT_APK%.apk}_aligned.apk" 2>&1 || true

# 清理临时文件
rm -f "$TEMP_KEYSTORE"
rm -f "${INPUT_APK%.apk}_aligned.apk"

# 强制清理残留的 apksigner 进程
pkill -9 -f "apksigner.jar" 2>/dev/null || true

# 验证签名
echo "🔍 验证签名..."
"$BUILD_TOOLS/apksigner" verify "$OUTPUT_APK" && echo "✅ 签名成功: $OUTPUT_APK" || echo "❌ 签名验证失败"

ls -la "$OUTPUT_APK"
