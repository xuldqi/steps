#!/bin/bash

# 设置所有必要的环境变量
export DEVECO_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony"
export OHOS_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony"
export HOS_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony"
export ARKUIX_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony"

# 进入项目目录
cd /Users/macmima1234/Documents/harmony/StepSportszc

# 显示环境变量
echo "=== 环境变量设置 ==="
echo "DEVECO_SDK_HOME: $DEVECO_SDK_HOME"
echo "OHOS_SDK_HOME: $OHOS_SDK_HOME"
echo "HOS_SDK_HOME: $HOS_SDK_HOME"
echo "ARKUIX_SDK_HOME: $ARKUIX_SDK_HOME"
echo ""

# 运行构建命令
echo "=== 开始构建 ==="
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p module=entry@default -p product=default -p buildMode=release -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
















