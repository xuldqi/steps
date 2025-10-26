
export interface CommonTitleData {
  str1: string,
}

//计算器计算按钮
@Component
export struct CommonTitleView {

  @State data1: CommonTitleData = {
    str1:''
  };

  @State str2: string = ''
  cancel: () => void = () => {
  }

  build() {
    Column(){


      Stack() {
        Row(){
          Text(this.data1.str1)
            .fontSize(16)
            .height('100%')
            .layoutWeight(1)
            .textAlign(TextAlign.Start).fontWeight(500)
            .fontColor('#000000').height('100%')
          Text(this.str2)
            .fontSize(12)
            .height('100%')
            .layoutWeight(1)
            .textAlign(TextAlign.End)
            .fontColor('#ff4c4c4c').height('100%')
        }.padding({left:35,right:10})
        Image($r('app.media.back_btn_dark')).height(27).width(27).onClick(() => {
          this.cancel()
        }).alignSelf(ItemAlign.Start)
      }.width('100%').height('7%').align(Alignment.Start).padding({left:10,right:10})
      Column() {
      }.width('100%').height(0.5).backgroundColor('#ffe0e0e0')
    }
  }
}