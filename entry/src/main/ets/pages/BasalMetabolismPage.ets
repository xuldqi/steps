import { router } from '@kit.ArkUI'
import { CommonTitleView } from '../view/CommonTitleView'
import preferencesUtil from '../tools/DataPreUtils'
import { Utils } from '../tools/Utils'
import { userDataManager } from '../services/UserDataManager'
import appDataManager, { AppDataManager } from '../tools/AppDataManager'
import { BodyRecordModel } from '../appdata/Model'

interface GenderOption {
  id: string
  label: string
  value: 'male' | 'female'
}

interface ActivityLevel {
  id: string
  title: string
  description: string
  multiplier: number
}

const ACTIVITY_LEVELS: Array<ActivityLevel> = [
  {
    id: 'sedentary',
    title: '久坐人群',
    description: '几乎不运动或只是偶尔散步',
    multiplier: 1.2
  },
  {
    id: 'light',
    title: '轻度活动',
    description: '每周 1-3 天轻量运动（如瑜伽、缓跑）',
    multiplier: 1.375
  },
  {
    id: 'moderate',
    title: '中等活动',
    description: '每周 3-5 天规律运动或体力劳动',
    multiplier: 1.55
  },
  {
    id: 'active',
    title: '高强度活动',
    description: '每周 6-7 天训练，运动时间较长',
    multiplier: 1.725
  },
  {
    id: 'very_active',
    title: '非常活跃',
    description: '体力工作或每日两次训练',
    multiplier: 1.9
  },
  {
    id: 'athlete',
    title: '高阶训练',
    description: '专业运动员级别，需要额外能量补给',
    multiplier: 2.1
  }
]

type PickerField = 'age' | 'height' | 'weight'

@Entry
@Component
struct BasalMetabolismPage {
  private scroller: Scroller = new Scroller()

  private genderOptions: Array<GenderOption> = [
    { id: 'male', label: '男', value: 'male' },
    { id: 'female', label: '女', value: 'female' }
  ]

  @State selectedGender: 'male' | 'female' = 'male'
  @State ageInput: number = 0
  @State heightInput: number = 0
  @State weightInput: number = 0

  @State bmrResult: number = 0
  @State showResult: boolean = false
  @State resultHeader: string = '完善信息后即可估算每日基础代谢。'
  @State resultDescription: string = '基础代谢率指身体在静息状态下维持生命所需的能量，是制定饮食与运动计划的重要参考。'

  @State showPickerDialog: boolean = false
  private pickerField: PickerField | null = null
  @State pickerTitle: string = ''
  @State pickerUnit: string = ''
  @State pickerValueList: Array<number> = []
  @State pickerDisplayList: Array<string> = []
  @State pickerSelectedIndex: number = 0
  private pickerDecimals: number = 0

  private metricsUnsubscribe?: () => void

  aboutToAppear(): void {
    // 建立订阅，确保任何时刻的数据更新都能立刻回调
    this.metricsUnsubscribe?.()
    this.metricsUnsubscribe = userDataManager.subscribe(async (metrics) => {
      this.selectedGender = metrics.gender === 'female' ? 'female' : 'male'
      // 优先使用缓存值（上次计算的输入），否则使用最新数据
      const cachedHeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'bmr_last_height', metrics.height) as number
      const cachedWeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'bmr_last_weight', metrics.weight) as number
      const cachedAge = await preferencesUtil.getPreferenceValue('steps_ohos', 'bmr_last_age', metrics.age) as number
      this.heightInput = cachedHeight > 0 ? cachedHeight : metrics.height
      this.weightInput = cachedWeight > 0 ? cachedWeight : metrics.weight
      this.ageInput = cachedAge > 0 ? cachedAge : metrics.age
      this.updateResult(false)
    })
  }

  aboutToDisappear(): void {
    // 取消订阅
    this.metricsUnsubscribe?.()
    this.metricsUnsubscribe = undefined
  }

  async onPageShow(): Promise<void> {
    // 先刷新数据，确保获取最新值
    await userDataManager.refreshMetrics()
    await this.loadInitialData()
  }

  private async loadInitialData(): Promise<void> {
    // 使用统一的数据管理服务加载数据
    const metrics = await userDataManager.loadMetrics()
    this.selectedGender = metrics.gender === 'female' ? 'female' : 'male'

    // 从数据库同步最新身高和体重数据（使用 Promise 包装）
    await Promise.all([
      this.syncLatestHeight(),
      this.syncLatestWeight()
    ])

    // 等待一小段时间确保数据已同步到 preferences
    await new Promise<void>((resolve: () => void) => setTimeout(resolve, 100))

    // 重新加载 metrics 以确保获取最新数据
    const updatedMetrics = await userDataManager.loadMetrics()

    // 检查是否有缓存的基础代谢值（上次计算时的输入值）
    const cachedHeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'bmr_last_height', updatedMetrics.height) as number
    const cachedWeight = await preferencesUtil.getPreferenceValue('steps_ohos', 'bmr_last_weight', updatedMetrics.weight) as number
    const cachedAge = await preferencesUtil.getPreferenceValue('steps_ohos', 'bmr_last_age', updatedMetrics.age) as number

    // 优先使用缓存值（上次计算的输入），否则使用最新数据
    this.heightInput = cachedHeight > 0 ? cachedHeight : updatedMetrics.height
    this.weightInput = cachedWeight > 0 ? cachedWeight : updatedMetrics.weight
    this.ageInput = cachedAge > 0 ? cachedAge : updatedMetrics.age

    this.updateResult(false)
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

  private updateResult(shouldPersist: boolean = true): void {
    if (this.heightInput <= 0 || this.weightInput <= 0 || this.ageInput <= 0) {
      this.bmrResult = 0
      this.showResult = false
      this.resultHeader = '完善信息后即可估算每日基础代谢。'
      this.resultDescription = '请填写性别、年龄、身高与体重，系统会根据哈里斯-本尼迪克特公式计算基础代谢率。'
      return
    }

    const rawValue = 10 * this.weightInput + 6.25 * this.heightInput - 5 * this.ageInput
    const genderOffset = this.selectedGender === 'male' ? 5 : -161
    this.bmrResult = Math.round(rawValue + genderOffset)
    this.showResult = true
    this.resultHeader = `估算结果：${this.bmrResult} 千卡/天`
    this.resultDescription = this.buildResultDescription(this.bmrResult)

    if (shouldPersist) {
      this.persistInputs(this.bmrResult)
    }
  }

  private buildResultDescription(value: number): string {
    if (value < 1200) {
      return '基础代谢偏低，建议适当增加高质量蛋白与力量训练，帮助提升肌肉量，逐渐改善代谢水平。'
    }
    if (value < 1600) {
      return '基础代谢处于日常范围，可搭配均衡饮食与规律运动，继续保持当前的生活节奏。'
    }
    if (value < 2000) {
      return '基础代谢表现良好，维持充足的睡眠与训练节奏，有助于进一步巩固健康状态。'
    }
    return '基础代谢较高，注意补充能量与水分，避免过度劳累。如需控制体重，可结合营养师建议调整餐食计划。'
  }

  private persistInputs(bmrValue: number): void {
    // 使用统一的数据管理服务更新数据
    void userDataManager.updateMetrics({
      gender: this.selectedGender,
      age: this.ageInput,
      height: this.heightInput,
      weight: this.weightInput
    })

    // 保存基础代谢相关缓存
    void preferencesUtil.putPreferenceValue('steps_ohos', 'bmr_last_value', bmrValue)
    void preferencesUtil.putPreferenceValue('steps_ohos', 'bmr_last_height', this.heightInput)
    void preferencesUtil.putPreferenceValue('steps_ohos', 'bmr_last_weight', this.weightInput)
    void preferencesUtil.putPreferenceValue('steps_ohos', 'bmr_last_age', this.ageInput)
    void preferencesUtil.putPreferenceValue('steps_ohos', 'bmr_last_gender', this.selectedGender)
    void preferencesUtil.putPreferenceValue('steps_ohos', 'bmr_last_calculated', true)
  }

  private openPicker(field: PickerField): void {
    this.pickerField = field
    let values: Array<number> = []
    let title = ''
    let unit = ''
    let current = 0
    let min = 0
    let max = 0
    let step = 1

    switch (field) {
      case 'age':
        title = '选择年龄'
        unit = '岁'
        min = 10
        max = 100
        step = 1
        current = this.ageInput > 0 ? this.ageInput : 25
        break
      case 'height':
        title = '选择身高'
        unit = '厘米'
        min = 120
        max = 230
        step = 0.5
        current = this.heightInput > 0 ? this.heightInput : 165
        break
      case 'weight':
        title = '选择体重'
        unit = '公斤'
        min = 30
        max = 200
        step = 0.5
        current = this.weightInput > 0 ? this.weightInput : 60
        break
    }

    const decimals = this.resolveDecimals(step)
    values = this.generatePickerValues(min, max, step, decimals)
    this.pickerDecimals = decimals

    let selectedIndex = values.findIndex((value) => Math.abs(value - current) < (step / 2))
    if (selectedIndex < 0) {
      selectedIndex = 0
    }

    this.pickerTitle = title
    this.pickerUnit = unit
    this.pickerValueList = values
    this.pickerDisplayList = values.map((value) => this.formatPickerValue(value, unit, decimals))
    this.pickerSelectedIndex = selectedIndex
    this.showPickerDialog = true
  }

  private generatePickerValues(min: number, max: number, step: number, decimals: number): Array<number> {
    const list: Array<number> = []
    for (let value = min; value <= max + (step / 2); value += step) {
      const rounded = step < 1 ? parseFloat(value.toFixed(decimals)) : Math.round(value)
      if (rounded > max) {
        break
      }
      list.push(rounded)
    }
    return list
  }

  private resolveDecimals(step: number): number {
    if (step >= 1) {
      return 0
    }
    const precise = Math.ceil(Math.log10(1 / step))
    return precise > 0 ? precise : 0
  }

  private formatPickerValue(value: number, unit: string, decimals: number): string {
    if (decimals > 0) {
      return `${value.toFixed(decimals)} ${unit}`
    }
    return `${Math.round(value)} ${unit}`
  }

  private onPickerChange(value: string | Array<string>, index: number | Array<number>): void {
    if (!this.showPickerDialog || this.pickerValueList.length === 0) {
      return
    }

    if (Array.isArray(index)) {
      const candidate = index[0] as number
      if (this.isValidPickerIndex(candidate)) {
        this.pickerSelectedIndex = candidate
        return
      }
    } else if (typeof index === 'number') {
      if (this.isValidPickerIndex(index)) {
        this.pickerSelectedIndex = index
        return
      }
    }

    const parsed = this.parsePickerValue(value)
    if (!Number.isNaN(parsed)) {
      const matches = this.pickerValueList.findIndex((item) => Math.abs(item - parsed) < Math.pow(10, -(this.pickerDecimals + 1)))
      if (matches >= 0) {
        this.pickerSelectedIndex = matches
      }
    }
  }

  private isValidPickerIndex(index: number): boolean {
    return index >= 0 && index < this.pickerValueList.length
  }

  private parsePickerValue(value: string | Array<string>): number {
    const raw = Array.isArray(value) ? value[0] ?? '' : value ?? ''
    const cleaned = raw.replace(/[^\d.]/g, '')
    return parseFloat(cleaned)
  }

  private closePicker(): void {
    this.showPickerDialog = false
    this.pickerField = null
  }

  private async confirmPicker(): Promise<void> {
    if (!this.showPickerDialog || this.pickerField === null || !this.isValidPickerIndex(this.pickerSelectedIndex)) {
      this.closePicker()
      return
    }

    const selectedValue = this.pickerValueList[this.pickerSelectedIndex]
    switch (this.pickerField) {
      case 'age':
        this.ageInput = Math.round(selectedValue)
        await userDataManager.updateAge(this.ageInput)
        break
      case 'height':
        this.heightInput = parseFloat(selectedValue.toFixed(this.pickerDecimals))
        await userDataManager.updateHeight(this.heightInput)
        break
      case 'weight':
        this.weightInput = parseFloat(selectedValue.toFixed(this.pickerDecimals))
        await userDataManager.updateWeight(this.weightInput)
        break
    }

    this.closePicker()
    // 刷新并广播数据更新
    await userDataManager.refreshMetrics()
    this.updateResult()
  }

  private async onGenderSelected(option: GenderOption): Promise<void> {
    if (this.selectedGender !== option.value) {
      this.selectedGender = option.value
      await userDataManager.updateGender(this.selectedGender)
      // 刷新并广播数据更新
      await userDataManager.refreshMetrics()
      this.updateResult()
    }
  }

  private getFormattedHeight(): string {
    return this.heightInput > 0 ? `${this.heightInput.toFixed(1)} 厘米` : '请选择'
  }

  private getFormattedWeight(): string {
    return this.weightInput > 0 ? `${this.weightInput.toFixed(1)} 公斤` : '请选择'
  }

  private getFormattedAge(): string {
    return this.ageInput > 0 ? `${this.ageInput} 岁` : '请选择'
  }

  private getActivityCalories(level: ActivityLevel): string {
    if (!this.showResult || this.bmrResult <= 0) {
      return '--'
    }
    return Math.round(this.bmrResult * level.multiplier).toString()
  }

  private handleRecordTap(): void {
    if (!this.showResult || this.bmrResult <= 0) {
      Utils.showToast('请先完善信息并计算基础代谢')
      return
    }
    Utils.showToast('基础代谢已同步，记得搭配合理饮食与训练哦')
  }

  build() {
    Stack() {
      Column() {
        CommonTitleView({
          data1: { str1: '基础代谢率计算' },
          cancel: () => router.back()
        })

        Scroll(this.scroller) {
          Column() {
            this.buildResultCard()
            this.buildInputCard()
            this.buildActivityCard()
            this.buildFooter()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: this.getSafeBottomPadding() + 40 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')

      if (this.showPickerDialog) {
        this.buildPickerDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private buildResultCard() {
    Column() {
      Text('基础代谢率')
        .fontSize(16)
        .fontColor('#222222')
        .fontWeight(500)

      if (this.showResult && this.bmrResult > 0) {
        Row() {
          Text(this.bmrResult.toString())
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0cc291')

          Text('千卡/天')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ left: 8, top: 12 })
        }
        .margin({ top: 16 })
      } else {
        Text('--')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#C8C8C8')
          .margin({ top: 16 })
      }

      Text(this.resultHeader)
        .fontSize(14)
        .fontColor('#333333')
        .margin({ top: 18 })

      Text(this.resultDescription)
        .fontSize(12)
        .fontColor('#666666')
        .lineHeight(18)
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ top: 24, bottom: 24, left: 20, right: 20 })
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ color: 'rgba(12,194,145,0.08)', radius: 8, offsetX: 0, offsetY: 4 })
    .margin({ top: 0, bottom: 0 })
  }

  @Builder
  private buildInputCard() {
    Column() {
      Text('基础信息')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#222222')

      Row() {
        ForEach(this.genderOptions, (option: GenderOption, index: number) => {
          Text(option.label)
            .layoutWeight(1)
            .height(44)
            .fontSize(16)
            .fontColor(this.selectedGender === option.value ? '#FFFFFF' : '#666666')
            .textAlign(TextAlign.Center)
            .backgroundColor(this.selectedGender === option.value ? '#0cc291' : '#F2F4F5')
            .borderRadius(12)
            .margin({ right: index === 0 ? 8 : 0 })
            .onClick(() => {
              this.onGenderSelected(option)
            })
        }, (option: GenderOption) => option.id)
      }
      .width('100%')
      .margin({ top: 16 })
      .justifyContent(FlexAlign.SpaceBetween)

      this.infoRow('年龄', this.getFormattedAge(), () => this.openPicker('age'))
      this.divider()
      this.infoRow('身高', this.getFormattedHeight(), () => this.openPicker('height'))
      this.divider()
      this.infoRow('体重', this.getFormattedWeight(), () => this.openPicker('weight'))
    }
    .padding({ top: 24, bottom: 12, left: 20, right: 20 })
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 16 })
  }

  @Builder
  private buildActivityCard() {
    Column() {
      Text('日常活动热量参考')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#222222')

      Text('根据你的基础代谢，估算不同活动强度下每日所需热量。')
        .fontSize(12)
        .fontColor('#666666')
        .lineHeight(18)
        .margin({ top: 8 })

      Column() {
        ForEach(ACTIVITY_LEVELS, (level: ActivityLevel, index: number) => {
          this.activityRow(level, index === ACTIVITY_LEVELS.length - 1)
        }, (level: ActivityLevel) => level.id)
      }
      .margin({ top: 18 })
    }
    .padding({ top: 24, bottom: 12, left: 20, right: 20 })
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 16 })
  }

  @Builder
  private buildPickerDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.45)')
        .onClick(() => {
          this.closePicker()
        })

      Column() {
        Text(this.pickerTitle)
          .fontSize(18)
          .fontWeight(500)
          .fontColor('#333333')
          .margin({ bottom: 16 })

        if (this.pickerDisplayList.length > 0) {
          TextPicker({
            range: this.pickerDisplayList,
            selected: this.pickerSelectedIndex
          })
            .height(200)
            .width('100%')
            .selectedTextStyle({ color: Color.Black, font: { size: 24, weight: FontWeight.Medium } })
            .textStyle({ color: '#666666', font: { size: 18, weight: FontWeight.Normal } })
            .margin({ bottom: 20 })
            .onChange((value, index) => {
              this.onPickerChange(value, index)
            })
        } else {
          Text('暂无可选数据')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 40, bottom: 40 })
        }

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor('#666666')
            .backgroundColor('#F2F4F5')
            .borderRadius(24)
            .onClick(() => {
              this.closePicker()
            })

          Button('确定')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#0cc291')
            .borderRadius(24)
            .margin({ left: 12 })
            .onClick(() => {
              this.confirmPicker()
            })
        }
        .width('100%')
      }
      .padding({ top: 24, bottom: 24, left: 24, right: 24 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 24, topRight: 24 })
      .align(Alignment.Bottom)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildFooter() {
    Column() {
      Button('记录基础代谢')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#0cc291')
        .borderRadius(24)
        .onClick(() => {
          this.handleRecordTap()
        })

      Text('基础代谢会同步至"我的-身体概况"，用于其他热量计算。')
        .fontSize(12)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .margin({ top: 12 })
    }
    .width('100%')
    .margin({ top: 24, bottom: 0 })
  }

  @Builder
  private infoRow(label: string, value: string, handler: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)

      Text(value)
        .fontSize(15)
        .fontColor(value === '请选择' ? '#999999' : '#0cc291')
        .margin({ right: 8 })

      Image($r('app.media.right_point'))
        .width(16)
        .height(16)
        .fillColor('#C8C8C8')
    }
    .height(48)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      handler()
    })
  }

  @Builder
  private divider() {
    Row()
      .height(1)
      .backgroundColor('#F0F0F0')
      .margin({ top: 12, bottom: 12 })
  }

  @Builder
  private activityRow(level: ActivityLevel, isLast: boolean) {
    Column() {
      Row() {
        Column() {
          Text(level.title)
            .fontSize(15)
            .fontWeight(500)
            .fontColor('#333333')
            .textAlign(TextAlign.Start)

          Text(level.description)
            .fontSize(12)
            .fontColor('#666666')
            .lineHeight(18)
            .margin({ top: 4 })
            .textAlign(TextAlign.Start)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column() {
          Text(this.getActivityCalories(level))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0cc291')
            .textAlign(TextAlign.End)

          Text('千卡/天')
            .fontSize(12)
            .fontColor('#999999')
            .textAlign(TextAlign.End)
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (!isLast) {
        Row()
          .height(1)
          .backgroundColor('#F5F5F5')
          .margin({ bottom: 12 })
      }
    }
  }

  private getSafeBottomPadding(): number {
    return 16
  }
}
