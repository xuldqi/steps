export interface BodyRecordData {
  data: string,
  img:Resource,
  time:string,
  hasData:boolean,
}


//计算器计算按钮
@Component
export struct BodyRecordItemView {
  @State formData: BodyRecordData = {
    data:'',
    img: $r('app.media.new_home_share_friend'),
    time:'',
    hasData:false
  }

  build() {
    Row() {
      Image(this.formData.img).height(27).width(27)
      Column(){
        Text(this.formData.data).padding(5).width('100%').textAlign(TextAlign.Start)
        Text(this.formData.time).padding(5).fontSize(12).fontColor('#ff808080').width('100%').textAlign(TextAlign.Start)
          .visibility(this.formData.hasData? Visibility.Visible:Visibility.None)
      }

    }.width('90%').backgroundColor('#FFFFFF').borderRadius(15).padding(10).margin({top:15})
  }
}