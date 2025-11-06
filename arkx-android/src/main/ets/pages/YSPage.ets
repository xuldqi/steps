import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'

@Entry
@Component
struct YSPage {
  // TODO: ArkUI X 的 Web 组件 API 可能不同，需要适配
  // 如果 ArkUI X 不支持 Web 组件，可以使用 Text 组件显示协议内容

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '隐私协议' },
        cancel: () => {
          router.back()
        },
        titleBackgroundColor: '#F5F5F5',
        useSafeTop: true
      })

      // 方案 A：如果 ArkUI X 支持 Web 组件
      // Web({ src: $rawfile("yszc.htm") })
      //   .layoutWeight(1)
      //   .width('100%')

      // 方案 B：如果 ArkUI X 不支持 Web 组件，使用 Scroll + Text 显示
      Scroll() {
        Column() {
          Text('隐私协议内容')
            .fontSize(16)
            .fontColor('#333333')
            .lineHeight(24)
            .padding(20)
          // TODO: 从 rawfile 读取 HTML 内容并转换为纯文本显示
          // 或使用 Native 桥接加载 HTML 内容
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

