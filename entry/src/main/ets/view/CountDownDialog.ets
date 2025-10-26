
@CustomDialog
export struct CountDownDialog {

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
    }.width('100%').height('100%')
  }
}
