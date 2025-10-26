import { Utils } from '../tools/Utils';
import { SubBannerTextView } from './SubBannerTextView';
import { SubBannerView } from './SubBannerView';
import { router } from '@kit.ArkUI';

export interface SubFragmentData {
  type:number,
  curTarget:string,
  subTopTitle:string,
  subTopData: string, // 当前步数
  subBotData: string, //目标步数
}

//计算器计算按钮
@Component
export struct SubFragment {

  @State formData: SubFragmentData = {
    type:1,
    curTarget:'',
    subTopTitle:'', // 当前步数
    subTopData:'5', // 当前步数
    subBotData: '记录', //目标步数
  }

  build() {
    Stack(){
      Image($r('app.media.setp_sub_background')).width('100%').height('100%')
      Column(){
        Text(this.formData.subTopTitle).fontColor('#000000').fontSize(14).width('100%').backgroundColor('#ffeaeaea').padding({bottom:10,top:10,left:15})
        Text(){
          Span(this.formData.subTopData).fontSize(40).fontColor('#000000').fontWeight(500)
          Span('公里').fontColor('#ff838383')
        }.textAlign(TextAlign.Start).backgroundColor('#ffeaeaea').width('100%').padding({bottom:10,top:5,left:15})
        Stack(){
          Image(Utils.getSubSportStartIcon(this.formData.type)).width('20%').onClick(() => {
            router.pushUrl({
              url: 'pages/SportStartingPage',
              params: this.formData,
            })
          }).alignSelf(ItemAlign.Center)
        }.align(Alignment.Center).layoutWeight(1)
        Column(){
          Row(){
            SubBannerTextView()
            Text(this.formData.curTarget).fontColor('#000000').fontWeight(500)
            Image($r('app.media.right_point')).width(18).height(18).margin({right:10})
          }.width('95%').borderRadius(10).backgroundColor('#FFFFFF').margin({bottom:5,top:5,left:10,right:10})
          .onClick(() => {
            router.pushUrl({
              url: 'pages/SportTargetSetPage',
              params: this.formData,
            })
          })
          SubBannerView({str1:this.formData.subBotData}).onClick(() => {
            router.pushUrl({
              url: 'pages/SportRecordPage',
              params: this.formData,
            })
          })
        }.width('100%').height('25%').backgroundColor('#ffeaeaea')

      }.layoutWeight(1)
    }
  }
}