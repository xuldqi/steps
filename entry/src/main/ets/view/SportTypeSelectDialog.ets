interface SportTypeItem {
  id: number
  name: string
  icon: Resource
}

@CustomDialog
export struct SportTypeSelectDialog {
  @State selectedType: number = 0
  controller?: CustomDialogController = undefined
  onSelect: (type: number) => void = () => {}
  
  private sportTypes: Array<SportTypeItem> = [
    { id: 0, name: '全部运动', icon: $r('app.media.sport_run') },
    { id: 1, name: '室内跑步', icon: $r('app.media.sport_indoor_run') },
    { id: 2, name: '室外跑步', icon: $r('app.media.sport_run') },
    { id: 3, name: '健走', icon: $r('app.media.sport_go_walk') },
    { id: 4, name: '骑行', icon: $r('app.media.sport_run') },
    { id: 5, name: '爬山', icon: $r('app.media.sport_climb') }
  ]
  
  aboutToAppear() {
    // 确保 selectedType 已初始化
  }
  
  build() {
    Column() {
      Text('选择运动类型')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#222222')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })
      
      Grid() {
        ForEach(this.sportTypes, (type: SportTypeItem) => {
          GridItem() {
            Column() {
              Image(type.icon)
                .width(28)
                .height(28)
                .margin({ bottom: 6 })
              Text(type.name)
                .fontSize(14)
                .fontColor(this.selectedType === type.id ? '#0cc291' : '#666666')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ top: 14, bottom: 14 })
            .backgroundColor(this.selectedType === type.id ? '#E8F5E8' : '#F6F7FA')
            .borderRadius(12)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.selectedType = type.id
              this.onSelect(type.id)
              this.controller?.close()
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')
    }
    .width('100%')
    .padding({ top: 16, bottom: 20, left: 20, right: 20 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}

