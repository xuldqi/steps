import { router } from '@kit.ArkUI'

export interface TopData {
  curSteps: string // 当前步数
  tarSteps: string // 目标步数
  tarStepsPer: number // 当前步数进度，满格100%
  tarStepsPerStr: string // 当前步数进度百分比字符
  tarStepsHintStr: string // 当前步数目标提醒
}

@Component
export struct MainTopView {
  @State formData: TopData = {
    curSteps: '2000',
    tarSteps: '/5000步',
    tarStepsPer: 20,
    tarStepsPerStr: '20%',
    tarStepsHintStr: '还差3000步达到目标'
  }

  build() {
    Column() {
      Row() {
        Text('今日步数')
          .layoutWeight(1)
          .padding(3)
          .fontSize(15)
          .fontColor('#FFFFFF')
        Text('目标管理')
          .width(80)
          .padding(3)
          .textAlign(TextAlign.Center)
          .fontSize(13)
          .fontColor('#0cc291')
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .onClick(() => {
            router.pushUrl({ url: 'pages/TargetManagementPage' })
          })
      }
      .margin(10)
      .alignItems(VerticalAlign.Center)

      Row() {
        Text() {
          Span(this.formData.curSteps)
            .fontSize(30)
          Span(this.formData.tarSteps)
        }
        .textAlign(TextAlign.Start)
        .fontColor('#FFFFFF')
        .layoutWeight(1)

        Stack() {
          Progress({ value: this.formData.tarStepsPer, total: 100, type: ProgressType.Ring })
            .width(40)
            .height(40)
            .color('#FFFFFF')
          Text(this.formData.tarStepsPerStr)
            .fontSize(10)
            .fontColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .alignContent(Alignment.Center)
      }
      .margin(10)
      .alignItems(VerticalAlign.Bottom)

      Text(this.formData.tarStepsHintStr)
        .fontSize(10)
        .fontColor('#FFFFFF')
        .margin(10)
        .alignSelf(ItemAlign.Start)
    }
    .padding(5)
    .backgroundColor('#0cc291')
    .borderRadius(20)
    .width('95%')
    .onClick(() => {
      router.pushUrl({ url: 'pages/StepTrendPage' })
    })
  }
}

