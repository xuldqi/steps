import web_webview from '@ohos.web.webview';
import { router } from '@kit.ArkUI';
import { CommonTitleView } from '../view/CommonTitleView';

@Entry
@Component
struct YSPage {
  controller: web_webview.WebviewController = new web_webview.WebviewController();

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '隐私协议' },
        cancel: () => { router.back(); },
        titleBackgroundColor: '#F5F5F5',
        useSafeTop: true
      })

      Web({ src: $rawfile("yszc.htm"), controller: this.controller })
        .layoutWeight(1)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
