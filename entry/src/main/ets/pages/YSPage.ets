import web_webview from '@ohos.web.webview';
import { window } from '@kit.ArkUI';
import EntryAbility from '../entryability/EntryAbility';

@Entry
@Component
struct YSPage {
  @State message: string = '微步运动'
  controller: web_webview.WebviewController = new web_webview.WebviewController();

  private getSafeTopPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 0
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return Math.max(0, avoidArea.topRect.height)
  }

  onPageShow(): void {
  }

  build() {
    Column() {
      Column() {
        Text('隐私协议')
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
      
      Web({ src: $rawfile("yszc.htm"), controller: this.controller })
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
  }
}
