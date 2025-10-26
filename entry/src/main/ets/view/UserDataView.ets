export interface UserData {
  title: string,
  subTitle: string,
  data: string,
  subData: string,
}
//计算器计算按钮
@Component
export struct UserDataView {

  @State formData: UserData = {
    title:'',
    subTitle: '',
    data: '',
    subData: ''
  }

  build() {
    Text(){
      Span(this.formData.title).fontSize(15).fontColor('#000000').margin(15)
      Span('\n').fontSize(6)
      Span('\n').fontSize(6)
      Span(this.formData.subTitle).fontSize(11).fontColor('#ff727272').margin(15)
      Span('\n').fontSize(6)
      Span('\n').fontSize(6)
      Span(this.formData.data).fontSize(18).fontColor('#000000').fontWeight(600).margin(15)
      Span('\n').fontSize(6)
      Span('\n').fontSize(6)
      Span(this.formData.subData).fontSize(11).fontColor('#ff727272').margin(15)
    }.width('46%').borderRadius(15).backgroundColor('#FFFFFF').margin('2%').padding(10)
  }
}