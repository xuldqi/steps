
//计算器计算按钮
@Component
export struct BannerView {

  @State str1: string = '';
  @State str2:string='';
  @State img:Resource = $r('app.media.new_home_share_friend');

  build() {
    Stack(){
      Image(this.img).width('100%')
      Text(){
        Span(this.str1).fontSize(14).fontWeight(600).fontColor('#000000')
        Span(this.str2).fontSize(12).fontColor('#ff8f8f8f')
      }.textAlign(TextAlign.Start).layoutWeight(1)
    }.width('92%').margin({bottom:15})
  }
}