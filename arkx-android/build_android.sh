#!/bin/bash

# ArkUI X Android 打包脚本
# 使用方法：在 DevEco Studio 创建的 ArkUI X Android 项目根目录执行

set -e

echo "=========================================="
echo "ArkUI X Android 打包脚本"
echo "=========================================="

# 检查是否在项目根目录
if [ ! -f "build-profile.json5" ] && [ ! -f "build.gradle" ]; then
    echo "❌ 错误：请在 ArkUI X Android 项目根目录执行此脚本"
    echo "   或者使用 DevEco Studio 的 Build > Generate Signed Bundle / APK"
    exit 1
fi

# 检查 DevEco Studio 环境
if command -v hvigorw &> /dev/null; then
    echo "✅ 检测到 HarmonyOS 构建工具"
    BUILD_TOOL="hvigor"
elif [ -f "gradlew" ]; then
    echo "✅ 检测到 Gradle 构建工具"
    BUILD_TOOL="gradle"
else
    echo "⚠️  未检测到构建工具，请使用 DevEco Studio 进行构建"
    echo ""
    echo "推荐步骤："
    echo "1. 打开 DevEco Studio"
    echo "2. 打开 ArkUI X Android 项目"
    echo "3. 选择 Build > Generate Signed Bundle / APK"
    echo "4. 选择 APK 或 AAB"
    echo "5. 配置签名并构建"
    exit 1
fi

echo ""
echo "开始构建..."

if [ "$BUILD_TOOL" = "hvigor" ]; then
    # HarmonyOS 构建
    echo "使用 hvigor 构建..."
    ./hvigorw assembleHap --mode module -p module=entry@default
    echo ""
    echo "✅ 构建完成！"
    echo "APK 位置：entry/build/default/outputs/default/entry-default-signed.hap"
    echo ""
    echo "注意：HarmonyOS 项目输出的是 HAP 文件，不是 APK"
    echo "要打包 Android APK，请在 DevEco Studio 中创建 ArkUI X Android 项目"
    
elif [ "$BUILD_TOOL" = "gradle" ]; then
    # Gradle 构建
    echo "使用 Gradle 构建..."
    ./gradlew clean
    ./gradlew assembleRelease
    
    echo ""
    echo "✅ 构建完成！"
    echo "APK 位置：app/build/outputs/apk/release/app-release-unsigned.apk"
    echo ""
    echo "⚠️  注意：这是未签名的 APK，需要签名后才能安装"
    echo "使用以下命令签名："
    echo "jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore your.keystore app-release-unsigned.apk alias_name"
fi

echo ""
echo "=========================================="
echo "构建完成！"
echo "=========================================="

