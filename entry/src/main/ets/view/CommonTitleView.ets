
import { window } from '@kit.ArkUI'
import EntryAbility from '../entryability/EntryAbility'
import { TITLE_SAFE_TOP_OFFSET } from '../tools/UiConstants'

export interface CommonTitleData {
  str1: string,
}

@Component
export struct CommonTitleView {

  @State data1: CommonTitleData = {
    str1:''
  };

  @State str2: string = ''
  cancel: () => void = () => {
  }
  useSafeTop: boolean = true
  titleBackgroundColor?: string = undefined

  private getSafeTopPadding(): number {
    if (!this.useSafeTop || !EntryAbility.myWindowClass) {
      return 0
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    // 与首页保持一致：状态栏高度基础上再减去统一参数，避免标题下移
    const full = Math.max(0, avoidArea.topRect.height)
    return Math.max(0, full - TITLE_SAFE_TOP_OFFSET)
  }

  build() {
    Column(){
      if (this.getSafeTopPadding() > 0) {
        Blank()
          .height(this.getSafeTopPadding())
          .backgroundColor(this.titleBackgroundColor || '#FFFFFF')
      }

      Row() {
        Image($r('app.media.back_btn_dark'))
          .height(28)
          .width(28)
          .onClick(() => {
            this.cancel()
          })
        Text(this.data1.str1)
          .fontSize(18)
          .fontWeight(500)
          .fontColor('#000000')
          .margin({ left: 12 })
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
        if (this.str2 && this.str2.length > 0) {
          Text(this.str2)
            .fontSize(12)
            .fontColor('#4c4c4c')
        }
      }
      .height(56)
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.titleBackgroundColor || '#FFFFFF')
    }
    .width('100%')
    .backgroundColor(this.titleBackgroundColor || '#FFFFFF')
  }
}
