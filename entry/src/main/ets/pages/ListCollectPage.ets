import web_webview from '@ohos.web.webview';

@Entry
@Component
struct XYPage {
  controller: web_webview.WebviewController = new web_webview.WebviewController();


  build() {
    Column() {
      Column() {
        Text('个人信息手机清单')
          .fontSize(16)
          .height('100%')
          .alignSelf(ItemAlign.Center)
          .textAlign(TextAlign.Center)
          .fontColor('#0cc291')
      }.width('100%').height('7%').align(Alignment.Center)

      Column() {
      }.width('100%').height(1).backgroundColor('#f0f0f0')
      Web({ src: $rawfile("list_collect.html"), controller: this.controller })
        .width('100%').height('91%').align(Alignment.TopStart)
    }
  }
}