import { SportTarget, Utils } from '../tools/Utils'

interface SportTypeDialogProps {
  currentType: number
  onSelect: (type: number) => void
}

@Builder
export function SportTypeDialog(props: SportTypeDialogProps) {
  Column() {
    Text('选择运动类型')
      .fontSize(16)
      .fontWeight(500)
      .fontColor('#222222')
      .alignSelf(ItemAlign.Start)
      .margin({ bottom: 12 })

    Grid() {
      ForEach(Utils.getSportTypeList(), (item: SportTarget, index: number) => {
        GridItem() {
          Column() {
            Image(Utils.getSportRecordIcon(item.type))
              .width(28)
              .height(28)
              .margin({ bottom: 6 })

            Text(item.name)
              .fontSize(14)
              .fontColor(item.type === props.currentType ? '#0cc291' : '#666666')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding({ top: 14, bottom: 14 })
          .backgroundColor(item.type === props.currentType ? '#E8F5E8' : '#F6F7FA')
          .borderRadius(12)
          .onClick(() => {
            props.onSelect(item.type)
          })
        }
      }, (_item: SportTarget, idx: number) => `type-${idx}`)
    }
    .columnsTemplate('1fr 1fr 1fr')
    .rowsTemplate('auto auto auto')
    .rowsGap(12)
    .columnsGap(12)
    .width('100%')
  }
  .width('100%')
  .padding({ top: 16, bottom: 20, left: 20, right: 20 })
  .backgroundColor('#FFFFFF')
  .borderRadius(16)
}
