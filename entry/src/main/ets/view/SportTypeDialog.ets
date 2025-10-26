import { SportTarget, Utils } from '../tools/Utils'

@CustomDialog
export struct SportTypeDialog {

  controller?: CustomDialogController = undefined
  onSelect: (type:number) => void = () => {
  }

  @State currentIndex:number = 0


  build() {
    Column() {
      // 只显示前6个运动类型，分两行显示
      Grid() {
        ForEach(Utils.getSportTypeList().slice(0, 6), (item: SportTarget, index: number) => {
          GridItem() {
            Column() {
              Image(Utils.getSportRecordIcon(item.type))
                .width(40)
                .height(40)
                .margin({ bottom: 8 })
              
              Text(item.name)
                .fontSize(12)
                .fontColor(this.currentIndex === index ? '#FFFFFF' : '#333333')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .height(80)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.currentIndex === index ? '#0cc291' : '#F8F8F8')
            .borderRadius(8)
            .onClick(() => {
              this.currentIndex = index
              // 延迟调用确保状态更新后再执行回调
              setTimeout(() => {
                this.onSelect(item.type)
              }, 100)
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .width('100%')
      .height(160)
      .padding(16)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}
