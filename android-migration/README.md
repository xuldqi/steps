# ArkUI → ArkUI X(Android) 迁移说明

本目录用于承载从 HarmonyOS ArkUI(ArkTS) 到 ArkUI X(Android) 的迁移资料与步骤。

## 迁移路线
- 目标平台：Android（优先 Android 8+）。
- 技术方案：ArkUI X（TypeScript/ETS 语法子集），在 Android 上运行。
- 能力替换：
  - 账号登录：Harmony HuaweiID → Android HMS Account Kit。
  - 云与分析：按需替换为 AGC Android SDK；不支持的接口用占位/适配层。
  - 存储：Preferences/CloudDB → Android SharedPreferences/Room（或 AGC CloudDB Android）。

## 前置准备
1. 安装 DevEco Studio（支持 ArkUI X）与 Android SDK/NDK（按官方文档）。
2. 创建 ArkUI X 空工程（Android 目标）。
3. 将本项目的 `android-migration` 文档作为参考，逐步迁移页面与组件。

## 迁移顺序
1. 搭建工程与包名、签名配置。
2. 迁移通用组件（`CommonTitleView` 等）与主题色、沉浸规则。
3. 迁移核心页面：锻炼时长、活动次数、热量（含趋势图）。
4. 接入 HMS Account（Android）并打通登录流程。
5. 迁移剩余页面与资源打包。
6. 打包 APK/AAB 并在真机验证。

更多细节见 `PLAN.md` 与 `components_mapping.md`。
