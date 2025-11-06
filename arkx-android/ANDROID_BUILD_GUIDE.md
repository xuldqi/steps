# Android 打包指南

## ⚠️ 重要说明

当前 `arkx-android` 目录包含的是**迁移的代码**，不是完整的 Android 项目。要打包 Android 版本，需要：

### 方案一：使用 DevEco Studio 创建 ArkUI X Android 项目（推荐）

1. **打开 DevEco Studio**
2. **创建新项目**
   - File > New > Create Project
   - 选择 **ArkUI X** 模板
   - 平台选择：**仅勾选 Android**
   - 包名：`com.microtarget.stepx`
   - 语言：TypeScript/ETS

3. **复制迁移的代码**
   ```bash
   # 将 arkx-android/src/main/ets/ 下的所有文件复制到新项目的对应目录
   cp -r arkx-android/src/main/ets/* <新项目路径>/entry/src/main/ets/
   ```

4. **配置资源文件**
   - 复制图片资源到 `resources/base/media/`
   - 配置 `main_pages.json` 添加页面路由

5. **构建和打包**
   - 在 DevEco Studio 中点击 **Build > Generate Signed Bundle / APK**
   - 选择 APK 或 AAB 格式
   - 配置签名密钥
   - 构建

### 方案二：使用标准 Android 项目（需要适配）

如果 ArkUI X 项目结构不完整，可以：

1. **创建标准 Android 项目**
   ```bash
   # 使用 Android Studio 创建新项目
   # 或使用命令行
   ```

2. **集成 ArkUI X 运行时**
   - 需要添加 ArkUI X 依赖库
   - 配置 ArkUI X 运行时环境

3. **适配代码**
   - 将 ETS 代码转换为可运行的格式
   - 实现 Native 桥接

## 快速打包步骤（DevEco Studio）

### 1. 创建项目
- 打开 DevEco Studio
- 创建 ArkUI X Android 项目

### 2. 复制代码
```bash
# 在项目根目录执行
cp -r arkx-android/src/main/ets/* entry/src/main/ets/
```

### 3. 配置页面路由
编辑 `entry/src/main/resources/base/profile/main_pages.json`：
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

### 4. 配置应用信息
编辑 `AppScope/app.json5`：
```json5
{
  "app": {
    "bundleName": "com.microtarget.stepx",
    "versionCode": 1,
    "versionName": "1.2.0",
    "vendor": "microtarget"
  }
}
```

### 5. 构建 APK
1. 在 DevEco Studio 中选择 **Build > Generate Signed Bundle / APK**
2. 选择 **APK**
3. 创建或选择签名密钥
4. 选择 **release** 构建类型
5. 点击 **Finish**

### 6. 输出位置
构建完成后，APK 文件位于：
```
entry/build/default/outputs/default/entry-default-signed.apk
```

## 注意事项

1. **ArkUI X 支持**：确保 DevEco Studio 版本支持 ArkUI X
2. **Native 桥接**：登录和存储功能需要实现 Native 桥接（参考 `NATIVE_BRIDGE_GUIDE.md`）
3. **资源文件**：确保所有图片资源已复制到项目
4. **数据源**：当前使用假数据，需要接入真实数据源

## 命令行构建（如果支持）

```bash
# 进入项目目录
cd <项目路径>

# 清理构建
./gradlew clean

# 构建 Debug APK
./gradlew assembleDebug

# 构建 Release APK
./gradlew assembleRelease

# 输出位置
# app/build/outputs/apk/debug/app-debug.apk
# app/build/outputs/apk/release/app-release.apk
```

## 问题排查

### 1. 找不到 ArkUI X 插件
- 确保 DevEco Studio 已更新到最新版本
- 检查是否安装了 ArkUI X 插件

### 2. 构建失败
- 检查 SDK 版本是否匹配
- 检查依赖是否完整
- 查看构建日志

### 3. 运行时错误
- 检查 Native 桥接是否实现
- 检查资源文件是否完整
- 检查页面路由配置

---

**推荐方式**：使用 DevEco Studio 创建 ArkUI X Android 项目，然后复制迁移的代码。

