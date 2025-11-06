import { router } from '@kit.ArkUI'
import { Utils } from '../tools/Utils'
import appDataManager from '../tools/AppDataManager'

export interface MainCardData {
  item: number
  index: number
  subtitle?: string
  value?: string
  prevTitle?: string
  prevValue?: string
}

@Component
export struct MainCardView {
  @Prop formData: MainCardData = {
    item: 0,
    index: 0
  }
  @State mainCardH: string = '27%'
  @State mainCardIconH: string = '40%'

  build() {
    Stack() {
      Column() {
        Text(Utils.getMainCardStr(this.formData.item))
          .fontColor('#000000')
          .fontSize(17)
        Text(this.formData.subtitle ?? appDataManager.getMainCardSubStr(this.formData.item))
          .fontColor('#8f8f8f')
          .fontSize(13)
          .margin({ top: 5 })
        Text(this.formData.value ?? appDataManager.getMainCardSubData(this.formData.item))
          .fontColor('#000000')
          .fontSize(appDataManager.getMainCardSubDataSize(this.formData.item))
          .margin({ top: 5 })
          .fontWeight(appDataManager.getMainCardSubDataWeight(this.formData.item))
        Column()
          .layoutWeight(1)
        if ((this.formData.prevTitle ?? appDataManager.getMainCardLastTitle(this.formData.item)) !== '' &&
          (this.formData.prevValue ?? appDataManager.getMainCardLastData(this.formData.item)) !== '') {
          Text(this.formData.prevTitle ?? appDataManager.getMainCardLastTitle(this.formData.item))
            .fontColor('#8f8f8f')
            .fontSize(13)
          Text(this.formData.prevValue ?? appDataManager.getMainCardLastData(this.formData.item))
            .fontColor('#8f8f8f')
            .fontSize(16)
            .margin({ top: 5 })
            .fontWeight(500)
        }
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(10)

      Image(Utils.getMainCardIcon(this.formData.item))
        .width(this.mainCardIconH)
        .height(this.mainCardIconH)
        .borderRadius({ bottomRight: 15 })
    }
    .height('96%')
    .width('47%')
    .backgroundColor('#FFFFFF')
    .borderRadius(15)
    .alignContent(Alignment.BottomEnd)
    .margin({ left: this.formData.index === 1 ? '6%' : '0%' })
    .onClick(() => {
      Utils.toMainCardPage(this.formData.item)
    })
  }
}

