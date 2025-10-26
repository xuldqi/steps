
//计算器计算按钮
@Component
export struct SubBannerTextView {

  build() {
    Text(){
      Span('设定目标\n').fontSize(15).fontColor('#000000').fontWeight(500)
      Span('有目标才有动力').fontSize(13).fontColor('#ff838383').padding({top:5})
    }.textAlign(TextAlign.Start).layoutWeight(1).padding({bottom:10,top:10,left:15})
  }
}