import { CommonTitleView } from '../view/CommonTitleView'
import { router } from '@kit.ArkUI'

@Entry
@Component
struct SettingPage {
  @State version: string = '1.2.0'

  onPageShow(): void {
    // TODO: 通过 Native 桥接获取版本号
    // const bundleInfo = await NativeBridge.call('App', 'getVersion')
    // this.version = bundleInfo?.versionName || '1.2.0'
  }

  private copyToClipboard(text: string) {
    // TODO: 通过 Native 桥接复制到剪贴板
    // await NativeBridge.call('Clipboard', 'setText', { text })
    console.info('[SettingPage] 复制到剪贴板:', text)
    // TODO: 显示 Toast 提示
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '设置' },
        cancel: () => {
          router.back()
        },
        useSafeTop: true
      })

      Scroll() {
        Column() {
          // 协议区域
          Column() {
            Row() {
              Text('用户协议')
                .layoutWeight(1)
              Image($r('app.media.right_point'))
                .width(15)
                .height(15)
            }
            .width('100%')
            .padding(12)
            .onClick(() => {
              router.pushUrl({ url: 'pages/XYPage' })
            })

            Row() {
              Text('隐私协议')
                .layoutWeight(1)
              Image($r('app.media.right_point'))
                .width(15)
                .height(15)
            }
            .width('100%')
            .padding(12)
            .onClick(() => {
              router.pushUrl({ url: 'pages/YSPage' })
            })
          }
          .width('91%')
          .margin(15)
          .borderRadius(15)
          .backgroundColor('#FFFFFF')

          // 信息区域
          Column() {
            Row() {
              Text('公众号')
                .layoutWeight(1)
              Text('微小目标(micro-target)')
                .fontColor('#676767')
            }
            .width('100%')
            .padding(12)
            .onClick(() => {
              this.copyToClipboard('micro-target')
            })

            Row() {
              Text('版本号')
                .layoutWeight(1)
              Text(this.version)
                .fontColor('#676767')
            }
            .width('100%')
            .padding(12)
          }
          .width('91%')
          .margin(15)
          .borderRadius(15)
          .backgroundColor('#FFFFFF')
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

