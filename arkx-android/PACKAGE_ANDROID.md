# 📦 Android 打包指南

## ⚡ 快速打包（推荐）

### 方式一：使用 DevEco Studio（最简单）

1. **打开 DevEco Studio**
2. **创建 ArkUI X Android 项目**
   - File > New > Create Project
   - 选择 **ArkUI X** > **Empty Template**
   - 平台：**仅勾选 Android** ✅
   - 包名：`com.microtarget.stepx`
   - 项目名：`StepSportsAndroid`

3. **复制代码**
   ```bash
   # 在项目根目录执行
   cp -r arkx-android/src/main/ets/* <新项目路径>/entry/src/main/ets/
   ```

4. **配置页面路由**
   - 编辑 `entry/src/main/resources/base/profile/main_pages.json`
   - 复制 `arkx-android/main_pages.json` 的内容

5. **构建 APK**
   - Build > Generate Signed Bundle / APK
   - 选择 **APK**
   - 配置签名
   - 构建

### 方式二：在当前项目中尝试构建

如果当前项目支持 ArkUI X，可以尝试：

```bash
# 进入项目目录
cd /Users/macmima1234/Documents/harmony/StepSportszc

# 检查是否有构建工具
ls -la | grep hvigor

# 如果有 hvigor，尝试构建
# 注意：HarmonyOS 项目构建的是 HAP，不是 APK
```

## 📋 详细步骤

### 1. 准备环境

- ✅ DevEco Studio（最新版本，支持 ArkUI X）
- ✅ Android SDK（API 21+）
- ✅ Java JDK 8+

### 2. 创建项目结构

在 DevEco Studio 中创建项目后，项目结构应该是：

```
StepSportsAndroid/
├── entry/
│   ├── src/
│   │   └── main/
│   │       ├── ets/
│   │       │   ├── pages/          # 页面代码
│   │       │   ├── view/           # 组件代码
│   │       │   └── tools/          # 工具类
│   │       └── resources/          # 资源文件
│   └── build-profile.json5
├── AppScope/
│   └── app.json5
└── build-profile.json5
```

### 3. 复制代码

```bash
# 复制所有 ETS 代码
cp -r arkx-android/src/main/ets/* entry/src/main/ets/

# 复制配置文件
cp arkx-android/main_pages.json entry/src/main/resources/base/profile/main_pages.json
cp arkx-android/app.json5 AppScope/app.json5
```

### 4. 配置资源

复制图片资源：
```bash
# 从原项目复制资源
cp -r entry/src/main/resources/base/media/* <新项目>/entry/src/main/resources/base/media/
```

### 5. 构建签名

#### 创建签名密钥（如果没有）

```bash
keytool -genkeypair -v \
  -keystore stepx-release.jks \
  -alias stepx \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

#### 在 DevEco Studio 中配置

1. File > Project Structure > Signing Configs
2. 添加签名配置
3. 选择密钥文件并输入密码

### 6. 构建 APK

在 DevEco Studio 中：
1. Build > Generate Signed Bundle / APK
2. 选择 **APK**
3. 选择签名配置
4. 选择 **release**
5. 点击 **Finish**

### 7. 获取 APK

构建完成后，APK 位于：
```
entry/build/default/outputs/default/entry-default-signed.apk
```

## 🔍 验证 APK

```bash
# 检查 APK 信息
aapt dump badging entry/build/default/outputs/default/entry-default-signed.apk

# 安装到设备
adb install entry/build/default/outputs/default/entry-default-signed.apk
```

## ⚠️ 注意事项

1. **ArkUI X 支持**：确保 DevEco Studio 版本支持 ArkUI X
2. **Native 桥接**：登录和存储功能需要实现 Native 桥接
3. **数据源**：当前使用假数据，需要接入真实数据源
4. **WebView**：图表组件使用 WebView，确保 ArkUI X 支持

## 🐛 常见问题

### Q: 构建失败，提示找不到模块
A: 检查页面路由配置是否正确，确保所有页面都在 `main_pages.json` 中

### Q: 运行时崩溃
A: 检查资源文件是否完整，特别是图片资源

### Q: 图表不显示
A: 检查 WebView 组件是否支持，如不支持需要改用原生图表库

### Q: 登录功能不工作
A: 需要实现 Native 桥接（参考 `NATIVE_BRIDGE_GUIDE.md`）

## 📞 需要帮助？

查看详细文档：
- [快速开始](QUICK_START.md)
- [构建指南](BUILD_GUIDE.md)
- [Native 桥接指南](NATIVE_BRIDGE_GUIDE.md)

---

**推荐**：使用 DevEco Studio 创建项目并构建，这是最可靠的方式。

