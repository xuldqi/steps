#!/bin/bash
set -euo pipefail

# 默认 DevEco SDK 根路径（可通过 DEVECO_SDK_HOME 覆盖）
DEVECO_SDK_ROOT=${DEVECO_SDK_HOME:-"/Applications/DevEco-Studio.app/Contents/sdk/default"}
HDC_BIN="$DEVECO_SDK_ROOT/openharmony/toolchains/hdc"

PROJECT_ROOT="/Users/macmima1234/Documents/harmony/StepSportszc"
HAP_DEFAULT="$PROJECT_ROOT/entry/build/default/outputs/default/entry-default-unsigned.hap"

# 应用信息（如有变更，可同步修改）
BUNDLE_NAME="com.microtarget.step.ohs"
MAIN_ABILITY="EntryAbility"

echo "[1/4] 构建 HAP..."
bash "$PROJECT_ROOT/build.sh"

echo "[2/4] 定位 HAP 包..."
HAP_PATH=""
if [[ -f "$HAP_DEFAULT" ]]; then
  HAP_PATH="$HAP_DEFAULT"
else
  # 兜底：在 entry/build 下搜索最新的 .hap
  mapfile -t HAPS < <(find "$PROJECT_ROOT/entry/build" -type f -name "*.hap" -print0 | xargs -0 ls -t 2>/dev/null || true)
  if [[ ${#HAPS[@]} -gt 0 ]]; then
    HAP_PATH="${HAPS[0]}"
  fi
fi

if [[ -z "$HAP_PATH" || ! -f "$HAP_PATH" ]]; then
  echo "[错误] 未找到 HAP 包。请检查构建输出。" >&2
  exit 1
fi
echo "HAP: $HAP_PATH"

if [[ ! -x "$HDC_BIN" ]]; then
  echo "[错误] 未找到 hdc 可执行文件：$HDC_BIN" >&2
  exit 1
fi

echo "[3/4] 检测模拟器/设备..."
TARGETS=$("$HDC_BIN" list targets || true)
TARGET=$(echo "$TARGETS" | head -n1 | tr -d '\r')
if [[ -z "$TARGET" ]]; then
  echo "[错误] 未检测到在线设备。请先在 DevEco Studio 启动模拟器。" >&2
  echo "提示: 打开 DevEco Studio -> 工具栏 Emulator -> 启动一个设备" >&2
  exit 1
fi
echo "使用目标: $TARGET"

echo "[4/4] 安装并启动应用..."
"$HDC_BIN" -t "$TARGET" install -r "$HAP_PATH"
"$HDC_BIN" -t "$TARGET" shell aa start -a "$MAIN_ABILITY" -b "$BUNDLE_NAME"

echo "完成。应用已启动。"












