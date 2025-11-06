import { window } from '@kit.ArkUI'
import { TITLE_SAFE_TOP_OFFSET } from '../tools/UiConstants'

@Component
export struct CommonTitleView {
  data1: { str1: string } = { str1: '' }
  cancel: () => void = () => {}
  useSafeTop: boolean = true
  titleBackgroundColor?: string = '#F5F5F5'

  private getSafeTopPadding(): number {
    // ArkUI X Android 先用固定偏移兜底，后续可接入真实状态栏高度
    return Math.max(0, 0 - TITLE_SAFE_TOP_OFFSET)
  }

  build() {
    Column() {
      if (this.useSafeTop && this.getSafeTopPadding() > 0) {
        Blank().height(this.getSafeTopPadding()).backgroundColor(this.titleBackgroundColor)
      }

      Row() {
        Image($r('app.media.back_btn_dark'))
          .height(28)
          .width(28)
          .onClick(() => this.cancel())
        Text(this.data1.str1)
          .fontSize(18)
          .fontWeight(500)
          .fontColor('#000000')
          .margin({ left: 12 })
          .layoutWeight(1)
      }
      .height(56)
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.titleBackgroundColor)
    }
    .width('100%')
    .backgroundColor(this.titleBackgroundColor)
  }
}

