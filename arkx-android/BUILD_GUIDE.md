# 构建与运行指南

## 前置条件

1. **DevEco Studio**（支持 ArkUI X）
   - 下载地址：https://developer.harmonyos.com/
   - 确保已安装 Android SDK 和 NDK

2. **Android 开发环境**
   - Android SDK API Level 21+（Android 5.0+）
   - 建议使用 Android 8.0+ 真机或模拟器

3. **HMS Core 服务**（可选，用于登录功能）
   - 在 AGC 控制台创建 Android 应用
   - 配置 SHA256 证书指纹
   - 下载 `agconnect-services.json`

## 创建 ArkUI X Android 工程

1. 打开 DevEco Studio
2. 选择 **File > New > Create Project**
3. 选择 **ArkUI X** 模板
4. 选择 **Empty Template**
5. 平台选择：**仅勾选 Android**
6. 语言选择：**TypeScript/ETS**
7. 包名：建议使用 `com.microtarget.stepx`（避免与 HarmonyOS 版本冲突）

## 迁移源码

将 `arkx-android/src/main/ets/` 下的所有文件复制到新工程的对应目录：

```
arkx-android/src/main/ets/
├── appdata/
│   └── Model.ts                    # 数据模型
├── tools/
│   ├── UiConstants.ts             # UI 常量
│   ├── DataCallback.ts            # 数据回调接口
│   ├── DateUtils.ts               # 日期工具
│   ├── AppDataManager.ts          # 数据管理器
│   ├── HuaweiAuth.ts              # 登录服务（占位）
│   └── PreferencesUtil.ts         # 本地存储（占位）
├── view/
│   ├── CommonTitleView.ets        # 通用标题组件
│   └── BarChartView.ets           # 图表组件
└── pages/
    ├── ExerciseTimePage.ets       # 锻炼时长统计
    ├── ActivityCountPage.ets      # 活动次数统计
    ├── ChartPage.ets              # 热量统计
    └── LoginPage.ets              # 登录页面
```

## 配置资源

1. 将图标资源复制到 `resources/base/media/`：
   - `back_btn_dark.png`（返回按钮）
   - `right_btn.png`（右箭头）
   - `week_report_reward.png`（奖励图标）
   - `icon.png`（应用图标）

2. 配置应用图标和名称：
   - 在 `resources/base/element/string.json` 中配置应用名称
   - 在 `AppScope/app.json5` 中配置应用信息

## 配置页面路由

在 `resources/base/profile/main_pages.json` 中添加页面路由：

```json
{
  "src": [
    "pages/Index",
    "pages/LoginPage",
    "pages/ExerciseTimePage",
    "pages/ActivityCountPage",
    "pages/ChartPage"
  ]
}
```

## 构建与运行

1. **同步依赖**
   - 点击 **Sync Project with Gradle Files**

2. **连接设备**
   - 连接 Android 真机或启动模拟器
   - 确保已开启 USB 调试

3. **运行应用**
   - 点击 **Run** 按钮或按 `Shift+F10`
   - 选择目标设备
   - 等待构建完成并安装

## 打包 APK/AAB

1. **生成签名密钥**
   ```bash
   keytool -genkeypair -v -keystore stepx-release.jks -alias stepx -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **配置签名**
   - 在 `build-profile.json5` 中配置签名信息

3. **构建 Release**
   - 选择 **Build > Generate Signed Bundle / APK**
   - 选择 **Android App Bundle** 或 **APK**
   - 选择签名密钥并构建

## 已知问题与解决方案

### 1. Web 组件不支持
**问题**：`BarChartView` 使用 Web 组件加载 ECharts，ArkUI X 可能不支持。

**解决方案**：
- 方案 A：使用原生图表库（如 MPAndroidChart），通过 Native 桥接
- 方案 B：使用 Canvas 组件自行绘制图表
- 方案 C：使用第三方 ArkUI X 图表组件

### 2. 登录功能需要 Native 桥接
**问题**：HMS Account Kit 需要通过 Native 桥接调用。

**解决方案**：参考 `NATIVE_BRIDGE_GUIDE.md` 实现 Native 桥接。

### 3. 数据层使用假数据
**问题**：当前 `AppDataManager` 使用假数据。

**解决方案**：
- 方案 A：接入 Room 数据库（推荐）
- 方案 B：接入 AGC CloudDB（Android）
- 方案 C：使用 SQLite 原生 API（通过 Native 桥接）

## 下一步

1. 实现 Native 桥接（HMS Account + SharedPreferences）
2. 接入真实数据源（Room 或 AGC CloudDB）
3. 迁移更多页面（首页、设置页等）
4. 完善错误处理和用户体验

