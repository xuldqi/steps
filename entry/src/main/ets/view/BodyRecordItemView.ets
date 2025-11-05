export interface BodyRecordData {
  data: string,
  img:Resource,
  time:string,
  hasData:boolean,
  recordType?: number,  // 记录类型
  onAddClick?: () => void  // 点击加号的回调
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
      Image(this.formData.img)
        .height(32)
        .width(32)
        .margin({ right: 12 })

      Column() {
        Text(this.formData.data)
          .fontSize(16)
          .fontWeight(500)
          .fontColor('#222222')
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(this.formData.time)
          .fontSize(12)
          .fontColor('#808080')
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ top: 4 })
          .visibility(this.formData.hasData ? Visibility.Visible : Visibility.None)
      }
      .layoutWeight(1)

      if (this.formData.recordType !== undefined && this.formData.onAddClick) {
        Image($r('app.media.add_all_record'))
          .width(20)
          .height(20)
          .margin({ left: 12 })
          .onClick(() => {
            if (this.formData.onAddClick) {
              this.formData.onAddClick()
            }
          })
      }
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .justifyContent(FlexAlign.SpaceBetween)
  }
}
