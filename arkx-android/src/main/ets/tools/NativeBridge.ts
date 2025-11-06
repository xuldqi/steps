// ArkUI X Native 桥接调用封装
// Android 侧需提供同名通道；这里做存在性检测与安全回退

type AnyMap = { [key: string]: any }

declare const globalThis: any

export const NativeBridge = {
  async call(service: string, method: string, params?: AnyMap): Promise<any> {
    try {
      const bridge = (globalThis as AnyMap)?.nativeBridge
      if (bridge && typeof bridge.call === 'function') {
        return await bridge.call(`${service}.${method}`, params || {})
      }
      // 无桥接实现时，返回 undefined 以便上层做降级
      return undefined
    } catch (e) {
      console.error('[NativeBridge] 调用失败:', service, method, e)
      return undefined
    }
  }
}


