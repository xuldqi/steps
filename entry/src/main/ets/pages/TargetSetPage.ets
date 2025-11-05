import { router, window } from '@kit.ArkUI';
import preferencesUtil from '../tools/DataPreUtils';
import { Log } from '../tools/Logger';
import EntryAbility from '../entryability/EntryAbility';


@Entry
@Component
struct TargetSetPage {

  private getSafeTopPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 0
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return Math.max(0, avoidArea.topRect.height)
  }

  @State stepTarget:string = ''
  @State stepTargetNum:number = 5000
  private stepTargetTimeOut:number = 0

  @State weightTarget:string = ''
  @State weightTargetNum:number = 80
  private weightTargetTimeOut:number = 0

  @State timeTarget: string = ''
  @State timeTargetNum: number = 25
  private timeTargetTimeOut: number = 0

  @State sportTarget:string = ''
  @State sportTargetNum:number = 5000
  private sportTargetTimeOut:number = 0

  async onPageShow(): Promise<void> {
    let tarSteps = await preferencesUtil.getPreferenceValue('steps_ohos', 'step_target', 5000) as number
    this.stepTargetNum = tarSteps
    this.stepTarget = tarSteps + '步'

    let tarWeights = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight_target', 80) as number
    this.weightTargetNum = tarWeights
    this.weightTarget = tarWeights + 'kg'

    let tarTime = await preferencesUtil.getPreferenceValue('steps_ohos', 'sport_time_target', 25) as number
    this.timeTargetNum = tarTime
    this.timeTarget = tarTime + '分钟'

    let tarSport = await preferencesUtil.getPreferenceValue('steps_ohos', 'sport_target', 5000) as number
    this.sportTargetNum = tarSport
    this.sportTarget = tarSport + 'm'
  }

  aboutToDisappear(): void {
    // 清理所有未完成的延迟保存操作
    if (this.stepTargetTimeOut) {
      clearTimeout(this.stepTargetTimeOut)
      this.stepTargetTimeOut = 0
    }
    if (this.weightTargetTimeOut) {
      clearTimeout(this.weightTargetTimeOut)
      this.weightTargetTimeOut = 0
    }
    if (this.sportTargetTimeOut) {
      clearTimeout(this.sportTargetTimeOut)
      this.sportTargetTimeOut = 0
    }
    if (this.timeTargetTimeOut) {
      clearTimeout(this.timeTargetTimeOut)
      this.timeTargetTimeOut = 0
    }
  }


  build() {
    Column() {
      Stack() {
        Text('目标管理')
          .fontSize(16)
          .height('100%')
          .alignSelf(ItemAlign.Center)
          .textAlign(TextAlign.Center)
          .fontColor('#ff707070').width('100%').height('100%')
        Image($r('app.media.back_btn_dark')).height(27).width(27).onClick(() => {
          router.back();
        }).alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .height(56)
      .padding({ top: this.getSafeTopPadding(), left: 10, right: 10 })
      .alignContent(Alignment.TopStart)
        Column() {
          this.buildTargetCard('步数目标', this.stepTarget, '步', this.stepTargetNum, 1000, 40000, 100, (value: number) => {
            this.updateStepTarget(value)
          }, 12, 12, 16)
          this.buildTargetCard('体重目标', this.weightTarget, 'kg', this.weightTargetNum, 30, 150, 1, (value: number) => {
            this.updateWeightTarget(value)
          }, 12, 12, 16)
          this.buildTargetCard('运动时长', this.timeTarget, '分钟', this.timeTargetNum, 10, 300, 5, (value: number) => {
            this.updateTimeTarget(value)
          }, 12, 12, 16)
          this.buildTargetCard('运动距离', this.sportTarget, 'm', this.sportTargetNum, 1000, 50000, 100, (value: number) => {
            this.updateSportTarget(value)
          }, 12, 12, 16)
        }
    }
  }

  @Builder buildTargetCard(title: string, displayValue: string, unit: string, sliderValue: number, min: number, max: number, step: number, onChange: (value: number) => void, marginLeft: number = 0, marginRight: number = 0, marginTop: number = 16) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontColor('#ff3c3c3c')
        .margin({ left: 12, right: 12, top: 8 })

      Row() {
        Text(sliderValue.toString())
          .fontSize(32)
          .fontWeight(700)
          .fontColor('#0cc291')
          .margin({ right: 4 })
        Text(unit)
          .fontSize(18)
          .fontColor('#ff3c3c3c')
          .fontWeight(500)
        Blank()
      }
      .margin({ left: 12, right: 12, top: 8, bottom: 4 })
      .alignItems(VerticalAlign.Bottom)

      Slider({
        value: sliderValue,
        min: min,
        max: max,
        step: step
      })
        .blockColor('#0cc291')
        .selectedColor('#0cc291')
        .trackColor('#ffe0e0e0')
        .width('90%')
        .margin({ top: 12, bottom: 8 })
        .onChange((value: number) => {
          const rounded = this.normalizeValue(value, step, min, max)
          onChange(rounded)
        })
    }
    .width('95%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .padding({ top: 12, bottom: 16 })
    .margin({ left: marginLeft, right: marginRight, top: marginTop })
  }

  private normalizeValue(value: number, step: number, min: number, max: number): number {
    let rounded = Math.round(value / step) * step
    if (rounded < min) {
      rounded = min
    }
    if (rounded > max) {
      rounded = max
    }
    return rounded
  }

  private updateStepTarget(value: number) {
    this.stepTargetNum = value
    this.stepTarget = `${value}步`
    clearTimeout(this.stepTargetTimeOut)
    this.stepTargetTimeOut = setTimeout(() => {
      preferencesUtil.putPreferenceValue('steps_ohos', 'step_target', value)
    }, 300)
  }

  private updateWeightTarget(value: number) {
    this.weightTargetNum = value
    this.weightTarget = `${value}kg`
    clearTimeout(this.weightTargetTimeOut)
    this.weightTargetTimeOut = setTimeout(() => {
      preferencesUtil.putPreferenceValue('steps_ohos', 'weight_target', value)
    }, 300)
  }

  private updateSportTarget(value: number) {
    this.sportTargetNum = value
    this.sportTarget = `${value}m`
    clearTimeout(this.sportTargetTimeOut)
    this.sportTargetTimeOut = setTimeout(() => {
      preferencesUtil.putPreferenceValue('steps_ohos', 'sport_target', value)
    }, 300)
  }

  private updateTimeTarget(value: number) {
    this.timeTargetNum = value
    this.timeTarget = `${value}分钟`
    clearTimeout(this.timeTargetTimeOut)
    this.timeTargetTimeOut = setTimeout(() => {
      preferencesUtil.putPreferenceValue('steps_ohos', 'sport_time_target', value)
    }, 300)
  }
}
