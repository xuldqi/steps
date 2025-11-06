// 仅示例：Android 原生桥接占位（需放入实际 Android 模块）
package com.microtarget.stepx.bridge

class PreferencesBridge {
    fun open(name: String) {}
    fun putString(name: String, key: String, value: String) {}
    fun getString(name: String, key: String, defaultValue: String): String = defaultValue
}


