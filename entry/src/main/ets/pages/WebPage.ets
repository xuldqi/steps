import { router } from '@kit.ArkUI';

@Entry
@Component
struct WebPage {
  @State type: string = '';
  @State title: string = '';

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
      }.width('100%').height('7%').align(Alignment.Center)

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
      .height('91%')
      .align(Alignment.Center)
    }
  }
}