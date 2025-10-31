import web_webview from '@ohos.web.webview';
import { window } from '@kit.ArkUI';
import EntryAbility from '../entryability/EntryAbility';

@Entry
@Component
struct XYPage {
  controller: web_webview.WebviewController = new web_webview.WebviewController();

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
        Text('个人信息共享清单')
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
      
      Web({ src: $rawfile("list_share.html"), controller: this.controller })
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
  }
}