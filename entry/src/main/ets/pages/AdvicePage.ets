@Entry
@Component
struct AdvicePage {
  build() {
    Column() {
      Column() {
        Text('帮助与反馈')
          .fontSize(16)
          .height('100%')
          .alignSelf(ItemAlign.Center)
          .textAlign(TextAlign.Center)
          .fontColor('#0cc291')
      }.width('100%').height('7%').align(Alignment.Center)

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
      .height('91%')
      .align(Alignment.Center)
    }
  }
}