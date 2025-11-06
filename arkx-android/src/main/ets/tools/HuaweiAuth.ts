// 华为账号登录适配（Android 版本）
// 注意：ArkUI X 需要通过 Native 桥接调用 HMS Account Kit (Android)
// 当前为占位实现，实际需要：
// 1. 在 Android Native 层集成 HMS Account Kit SDK
// 2. 通过 Native 桥接（如 JSI/FFI）调用登录接口
// 3. 将登录结果回调到 ArkUI X 层

export interface HuaweiUserInfo {
  unionID?: string
  openID?: string
  displayName?: string
  avatarUri?: string
}

import { NativeBridge } from './NativeBridge'

export class HuaweiAuth {
  /**
   * 执行华为账号登录（Android 版本）
   * 
   * 实现说明：
   * 1. 需要在 Android Native 层集成 HMS Account Kit SDK
   * 2. 使用 AccountAuthManager.signIn() 进行登录
   * 3. 获取 UnionID、OpenID、DisplayName、AvatarUri
   * 4. 通过 Native 桥接将结果返回给 ArkUI X
   * 
   * 参考文档：
   * https://developer.huawei.com/consumer/cn/doc/development/HMS-Guides/account-introduction-v4
   */
  static async login(): Promise<HuaweiUserInfo> {
    // 优先走 Native 桥接
    const bridged = await NativeBridge.call('HMSAccount', 'signIn', {
      scopes: ['https://www.huawei.com/auth/account/base.profile', 'openid']
    })
    if (bridged && !bridged.error) {
      const userInfo: HuaweiUserInfo = {
        unionID: bridged.unionID,
        openID: bridged.openID,
        displayName: bridged.displayName,
        avatarUri: bridged.avatarUri
      }
      return userInfo
    }

    // 无桥接或失败时使用占位实现（便于联调 UI）
    return new Promise((resolve) => {
      setTimeout(() => {
        const userInfo: HuaweiUserInfo = {
          unionID: 'mock_union_id_' + Date.now(),
          openID: 'mock_open_id_' + Date.now(),
          displayName: '华为账号用户',
          avatarUri: ''
        }
        console.info('[HuaweiAuth Android] 登录成功（占位）:', JSON.stringify(userInfo))
        resolve(userInfo)
      }, 600)
    })
  }

  /**
   * 登出
   */
  static async logout(): Promise<void> {
    await NativeBridge.call('HMSAccount', 'signOut')
    console.info('[HuaweiAuth Android] 登出（桥接/占位）')
  }

  /**
   * 检查登录状态
   */
  static async checkLoginStatus(): Promise<boolean> {
    const res = await NativeBridge.call('HMSAccount', 'isSignedIn')
    return !!res
  }
}

