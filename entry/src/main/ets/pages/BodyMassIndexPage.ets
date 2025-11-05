import { CommonTitleView } from '../view/CommonTitleView'
import { router, window } from '@kit.ArkUI'
import preferencesUtil from '../tools/DataPreUtils'
import { BodyRecordDialog } from '../view/BodyRecordDialog'
import appDataManager, { AppDataManager } from '../tools/AppDataManager'
import { userDataManager } from '../services/UserDataManager'
import { BodyRecordModel } from '../appdata/Model'
import EntryAbility from '../entryability/EntryAbility'

interface BmiStatusInfo {
  label: string
  color: string
  description: string
}

interface BmiStatusSegment {
  max: number
  info: BmiStatusInfo
}

const BMI_STATUS_SEGMENTS: Array<BmiStatusSegment> = [
  {
    max: 18.5,
    info: {
      label: '过轻',
      color: '#97a7c7',
      description: '体重指数过低可能会带来一定的健康风险。建议调整饮食增加体重，让 BMI 回到正常范围。每天比平时多摄入 250~500 千卡，但要远离垃圾食品和含糖饮料。将饮食调整与力量训练结合，增强肌肉有助于提高 BMI。'
    }
  },
  {
    max: 24,
    info: {
      label: '正常',
      color: '#5bdc70',
      description: '健康的体重有助于降低患严重健康状况的风险，说明你正接近自己的健身目标。保持均衡饮食与规律运动，持续关注身体变化。'
    }
  },
  {
    max: 28,
    info: {
      label: '偏胖',
      color: '#ff9c57',
      description: '体重指数超标可能增加心血管疾病等健康风险。可以逐步调整饮食结构、控制热量摄入，并配合有氧与力量训练来改善身体状况。'
    }
  },
  {
    max: Number.POSITIVE_INFINITY,
    info: {
      label: '肥胖',
      color: '#ff6037',
      description: '肥胖会提高心血管疾病、高血压、II 型糖尿病、呼吸系统问题等风险。请尽量通过健康饮食、建立长期锻炼计划来改善整体健康与生活质量。'
    }
  }
]

@Entry
@Component
struct BodyMassIndexPage {
  @State heightInput: number = 0
  @State weightInput: number = 0
  @State resultBmi: number = 0
  @State resultStatus: string = ''
  @State resultColor: string = '#97a7c7'
  @State resultDescription: string = '请先填写身高和体重信息后再点击“计算”。'
  @State showResult: boolean = false

  private heightDialog?: CustomDialogController
  private weightDialog?: CustomDialogController

  private metricsUnsubscribe?: () => void

  aboutToAppear(): void {
    // 建立订阅，确保任何时刻的数据更新都能立刻回调
    this.metricsUnsubscribe?.()
    this.metricsUnsubscribe = userDataManager.subscribe((metrics) => {
      this.heightInput = metrics.height
      this.weightInput = metrics.weight
      // 自动重新计算BMI
      this.calculateBmi(false)
    })
  }

  aboutToDisappear(): void {
    // 取消订阅
    this.metricsUnsubscribe?.()
    this.metricsUnsubscribe = undefined
    // 恢复默认状态栏
    this.restoreStatusBar()
  }

  async onPageShow(): Promise<void> {
    // 先刷新数据，确保获取最新值
    await userDataManager.refreshMetrics()
    await this.loadInitialData()
    // 设置沉浸式状态栏和标题栏
    this.setImmersiveStatusBar()
  }

  private setImmersiveStatusBar(): void {
    if (EntryAbility.myWindowClass) {
      EntryAbility.myWindowClass.setWindowSystemBarProperties({
        statusBarColor: '#F5F5F5',
        statusBarContentColor: '#000000'
      })
    }
  }

  private restoreStatusBar(): void {
    if (EntryAbility.myWindowClass) {
      EntryAbility.myWindowClass.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: '#000000'
      })
    }
  }

  private async loadInitialData() {
    // 从数据库同步最新身高和体重数据
    await Promise.all([
      this.syncLatestHeight(),
      this.syncLatestWeight()
    ])

    // 等待一小段时间确保数据已同步到 preferences
    await new Promise<void>((resolve: () => void) => setTimeout(resolve, 100))

    // 使用统一的数据管理服务加载最新数据
    const metrics = await userDataManager.loadMetrics()
    
    // 直接使用最新的真实数据，不使用缓存
    this.heightInput = metrics.height
    this.weightInput = metrics.weight

    // 自动计算BMI
    this.calculateBmi(false)
  }

  private async syncLatestHeight(): Promise<void> {
    return new Promise<void>((resolve) => {
      // 从数据库获取最新的身高记录，并同步到 preferences
      appDataManager.findBodyRecordByType(AppDataManager.TYPE_HEIGHT, {
        onDataResult: async (type: number, result: Array<BodyRecordModel>, isFirst: boolean): Promise<void> => {
          if (type !== AppDataManager.TYPE_HEIGHT) {
            resolve()
            return
          }
          if (result && result.length > 0) {
            const latestRecord = result[0]
            let cleanData = latestRecord.data.replace(/[^0-9.]/g, '')
            const heightValue = parseFloat(cleanData)
            if (!isNaN(heightValue) && heightValue > 0) {
              const currentHeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'height', 0) as number
              if (Math.abs(currentHeight - heightValue) > 0.01) {
                await userDataManager.updateHeight(heightValue)
              }
            }
          }
          resolve()
        }
      }, true) // isReturnFirstData = true，只获取最新一条
    })
  }

  private async syncLatestWeight(): Promise<void> {
    return new Promise<void>((resolve) => {
      // 从数据库获取最新的体重记录，并同步到 preferences
      appDataManager.findBodyRecordByType(AppDataManager.TYPE_WEIGHT, {
        onDataResult: async (type: number, result: Array<BodyRecordModel>, isFirst: boolean): Promise<void> => {
          if (type !== AppDataManager.TYPE_WEIGHT) {
            resolve()
            return
          }
          if (result && result.length > 0) {
            const latestRecord = result[0]
            let cleanData = latestRecord.data.replace(/[^0-9.]/g, '')
            const weightValue = parseFloat(cleanData)
            if (!isNaN(weightValue) && weightValue > 0) {
              const currentWeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight', 0) as number
              if (Math.abs(currentWeight - weightValue) > 0.01) {
                await userDataManager.updateWeight(weightValue)
              }
            }
          }
          resolve()
        }
      }, true) // isReturnFirstData = true，只获取最新一条
    })
  }

  private saveInputs() {
    preferencesUtil.putPreferenceValue('steps_ohos', 'bmi_last_height', this.heightInput)
    preferencesUtil.putPreferenceValue('steps_ohos', 'bmi_last_weight', this.weightInput)
  }

  private openHeightDialog() {
    const baseValue = this.heightInput > 0 ? this.heightInput : 170
    this.heightDialog = new CustomDialogController({
      builder: BodyRecordDialog({
        title: '身高',
        unit: '厘米',
        bodyType: AppDataManager.TYPE_HEIGHT,
        startNum: 80,
        endNum: 230,
        stepNum: 0.1,
        selectNum: baseValue,
        content: baseValue.toFixed(1),
        cancel: () => {
          this.heightDialog?.close()
        },
        confirm: async (value: number, _type: number) => {
          this.heightDialog?.close()
          this.heightInput = Math.round(value * 10) / 10
          // 更新数据并广播
          await userDataManager.updateHeight(this.heightInput)
          await userDataManager.refreshMetrics()
          this.saveInputs()
          // 自动重新计算BMI
          this.calculateBmi(true)
        }
      }),
      autoCancel: true
    })
    this.heightDialog.open()
  }

  private openWeightDialog() {
    const baseValue = this.weightInput > 0 ? this.weightInput : 60
    this.weightDialog = new CustomDialogController({
      builder: BodyRecordDialog({
        title: '体重',
        unit: '公斤',
        bodyType: AppDataManager.TYPE_WEIGHT,
        startNum: 30,
        endNum: 200,
        stepNum: 0.1,
        selectNum: baseValue,
        content: baseValue.toFixed(1),
        cancel: () => {
          this.weightDialog?.close()
        },
        confirm: async (value: number, _type: number) => {
          this.weightDialog?.close()
          this.weightInput = Math.round(value * 10) / 10
          // 更新数据并广播
          await userDataManager.updateWeight(this.weightInput)
          await userDataManager.refreshMetrics()
          this.saveInputs()
          // 自动重新计算BMI
          this.calculateBmi(true)
        }
      }),
      autoCancel: true
    })
    this.weightDialog.open()
  }

  private calculateBmi(savePreference: boolean = true) {
    if (this.heightInput <= 0 || this.weightInput <= 0) {
      this.showResult = false
      this.resultDescription = '请填写身高和体重信息后再计算。'
      return
    }

    const heightInMeters = this.heightInput / 100
    const bmi = this.weightInput / (heightInMeters * heightInMeters)
    this.resultBmi = Math.round(bmi * 10) / 10

    const status = this.resolveStatus(this.resultBmi)
    this.resultStatus = status.label
    this.resultColor = status.color
    this.resultDescription = status.description
    this.showResult = true

    if (savePreference) {
      this.saveInputs()
      preferencesUtil.putPreferenceValue('steps_ohos', 'bmi_last_calculated', true)
    }
  }

  private resolveStatus(bmi: number): BmiStatusInfo {
    for (const segment of BMI_STATUS_SEGMENTS) {
      if (bmi < segment.max) {
        return segment.info
      }
    }
    return BMI_STATUS_SEGMENTS[BMI_STATUS_SEGMENTS.length - 1].info
  }

  private getIndicatorPercent(): number {
    const min = 15
    const max = 35
    const clamped = Math.max(min, Math.min(max, this.resultBmi))
    return (clamped - min) / (max - min)
  }

  private formatValue(value: number): string {
    if (value <= 0) {
      return '选择'
    }
    return value.toFixed(1)
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '身体质量指数 BMI' },
        cancel: () => {
          router.back()
        },
        titleBackgroundColor: '#F5F5F5'
      })

      Scroll() {
        Column() {
          this.buildInputCard()
          if (this.showResult) {
            this.buildResultCard()
          } else {
            this.buildPlaceholderCard()
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 0 })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private buildInputCard() {
    Column() {
      Text('信息填写')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      this.buildHeightInputRow()
      this.buildWeightInputRow()

      Text('注：BMI 计算公式为体重(kg) ÷ 身高²(m²)。若未录入过身高、体重，可在本页直接填写，结果将自动计算并保存。')
        .fontSize(12)
        .fontColor('#999999')
        .lineHeight(18)
        .margin({ top: 12 })
    }
    .width('92%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 16 })
    .shadow({ radius: 8, color: '#14000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  private buildHeightInputRow() {
    Column() {
      Row() {
        Column() {
          Text('身高（厘米）')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
          Text(this.heightInput > 0 ? this.heightInput.toFixed(1) : '选择')
            .fontSize(18)
            .fontWeight(500)
            .fontColor(this.heightInput > 0 ? '#222222' : '#bbbbbb')
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        Image($r('app.media.right_point'))
          .width(16)
          .height(16)
          .opacity(0.4)
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(() => {
        this.openHeightDialog()
      })

      Row()
        .width('100%')
        .height(1)
        .backgroundColor('#f0f0f0')
    }
  }

  @Builder
  private buildWeightInputRow() {
    Column() {
      Row() {
        Column() {
          Text('体重（公斤）')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
          Text(this.weightInput > 0 ? this.weightInput.toFixed(1) : '选择')
            .fontSize(18)
            .fontWeight(500)
            .fontColor(this.weightInput > 0 ? '#222222' : '#bbbbbb')
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        Image($r('app.media.right_point'))
          .width(16)
          .height(16)
          .opacity(0.4)
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(() => {
        this.openWeightDialog()
      })
    }
  }

  @Builder
  private buildResultCard() {
    Column() {
      Text('计算结果')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Text(this.resultBmi.toFixed(1))
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.resultColor)
        .margin({ top: 8 })

      Text(this.resultStatus)
        .fontSize(16)
        .fontColor(this.resultColor)
        .margin({ top: 4 })

      this.buildBmiScale()

      Text(this.resultDescription)
        .fontSize(13)
        .fontColor('#666666')
        .lineHeight(20)
        .margin({ top: 16 })
    }
    .width('92%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 16, bottom: 24 })
    .shadow({ radius: 8, color: '#14000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  private buildPlaceholderCard() {
    Column() {
      Text('计算结果')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Text('尚未计算')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#bbbbbb')
        .margin({ top: 16 })

      Text(this.resultDescription)
        .fontSize(13)
        .fontColor('#666666')
        .lineHeight(20)
        .margin({ top: 16 })
    }
    .width('92%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 16, bottom: 24 })
    .shadow({ radius: 8, color: '#14000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  private buildBmiScale() {
    Column() {
      Stack() {
        Row() {
          this.buildScaleSegment('#97a7c7', 185)
          this.buildScaleSegment('#5bdc70', 55)
          this.buildScaleSegment('#ff9c57', 40)
          this.buildScaleSegment('#ff6037', 40)
        }
        .height(12)
        .width('100%')
        .borderRadius(6)

        Row() {
          Blank().width(`${(this.getIndicatorPercent() * 100).toFixed(1)}%`)
          Text('▼')
            .fontSize(12)
            .fontColor(this.resultColor)
        }
        .width('100%')
        .margin({ top: -6 })
      }
      .width('100%')
      .margin({ top: 20 })

      Row() {
        Text('18.5')
          .fontSize(12)
          .fontColor('#999999')
        Blank().layoutWeight(1)
        Text('24')
          .fontSize(12)
          .fontColor('#999999')
        Blank().layoutWeight(1)
        Text('28')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .margin({ top: 8 })
    }
  }

  @Builder
  private buildScaleSegment(color: string, weight: number) {
    Row()
      .layoutWeight(weight)
      .backgroundColor(color)
      .height('100%')
  }
}
