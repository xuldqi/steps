import web_webview from '@ohos.web.webview';

@Entry
@Component
struct YSPage {
  @State message: string = '微步运动'
  //scroller: Scroller = new Scroller;
  controller: web_webview.WebviewController = new web_webview.WebviewController();

  onPageShow(): void {
    // let context = getContext() as common.UIAbilityContext;
    // try {
    //   context.resourceManager.getRawFileContent("ys.txt", (error: BusinessError, value: Uint8Array) => {
    //     if (error != null) {
    //       Log.i('error is :' + error);
    //     } else {
    //       let textDecoder = util.TextDecoder.create('gbk')
    //       this.message = textDecoder.decodeWithStream(value)
    //     }
    //   });
    // } catch (error) {
    //   let code = (error as BusinessError).code;
    //   let message = (error as BusinessError).message;
    //   Log.i(`callback getRawFileContent failed, error code: ${code}, message: ${message}.`);
    // }
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
      }.width('100%').height('7%').align(Alignment.Center)

      Column() {
      }.width('100%').height(1).backgroundColor('#f0f0f0')
      // Scroll(this.scroller){
      //   Text(this.message).width('100%')
      //     .height('1420%').textAlign(TextAlign.Start)
      //     .padding({left:10,right:10,top:10,bottom:10})
      // }.width('100%').height('91%').align(Alignment.TopStart)
      Web({ src: $rawfile("yszc.htm"), controller: this.controller })
        .width('100%').height('91%').align(Alignment.TopStart)
    }
  }
}