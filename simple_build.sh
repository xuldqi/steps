#!/bin/bash

# 设置环境变量
export DEVECO_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default"

# 进入项目目录
cd /Users/macmima1234/Documents/harmony/StepSportszc

# 使用node直接运行hvigor
node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js assembleHap --mode module -p module=entry@default

