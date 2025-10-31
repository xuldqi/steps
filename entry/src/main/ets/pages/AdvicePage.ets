import { window } from '@kit.ArkUI';
import EntryAbility from '../entryability/EntryAbility';

@Entry
@Component
struct AdvicePage {
  private getSafeTopPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 0
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return Math.max(0, avoidArea.topRect.height)
  }

  build() {
    Column() {
      Column() {
        Text('帮助与反馈')
          .fontSize(16)
          .height('100%')
          .alignSelf(ItemAlign.Center)
          .textAlign(TextAlign.Center)
          .fontColor('#0cc291')
      }
      .width('100%')
      .height(56)
      .padding({ top: this.getSafeTopPadding() })
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)

      Column() {
      }.width('100%').height(1).backgroundColor('#f0f0f0')
      
      Column() {
        Text('帮助与反馈功能')
          .fontSize(18)
          .fontWeight(500)
          .margin({ top: 40, bottom: 20 })
        
        Text('如有问题请联系客服')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 20 })
        
        Text('客服电话：400-123-4567')
          .fontSize(14)
          .fontColor('#0cc291')
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Center)
    }
    .width('100%')
    .height('100%')
  }
}