# 迁移计划（ArkUI X Android）

## 工程
- 新建 ArkUI X Android 工程，包名与本项目 `com.microtarget.step.ohs` 对齐或新包名。
- 资源：将 `entry/src/main/resources/base/media` 下 PNG 拷贝到 ArkUI X 资源目录；HTML 放到 `rawfile` 等价目录或 WebView 资源。

## 通用组件
- 迁移 `view/CommonTitleView.ets`，保留沉浸与安全区逻辑；必要时简化 API 以适配 ArkUI X。
- `UiConstants.ts` 常量直接复用。

## 页面优先级
1. `ExerciseTimePage.ets`（锻炼时长）
2. `ActivityCountPage.ets`（活动次数）
3. `ChartPage.ets`（热量）
4. 其余页面依次迁移。

## 能力替换
- 登录：HMS Account Kit(Android)；封装 `LoginService` 统一接口。
- 存储：SharedPreferences/Room 或 AGC CloudDB(Android)。
- 权限：网络、运动相关权限按 AndroidManifest 配置。

## 构建与签名
- Gradle 构建；调试 keystore 与发布 keystore 分离。
- 输出 APK/AAB。

## 验证
- 登录流程、趋势图显示、目标进度、汇总卡片。
