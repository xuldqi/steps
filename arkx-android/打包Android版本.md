# 📦 打包 Android 版本 - 详细步骤

## ⚠️ 重要说明

当前项目是 **HarmonyOS 项目**，构建的是 **HAP 文件**，不是 **APK**。

要打包 **Android APK**，需要：
1. 在 DevEco Studio 中创建 **ArkUI X Android 项目**
2. 复制迁移的代码到新项目
3. 在新项目中构建 APK

## 🚀 快速打包步骤

### 第一步：创建 ArkUI X Android 项目

1. **打开 DevEco Studio**
2. **创建新项目**
   - 点击 **File > New > Create Project**
   - 选择 **ArkUI X** 模板
   - 选择 **Empty Template**
   - **平台选择**：**仅勾选 Android** ✅（重要！）
   - **包名**：`com.microtarget.stepx`
   - **项目名称**：`StepSportsAndroid`
   - 点击 **Finish**

### 第二步：复制迁移的代码

```bash
# 方法 1：使用命令行（推荐）
# 在项目根目录执行
cd /Users/macmima1234/Documents/harmony/StepSportszc
cp -r arkx-android/src/main/ets/* <新项目路径>/entry/src/main/ets/

# 方法 2：手动复制
# 1. 打开 arkx-android/src/main/ets/ 目录
# 2. 复制所有文件夹（pages、view、tools、appdata）
# 3. 粘贴到新项目的 entry/src/main/ets/ 目录
```

### 第三步：配置页面路由

编辑新项目的 `entry/src/main/resources/base/profile/main_pages.json`：

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

或者直接复制：
```bash
cp arkx-android/main_pages.json <新项目路径>/entry/src/main/resources/base/profile/main_pages.json
```

### 第四步：配置应用信息

编辑新项目的 `AppScope/app.json5`：

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

### 第五步：复制资源文件

```bash
# 复制图片资源
cp -r entry/src/main/resources/base/media/* <新项目路径>/entry/src/main/resources/base/media/

# 复制 HTML 文件（用户协议、隐私政策）
cp entry/src/main/resources/rawfile/yhxy.htm <新项目路径>/entry/src/main/resources/rawfile/
cp entry/src/main/resources/rawfile/yszc.htm <新项目路径>/entry/src/main/resources/rawfile/
```

### 第六步：构建 APK

1. **在 DevEco Studio 中打开新项目**
2. **配置签名**（如果还没有）：
   - File > Project Structure > Signing Configs
   - 添加签名配置
   - 创建或选择密钥文件
3. **构建 APK**：
   - 点击 **Build > Generate Signed Bundle / APK**
   - 选择 **APK**
   - 选择签名配置
   - 选择 **release** 构建类型
   - 点击 **Finish**
4. **等待构建完成**

### 第七步：获取 APK

构建完成后，APK 文件位于：

```
entry/build/default/outputs/default/entry-default-signed.apk
```

或者在构建输出窗口会显示完整路径。

## 📱 安装到 Android 设备

### 方法 1：通过 DevEco Studio
1. 连接 Android 设备（开启 USB 调试）
2. 点击 **Run** 按钮（绿色三角形）
3. 选择目标设备
4. 自动安装并运行

### 方法 2：手动安装
```bash
# 使用 adb 安装
adb install entry/build/default/outputs/default/entry-default-signed.apk

# 或直接传输到设备后点击安装
```

## 🔧 创建签名密钥（如果没有）

```bash
keytool -genkeypair -v \
  -keystore stepx-release.jks \
  -alias stepx \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

按照提示输入信息：
- 密钥库密码
- 密钥密码
- 姓名、组织等信息

## ⚠️ 重要提示

1. **ArkUI X 支持**：确保 DevEco Studio 版本支持 ArkUI X（建议最新版本）
2. **平台选择**：创建项目时**必须只选择 Android**，不要选择 HarmonyOS
3. **Native 桥接**：登录和存储功能需要实现 Native 桥接才能正常工作
4. **数据源**：当前使用假数据，图表和统计会显示模拟数据
5. **资源文件**：确保所有图片和 HTML 文件已复制

## 🐛 常见问题

### Q: 构建失败，提示找不到页面
A: 检查 `main_pages.json` 配置是否正确，确保所有页面都在列表中

### Q: 运行时崩溃
A: 检查资源文件是否完整，特别是图片资源

### Q: 图表不显示
A: 检查 WebView 组件是否支持，如不支持需要改用原生图表库

### Q: 登录功能不工作
A: 需要实现 Native 桥接（参考 `NATIVE_BRIDGE_GUIDE.md`）

## 📚 相关文档

- [快速开始](QUICK_START.md) - 更简洁的步骤说明
- [构建指南](BUILD_GUIDE.md) - 详细的构建说明
- [Native 桥接指南](NATIVE_BRIDGE_GUIDE.md) - 实现登录和存储功能
- [最终迁移状态](FINAL_MIGRATION_STATUS.md) - 完整的迁移状态

---

**总结**：在 DevEco Studio 中创建 ArkUI X Android 项目 → 复制代码 → 构建 APK

