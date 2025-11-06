# 快速开始 - 打包 Android 版本

## 🚀 最快方式：使用 DevEco Studio

### 步骤 1：创建 ArkUI X Android 项目

1. 打开 **DevEco Studio**
2. 选择 **File > New > Create Project**
3. 选择 **ArkUI X** 模板
4. 平台选择：**仅勾选 Android** ✅
5. 包名：`com.microtarget.stepx`
6. 项目名称：`StepSportsAndroid`
7. 点击 **Finish**

### 步骤 2：复制迁移的代码

```bash
# 方法 1：使用命令行（在项目根目录执行）
cp -r arkx-android/src/main/ets/* <新项目路径>/entry/src/main/ets/

# 方法 2：手动复制
# 将 arkx-android/src/main/ets/ 下的所有文件夹和文件
# 复制到新项目的 entry/src/main/ets/ 目录
```

### 步骤 3：配置页面路由

编辑 `entry/src/main/resources/base/profile/main_pages.json`，内容如下：

```json
{
  "src": [
    "pages/Index",
    "pages/MainTabs",
    "pages/LoginPage",
    "pages/UserProfilePage",
    "pages/ExerciseTimePage",
    "pages/ActivityCountPage",
    "pages/ChartPage",
    "pages/StepTrendPage",
    "pages/DistanceTrendPage",
    "pages/SportRecordPage",
    "pages/ExerciseRecordPage",
    "pages/TargetManagementPage",
    "pages/WeightTrendPage",
    "pages/BodyDataPage",
    "pages/EditMainCardPage",
    "pages/SettingPage",
    "pages/XYPage",
    "pages/YSPage"
  ]
}
```

### 步骤 4：配置应用信息

编辑 `AppScope/app.json5`：

```json5
{
  "app": {
    "bundleName": "com.microtarget.stepx",
    "vendor": "microtarget",
    "versionCode": 1,
    "versionName": "1.2.0",
    "icon": "$media:app_icon",
    "label": "$string:app_name"
  }
}
```

### 步骤 5：复制资源文件

将原项目的资源文件复制到新项目：

```bash
# 复制图片资源
cp -r entry/src/main/resources/base/media/* <新项目路径>/entry/src/main/resources/base/media/

# 复制 HTML 文件（用户协议、隐私政策）
cp entry/src/main/resources/rawfile/yhxy.htm <新项目路径>/entry/src/main/resources/rawfile/
cp entry/src/main/resources/rawfile/yszc.htm <新项目路径>/entry/src/main/resources/rawfile/
```

### 步骤 6：构建 APK

1. 在 DevEco Studio 中，选择 **Build > Generate Signed Bundle / APK**
2. 选择 **APK**
3. 创建或选择签名密钥：
   - 如果已有密钥，选择现有密钥
   - 如果没有，点击 **Create new...** 创建新密钥
4. 选择 **release** 构建类型
5. 点击 **Finish**
6. 等待构建完成

### 步骤 7：获取 APK

构建完成后，APK 文件位于：

```
entry/build/default/outputs/default/entry-default-signed.apk
```

或者在构建输出窗口会显示完整路径。

## 📱 安装到设备

### 方法 1：通过 DevEco Studio
1. 连接 Android 设备（开启 USB 调试）
2. 点击 **Run** 按钮
3. 选择目标设备
4. 自动安装并运行

### 方法 2：手动安装
```bash
# 使用 adb 安装
adb install entry/build/default/outputs/default/entry-default-signed.apk

# 或直接传输到设备后安装
```

## ⚠️ 重要提示

1. **ArkUI X 支持**：确保 DevEco Studio 版本支持 ArkUI X（最新版本）
2. **Native 桥接**：登录和存储功能需要实现 Native 桥接才能正常工作
3. **数据源**：当前使用假数据，图表和统计会显示模拟数据
4. **资源文件**：确保所有图片和 HTML 文件已复制

## 🔧 问题排查

### 构建失败
- 检查 DevEco Studio 版本是否支持 ArkUI X
- 检查 SDK 和工具链是否完整
- 查看构建日志中的错误信息

### 运行时错误
- 检查页面路由配置是否正确
- 检查资源文件是否完整
- 检查 Native 桥接是否实现（登录和存储功能）

### 图表不显示
- 检查 WebView 组件是否支持
- 如不支持，需要改用原生图表库或 Canvas

## 📚 更多信息

- [构建指南](BUILD_GUIDE.md) - 详细的构建说明
- [Native 桥接指南](NATIVE_BRIDGE_GUIDE.md) - 实现登录和存储功能
- [迁移总结](FINAL_MIGRATION_STATUS.md) - 完整的迁移状态

---

**推荐**：使用 DevEco Studio 创建项目并构建，这是最可靠的方式。

