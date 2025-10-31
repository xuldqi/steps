import { router } from '@kit.ArkUI'
import { common, featureAbility, Want } from '@kit.AbilityKit'
// import { productViewManager } from '@kit.StoreKit'  // OpenHarmony不支持
// import { BusinessError } from '@kit.BasicServicesKit'  // OpenHarmony不支持
import { Log } from '../tools/Logger'
import { Utils } from '../tools/Utils'
import appDataManager from '../tools/AppDataManager'

// 临时定义类型
interface BusinessError {
  code: number;
  message: string;
}

export interface MainCardData {
  item:number,
  index: number,
  subtitle?: string,
  value?: string,
  prevTitle?: string,
  prevValue?: string,
}
//计算器计算按钮
@Component
export struct MainCardView {

  @State formData: MainCardData = {
    item:0,
    index:0,
  }
  @State mainCardH: string = '27%'//卡片高度
  @State mainCardIconH: string = '40%'//卡片内部图片高度

  build() {
    Stack() {
      Column() {
        Text(Utils.getMainCardStr(this.formData.item)).fontColor('#000000').fontSize(17)
        Text(this.formData.subtitle ?? appDataManager.getMainCardSubStr(this.formData.item))
          .fontColor('#ff8f8f8f').fontSize(13).margin({top:5})
        Text(this.formData.value ?? appDataManager.getMainCardSubData(this.formData.item)).fontColor('#000000')
          .fontSize(appDataManager.getMainCardSubDataSize(this.formData.item)).margin({top:5})
          .fontWeight(appDataManager.getMainCardSubDataWeight(this.formData.item))
        Column().layoutWeight(1)
        if ((this.formData.prevTitle ?? appDataManager.getMainCardLastTitle(this.formData.item)) !== '' &&
          (this.formData.prevValue ?? appDataManager.getMainCardLastData(this.formData.item)) !== '') {
          Text(this.formData.prevTitle ?? appDataManager.getMainCardLastTitle(this.formData.item)).fontColor('#ff8f8f8f').fontSize(13)
          Text(this.formData.prevValue ?? appDataManager.getMainCardLastData(this.formData.item)).fontColor('#ff8f8f8f').fontSize(16).margin({top:5}).fontWeight(500)
        }
      }.width('100%').height('100%').alignItems(HorizontalAlign.Start).padding(10)
      Image(Utils.getMainCardIcon(this.formData.item)).width(this.mainCardIconH).height(this.mainCardIconH).borderRadius({bottomRight:15})
    }.height('96%').width('47%').backgroundColor('#FFFFFF').borderRadius(15).alignContent(Alignment.BottomEnd)
    .margin({left:this.formData.index == 1 ? '6%' : '0%'})
    .onClick(() => {
      Utils.toMainCardPage(this.formData.item)
    })
  }
}
