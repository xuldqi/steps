import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import { HuaweiAuth, HuaweiUserInfo } from '../tools/HuaweiAuth'
import preferencesUtil from '../tools/PreferencesUtil'

@Entry
@Component
struct LoginPage {
  @State private isProcessing: boolean = false

  private goPrivacy() {
    router.pushUrl({ url: 'pages/YSPage' })
  }

  private goAgreement() {
    router.pushUrl({ url: 'pages/XYPage' })
  }

  private async performHuaweiLogin(): Promise<void> {
    if (this.isProcessing) {
      return
    }
    this.isProcessing = true
    try {
      const userInfo = await HuaweiAuth.login()
      await this.handleLogin(userInfo)
    } catch (error) {
      const message = (error as Error)?.message ?? '登录失败，请稍后重试'
      console.error('[LoginPage] 登录失败:', message)
      // TODO: 显示 Toast 提示
      this.isProcessing = false
    }
  }

  private async handleLogin(userInfo: HuaweiUserInfo): Promise<void> {
    const resolvedId = (userInfo.unionID?.trim() ?? userInfo.openID?.trim() ?? '')
    if (resolvedId.length === 0) {
      console.error('[LoginPage] 未获取到华为账号 ID')
      this.isProcessing = false
      return
    }
    try {
      const displayName = userInfo.displayName?.trim() ?? '华为账号用户'
      await preferencesUtil.putPreferenceValue('steps_ohos', 'userNickname', displayName)
      await preferencesUtil.putPreferenceValue('steps_ohos', 'userName', displayName)
      if (userInfo.avatarUri) {
        await preferencesUtil.putPreferenceValue('steps_ohos', 'userAvatarUri', userInfo.avatarUri)
      }
      // TODO: 保存 unionId 到本地，用于后续自动登录
      await preferencesUtil.putPreferenceValue('steps_ohos', 'unionId', resolvedId)
      
      console.info('[LoginPage] 登录成功:', displayName)
      // TODO: 显示 Toast 提示
      router.back()
    } catch (error) {
      const message = (error as Error)?.message ?? '登录失败，请稍后重试'
      console.error('[LoginPage] 处理登录失败:', message)
      // TODO: 显示 Toast 提示
    } finally {
      this.isProcessing = false
    }
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '登录' },
        cancel: () => {
          router.back()
        },
        useSafeTop: true,
        titleBackgroundColor: '#F5F5F5'
      })
      
      Column() {
        Image($r('app.media.icon'))
          .width(96)
          .height(96)
          .borderRadius(24)
          .margin({ bottom: 24 })

        Text('欢迎使用')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ bottom: 8 })

        Text('使用华为账号登录，享受完整功能')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 40 })

        Row() {
          Image($r('app.media.icon'))
            .width(24)
            .height(24)
            .margin({ right: 8 })

          Text(this.isProcessing ? '登录中...' : '华为账号登录')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width('80%')
        .height(48)
        .backgroundColor('#0cc291')
        .borderRadius(24)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          if (!this.isProcessing) {
            void this.performHuaweiLogin()
          }
        })
        .margin({ bottom: 20 })

        Row() {
          Text('查看《隐私政策》')
            .fontSize(12)
            .fontColor('#0cc291')
            .onClick(() => this.goPrivacy())
          Text('  |  ')
            .fontSize(12)
            .fontColor('#999999')
          Text('查看《用户协议》')
            .fontSize(12)
            .fontColor('#0cc291')
            .onClick(() => this.goAgreement())
        }
        .margin({ top: 40 })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 24, right: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

