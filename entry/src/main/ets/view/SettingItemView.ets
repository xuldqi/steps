import { router } from '@kit.ArkUI'
import { common, Want } from '@kit.AbilityKit'
// import { productViewManager } from '@kit.StoreKit'  // OpenHarmony不支持
// import { BusinessError } from '@kit.BasicServicesKit'  // OpenHarmony不支持
import { Log } from '../tools/Logger'

// 临时定义类型
interface BusinessError {
  code: number;
  message: string;
}

export interface SettingItemData {
  type:number,
  title: string,
  icon: Resource,
}
//计算器计算按钮
@Component
export struct SettingItemView {

  @State formData: SettingItemData = {
    type:0,
    title:'',
    icon: $r('app.media.setting_data_sport'),
  }

  build() {
    Row(){
      Image(this.formData.icon).width(22).height(22)
      Text(this.formData.title).layoutWeight(1).textAlign(TextAlign.Start).margin({left:15})
    }.width('100%').padding(12).onClick(() => {
      switch (this.formData.type){
        case 1:
          router.pushUrl({
            url: 'pages/SportRecordPage',
            params: { type:0, curTarget:'', subTopTitle:'', subTopData:'', subBotData: '', },
          })
          return
        case 2:
          router.pushUrl({ url: 'pages/BodyDataPage' })
          return
        case 3:
          return
        case 4:
          router.pushUrl({ url: 'pages/ListCollectPage' })
          return
        case 5:
          router.pushUrl({ url: 'pages/ListSharePage' })
          return
        case 6:
          const uiContext = getContext(this) as common.UIAbilityContext
          const wantParam: Want = {
            parameters: {
              bundleName: 'com.microtarget.step.ohs'
            }
          }
          // OpenHarmony环境下暂时注释掉StoreKit相关功能
          // const callback: productViewManager.ProductViewCallback = {
          //   onError: (error: BusinessError) => {
          //     Log.i( `loadProduct onError.code is ${error.code}, message is ${error.message}`);
          //   }
          // }
          // productViewManager.loadProduct(uiContext, wantParam, callback);
          Log.i('StoreKit功能在OpenHarmony环境下暂不支持');
          return
        case 7:
          router.pushUrl({ url: 'pages/AdvicePage' })
          return
      }

    })
  }
}
