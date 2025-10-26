
//计算器计算按钮
@Component
export struct SubBannerView {

  @State str1: string = '';

  build() {
    Row(){
      Text(){
        Span(this.str1).fontSize(15).fontColor('#000000').fontWeight(500)
        Span('\n知晓过去才能遇见未来').fontSize(13).fontColor('#ff838383').padding({top:5})
      }.textAlign(TextAlign.Start).layoutWeight(1).padding({bottom:10,top:10,left:15})
    }.width('95%').borderRadius(10).backgroundColor('#FFFFFF').margin({bottom:5,top:1,left:10,right:10})
  }
}