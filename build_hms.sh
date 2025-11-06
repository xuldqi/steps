#!/bin/bash

# 设置HMS SDK环境变量
export DEVECO_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default/hms"
export OHOS_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default/hms"
export HOS_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default/hms"

# 进入项目目录
cd /Users/macmima1234/Documents/harmony/StepSportszc

# 显示环境变量
echo "Environment variables:"
echo "DEVECO_SDK_HOME: $DEVECO_SDK_HOME"
echo "OHOS_SDK_HOME: $OHOS_SDK_HOME"
echo "HOS_SDK_HOME: $HOS_SDK_HOME"
echo ""

# 运行构建命令
node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js assembleHap --mode module -p module=entry@default

