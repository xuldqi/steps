# Native 桥接指南（HMS Account Kit Android）

由于 ArkUI X 在 Android 上运行，需要通过 Native 桥接调用 Android 原生 SDK。

## HMS Account Kit 集成步骤

### 1. 添加依赖

在 Android 项目的 `build.gradle` 中添加：

```gradle
dependencies {
    implementation 'com.huawei.hms:hwid:6.12.0.300'
}
```

### 2. 创建 Native 桥接模块

在 Android Native 层创建桥接类，例如 `HMSAccountBridge.kt`：

```kotlin
class HMSAccountBridge {
    private val accountAuthManager: AccountAuthManager by lazy {
        AccountAuthManager.getService(context, AccountAuthParams.DEFAULT_AUTH_REQUEST_PARAM)
    }

    fun signIn(callback: (result: Map<String, String>) -> Unit) {
        val task = accountAuthManager.signIn()
        task.addOnSuccessListener { authAccount ->
            val result = mapOf(
                "unionID" to (authAccount.unionId ?: ""),
                "openID" to (authAccount.openId ?: ""),
                "displayName" to (authAccount.displayName ?: ""),
                "avatarUri" to (authAccount.avatarUriString ?: "")
            )
            callback(result)
        }.addOnFailureListener { e ->
            callback(mapOf("error" to e.message ?: "登录失败"))
        }
    }
}
```

### 3. 通过 JSI/FFI 桥接到 ArkUI X

在 ArkUI X 中通过 Native 桥接调用：

```typescript
// 在 HuaweiAuth.ts 中
static async login(): Promise<HuaweiUserInfo> {
  const result = await nativeBridge.call('HMSAccount.signIn')
  if (result.error) {
    throw new Error(result.error)
  }
  return {
    unionID: result.unionID,
    openID: result.openID,
    displayName: result.displayName,
    avatarUri: result.avatarUri
  }
}
```

### 4. SharedPreferences 桥接

类似地，创建 SharedPreferences 的 Native 桥接：

```kotlin
class PreferencesBridge {
    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences("steps_ohos", Context.MODE_PRIVATE)
    }

    fun putString(key: String, value: String) {
        prefs.edit().putString(key, value).apply()
    }

    fun getString(key: String, defaultValue: String): String {
        return prefs.getString(key, defaultValue) ?: defaultValue
    }
}
```

## 参考文档

- HMS Account Kit: https://developer.huawei.com/consumer/cn/doc/development/HMS-Guides/account-introduction-v4
- ArkUI X Native 桥接: 参考 DevEco Studio 官方文档

