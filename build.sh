#!/bin/bash
export DEVECO_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default/hms"
export OHOS_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default/hms"
export PATH="$PATH:/Applications/DevEco-Studio.app/Contents/sdk/default/hms/toolchains"

/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p module=entry@default -p product=default -p buildMode=release -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon






