import { router, window } from '@kit.ArkUI';
import EntryAbility from '../entryability/EntryAbility';

@Entry
@Component
struct WebPage {
  @State type: string = '';
  @State title: string = '';

  private getSafeTopPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 0
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return Math.max(0, avoidArea.topRect.height)
  }

  onPageShow(): void {
    const params = router.getParams() as Record<string, string>;
    this.type = params['type'];
    this.title = params['title'];
  }

  build() {
    Column() {
      Column() {
        Text(this.title)
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
        Text('网页功能')
          .fontSize(18)
          .fontWeight(500)
          .margin({ top: 40, bottom: 20 })
        
        Text('网页内容加载中...')
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Center)
    }
    .width('100%')
    .height('100%')
  }
}