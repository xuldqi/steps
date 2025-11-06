// 仅示例：Android 原生桥接占位（需放入实际 Android 模块）
package com.microtarget.stepx.bridge

class HMSAccountBridge {
    fun signIn(): Map<String, String> {
        // TODO: 调用 HMS Account Kit 完成登录，并返回 map
        return mapOf(
            "unionID" to "",
            "openID" to "",
            "displayName" to "",
            "avatarUri" to ""
        )
    }

    fun signOut() {}

    fun isSignedIn(): Boolean = false
}


