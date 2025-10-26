
@CustomDialog
export struct CommonDialog {

  @State title:string = ''
  @State content:string = ''

  controller?: CustomDialogController = undefined
  cancel: () => void = () => {
  }
  confirm: () => void = () => {
  }

  build() {
    Column() {
      Text(this.title).fontSize(22).margin({ top: 35 }).fontWeight(FontWeight.Bold)
      Text(this.content){

      }.fontSize(15)
        .padding({ top: 25,left:35,right:35,bottom:25 })
      Blank()

      Row() {
        Text('拒绝')
          .width('50%')
          .height(50)
          .backgroundColor('#ffbebebe')
          .fontColor(Color.White)
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.cancel() //调用回调
          })
        Text('同意')
          .width('50%')
          .height(50)
          .backgroundColor('#0cc291')
          .fontColor(Color.White)
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.confirm() //调用回调
          })
      }
    }.width('100%').height('AUTO')
  }
}
