
export interface Common2TitleData {
  str1: string,
}

//计算器计算按钮
@Component
export struct Common2TitleView {

  @State data1: Common2TitleData = {
    str1:''
  };

  cancel: () => void = () => {
  }

  click: () => void = () => {
  }

  build() {
    Column(){


      Stack() {
        Row(){
          Text(this.data1.str1)
            .fontSize(16)
            .alignSelf(ItemAlign.Center)
            .textAlign(TextAlign.Start).fontWeight(500)
            .fontColor('#000000').height('100%')
            Image($r('app.media.down_btn_')).height(15).width(15).margin({left:5})
        }.padding({left:35}).height('100%').onClick(() => {
          this.click()
        })
        Image($r('app.media.back_btn_dark')).height(27).width(27).onClick(() => {
          this.cancel()
        }).alignSelf(ItemAlign.Start)
      }.width('100%').height('7%').align(Alignment.Start).padding({left:10,right:10})
      Column() {
      }.width('100%').height(0.5).backgroundColor('#ffe0e0e0')
    }
  }
}