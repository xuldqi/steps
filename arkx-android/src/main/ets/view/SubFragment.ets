import { router } from '@kit.ArkUI'
import { Utils } from '../tools/Utils'

export interface SubFragmentData {
  type: number
  curTarget: string
  subTopTitle: string
  subTopData: string // 总的运动里程
  subBotData: string // 运动底部提示
}

@Component
export struct SubFragment {
  @Prop formData: SubFragmentData = {
    type: 1,
    curTarget: '',
    subTopTitle: '',
    subTopData: '5',
    subBotData: '记录'
  }

  build() {
    Stack() {
      Image($r('app.media.setp_sub_background'))
        .width('100%')
        .height('100%')

      Column() {
        Text(this.formData.subTopTitle)
          .fontColor('#000000')
          .fontSize(14)
          .width('100%')
          .backgroundColor('#eaeaea')
          .padding({ bottom: 10, top: 10, left: 15 })

        Text() {
          Span(this.formData.subTopData)
            .fontSize(40)
            .fontColor('#000000')
            .fontWeight(500)
          Span('公里')
            .fontColor('#838383')
        }
        .textAlign(TextAlign.Start)
        .backgroundColor('#eaeaea')
        .width('100%')
        .padding({ bottom: 10, top: 5, left: 15 })

        Stack() {
          Image(Utils.getSubSportStartIcon(this.formData.type))
            .width('20%')
            .onClick(() => {
              router.pushUrl({
                url: 'pages/SportStartingPage',
                params: this.formData
              })
            })
            .alignSelf(ItemAlign.Center)
        }
        .align(Alignment.Center)
        .layoutWeight(1)

        Column() {
          Row() {
            Text('目标')
              .fontColor('#000000')
              .fontWeight(500)
            Text(this.formData.curTarget)
              .fontColor('#000000')
              .fontWeight(500)
            Image($r('app.media.right_point'))
              .width(18)
              .height(18)
              .margin({ right: 10 })
          }
          .width('95%')
          .borderRadius(10)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 5, top: 5, left: 10, right: 10 })
          .padding(12)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/SportTargetSetPage',
              params: this.formData
            })
          })

          Row() {
            Text(this.formData.subBotData)
              .fontColor('#000000')
              .fontSize(14)
            Image($r('app.media.right_point'))
              .width(18)
              .height(18)
              .margin({ right: 10 })
          }
          .width('95%')
          .borderRadius(10)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 5, top: 5, left: 10, right: 10 })
          .padding(12)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/SportRecordPage',
              params: this.formData
            })
          })
        }
        .width('100%')
        .height('25%')
        .backgroundColor('#eaeaea')
      }
      .layoutWeight(1)
    }
  }
}

