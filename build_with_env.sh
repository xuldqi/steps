#!/bin/bash

# 设置所有必要的环境变量
export DEVECO_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default"
export OHOS_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default"
export HOS_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default"
export ARKUIX_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default"
export NODE_HOME="/Applications/DevEco-Studio.app/Contents/tools/node"

# 添加到PATH
export PATH="$PATH:/Applications/DevEco-Studio.app/Contents/sdk/default/toolchains"
export PATH="$PATH:/Applications/DevEco-Studio.app/Contents/tools/node/bin"

# 显示环境变量
echo "Environment variables:"
echo "DEVECO_SDK_HOME: $DEVECO_SDK_HOME"
echo "OHOS_SDK_HOME: $OHOS_SDK_HOME"
echo "HOS_SDK_HOME: $HOS_SDK_HOME"
echo "ARKUIX_SDK_HOME: $ARKUIX_SDK_HOME"
echo "NODE_HOME: $NODE_HOME"
echo ""

# 运行构建命令
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p module=entry@default -p product=default -p buildMode=debug -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon

