
import { window } from '@kit.ArkUI'
import EntryAbility from '../entryability/EntryAbility'

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

  private getSafeTopPadding(): number {
    if (!this.useSafeTop || !EntryAbility.myWindowClass) {
      return 0
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return Math.max(0, avoidArea.topRect.height - 80)
  }

  build() {
    Column(){
      if (this.getSafeTopPadding() > 0) {
        Blank().height(this.getSafeTopPadding())
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
    }
  }
}
