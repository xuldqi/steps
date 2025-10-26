export interface WeekSportData {
  img: Resource,
  title: string,
  times: number,
  long: string,
}
//计算器计算按钮
@Component
export struct WeekSportView {

  @State formData:WeekSportData = {
    img:$r('app.media.sport_indoor_run'),
    title:'户外跑',
    times:0,
    long:'0'
  }

  build() {
    Column(){
      Row(){
        Image(this.formData.img).width(25).height(25)
        Text(this.formData.title)
      }.width('100%').margin({top:5,bottom:10})
      Row(){
        Text(){
          Span('运动次数\n').fontColor('#ff535353')
          Span(this.formData.times.toString()).fontWeight(600).fontSize(28)
          Span('次')
        }.layoutWeight(1)
        Text(){
          Span('总距离\n').fontColor('#ff535353')
          Span(this.formData.long).fontWeight(600).fontSize(28)
          Span('公里')
        }.layoutWeight(1)
      }.width('100%')
    }.width('92%').padding(15).backgroundColor('#FFFFFF').borderRadius(15).margin({bottom:10})
  }
}