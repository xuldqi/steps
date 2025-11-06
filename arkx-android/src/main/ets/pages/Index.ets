import { router } from '@kit.ArkUI'
import preferencesUtil from '../tools/PreferencesUtil'

@Entry
@Component
struct Index {
  @State timerId: number = 0

  async onPageShow() {
    const isFirst = await preferencesUtil.getPreferenceValue('steps_ohos', 'isFirstOpenApp', 'true')
    if (isFirst === 'true') {
      // TODO: 显示协议对话框
      // 暂时直接接受协议
      await preferencesUtil.putPreferenceValue('steps_ohos', 'isFirstOpenApp', 'false')
      await preferencesUtil.putPreferenceValue('steps_ohos', 'step_target', '5000')
    }
    
    // 延迟1秒后跳转到主页面
    this.timerId = setTimeout(() => {
      this.jumpToMain()
    }, 1000) as unknown as number
  }

  onPageHide() {
    if (this.timerId) {
      clearTimeout(this.timerId)
    }
  }

  private jumpToMain() {
    // TODO: 尝试静默登录
    // 暂时直接跳转
    router.replaceUrl({ url: 'pages/MainTabs' })
  }

  private getSafeBottomPadding(): number {
    // 简化版：固定底部安全区
    return 48
  }

  build() {
    Column() {
      Stack() {
        Text() {
          Span('在\n')
          Span('于\n')
          Span('运\n')
          Span('动\n')
          Span('。')
        }
        .fontSize(15)
        .width(20)
        .height(130)
        .margin({ right: 20 })
        .align(Alignment.TopStart)

        Text('生\n命\n,')
          .fontSize(15)
          .width(20)
          .height(130)
          .margin({ left: 20 })
          .align(Alignment.TopStart)
      }
      .width('100%')
      .layoutWeight(1)
      .alignContent(Alignment.Center)

      Row() {
        Image($r('app.media.icon'))
          .height(64)
          .width(64)
          .borderRadius(10)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: this.getSafeBottomPadding() })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

