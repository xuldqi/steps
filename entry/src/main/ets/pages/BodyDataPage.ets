import { router } from '@kit.ArkUI'
import preferencesUtil from '../tools/DataPreUtils'
import { Utils } from '../tools/Utils'
import { AppStateStore } from '../services/AppStateStore'
import appDataManager, { AppDataManager, DataCallback } from '../tools/AppDataManager'
import { BodyRecordModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'
import { userDataManager } from '../services/UserDataManager'

interface SummaryCardConfig {
  id: string
  title: string
  value: string
  unit?: string
  note?: string
  icon: Resource
  accent: string
  badgeBackground: string
  noteColor?: string
  onTap?: () => void
}

interface NavItemConfig {
  id: string
  icon: Resource
  title: string
  trailing?: string
  onTap: () => void
}

@Entry
@Component
struct BodyDataPage {
  private scroller: Scroller = new Scroller()
  private appStateStore: AppStateStore = AppStateStore.getInstance()
  private appStateUnsubscribe: (() => void) | null = null

  @State nickname: string = '运动达人'
  @State persistedDays: number = 0
  @State currentHeight: number = 0
  @State currentWeight: number = 0
  @State userAge: number = 0
  @State userGender: string = 'male'
  @State basalMetabolism: number = 0
  @State bmi: number = 0
  @State bmiStatus: string = '--'
  @State isWeightUnitKg: boolean = true
  @State heightRecords: Array<BodyRecordModel> = []

  private pendingHeightSheet: boolean = false
  private heightDialog: CustomDialogController | null = null
  private metricsUnsubscribe: (() => void) | null = null

  onPageShow(): void {
    interface RouteParams {
      showHeightRecord?: boolean
    }
    const params = typeof router.getParams === 'function' ? router.getParams() as RouteParams | undefined : undefined
    const needShowHeightSheet = params?.showHeightRecord === true
    
    console.info('[BodyDataPage] 页面显示，参数:', JSON.stringify(params), '需要显示身高记录:', needShowHeightSheet)
    
    // 总是重新加载数据，确保从其他页面返回后数据是最新的
    this.ensureAppStateSubscription()
    this.ensureMetricsSubscription()
    void this.loadUserMetrics().then(() => {
      console.info('[BodyDataPage] 数据加载完成 - 身高:', this.currentHeight, '体重:', this.currentWeight, '年龄:', this.userAge, 'BMI:', this.bmi, '基础代谢:', this.basalMetabolism)
    })
    void this.loadWeightUnitPreference()
    
    // 如果需要显示身高记录对话框，延迟打开以确保页面已完全加载
    if (needShowHeightSheet) {
      console.info('[BodyDataPage] 准备打开身高记录对话框')
      // 清理参数，避免下次进入时重复打开
      if (typeof router.replaceUrl === 'function') {
        try {
          router.replaceUrl({ url: 'pages/BodyDataPage' }).catch(() => {})
        } catch (_e) {}
      }
      // 延迟打开对话框，确保页面渲染完成
      setTimeout(() => {
        this.openHeightRecordSheet()
      }, 300)
    }
  }

  aboutToDisappear(): void {
    if (this.appStateUnsubscribe) {
      this.appStateUnsubscribe()
      this.appStateUnsubscribe = null
    }
    if (this.metricsUnsubscribe) {
      this.metricsUnsubscribe()
      this.metricsUnsubscribe = null
    }
  }

  private ensureAppStateSubscription(): void {
    if (this.appStateUnsubscribe) {
      return
    }
    this.appStateUnsubscribe = this.appStateStore.subscribe((state) => {
      if (state.user) {
        this.nickname = state.user.nickname && state.user.nickname.length > 0 ? state.user.nickname : '运动达人'
        this.persistedDays = state.user.persistedDays ?? 0
      } else {
        this.nickname = '运动达人'
        this.persistedDays = 0
      }
    })
  }

  private ensureMetricsSubscription(): void {
    if (this.metricsUnsubscribe) {
      return
    }
    this.metricsUnsubscribe = userDataManager.subscribe((metrics) => {
      this.currentHeight = metrics.height
      this.currentWeight = metrics.weight
      this.userAge = metrics.age
      this.userGender = metrics.gender
      this.calculateMetrics()
    })
  }

  private calculateMetrics(): void {
    if (this.currentHeight > 0 && this.currentWeight > 0) {
      const { value, status } = userDataManager.calculateBMI(this.currentHeight, this.currentWeight)
      this.bmi = value
      this.bmiStatus = status
    } else {
      this.bmi = 0
      this.bmiStatus = '--'
    }

    if (this.currentHeight > 0 && this.currentWeight > 0 && this.userAge > 0) {
      this.basalMetabolism = userDataManager.calculateBMR(this.currentHeight, this.currentWeight, this.userAge, this.userGender)
    } else {
      this.basalMetabolism = 0
    }
  }

  private heightDataCallback: DataCallback<BodyRecordModel> = {
    onDataResult: (type: number, result: Array<BodyRecordModel>, isFirst: boolean): void => {
      if (type !== AppDataManager.TYPE_HEIGHT || isFirst) {
        return
      }
      const sorted = result.slice().sort((a, b) => b.time - a.time)
      this.heightRecords = sorted
      const latest = sorted.length > 0 ? parseFloat(sorted[0].data) : 0
      if (Math.abs(latest - this.currentHeight) > 0.0001) {
        this.persistHeightAndRefreshMetrics(latest)
      }
    }
  }

  private async loadWeightUnitPreference(): Promise<void> {
    const stored = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight_unit_kg', true) as boolean
    this.isWeightUnitKg = stored
  }

  private async loadUserMetrics(): Promise<void> {
    // 使用统一的数据管理服务加载数据
    const metrics = await userDataManager.loadMetrics()
    this.currentHeight = metrics.height
    this.currentWeight = metrics.weight
    this.userAge = metrics.age
    this.userGender = metrics.gender
    this.calculateMetrics()
  }

  private formatNumber(value: number, digits: number = 1): string {
    if (value <= 0) {
      return '--'
    }
    return value.toFixed(digits)
  }

  private formatWeightDisplay(): string {
    if (this.currentWeight <= 0) {
      return '--'
    }
    const displayValue = this.isWeightUnitKg ? this.currentWeight : this.currentWeight * 2
    return displayValue.toFixed(1)
  }

  private getWeightUnitLabel(): string {
    return this.isWeightUnitKg ? '公斤' : '斤'
  }

  private getStreakText(): string {
    if (this.persistedDays > 0) {
      return `已坚持${this.persistedDays}天`
    }
    return '开启你的健康旅程'
  }

  private getBmiNoteColor(): string {
    switch (this.bmiStatus) {
      case '正常':
        return '#0cc291'
      case '过轻':
        return '#5BA7FF'
      case '偏胖':
        return '#FF9C57'
      case '肥胖':
        return '#FF6B6B'
      default:
        return '#999999'
    }
  }

  private async toggleWeightUnit(): Promise<void> {
    this.isWeightUnitKg = !this.isWeightUnitKg
    await preferencesUtil.putPreferenceValue('steps_ohos', 'weight_unit_kg', this.isWeightUnitKg)
    Utils.showToast(`已切换为${this.getWeightUnitLabel()}`)
  }

  private openFoodHeatPage(): void {
    Utils.showToast('功能开发中')
  }

  private refreshHeightRecords(): void {
    appDataManager.findBodyRecordByType(AppDataManager.TYPE_HEIGHT, this.heightDataCallback, false)
  }

  private persistHeightAndRefreshMetrics(nextHeight: number): void {
    void (async () => {
      await userDataManager.updateHeight(nextHeight)
      await this.loadUserMetrics()
    })()
  }

  private openHeightRecordSheet(): void {
    console.info('[BodyDataPage] 打开身高记录对话框')
    this.refreshHeightRecords()
    if (this.heightDialog) {
      this.heightDialog.close()
      this.heightDialog = null
    }
    this.heightDialog = new CustomDialogController({
      builder: () => {
        this.heightRecordDialogBuilder()
      },
      gridCount: 20,
      autoCancel: true
    })
    try {
      this.heightDialog.open()
      console.info('[BodyDataPage] 身高记录对话框已打开')
    } catch (err) {
      console.error('[BodyDataPage] 打开对话框失败:', err)
    }
  }

  private openAddHeightRecord(): void {
    Utils.showToast('功能开发中')
  }

  private openEditHeightRecord(_record: BodyRecordModel): void {
    Utils.showToast('功能开发中')
  }

  private deleteHeightRecord(record: BodyRecordModel): void {
    appDataManager.deleteBodyRecordAndId(record.id)
    const nextRecords = this.heightRecords.filter((item) => item.id !== record.id)
    this.heightRecords = nextRecords
    const latestHeight = nextRecords.length > 0 ? parseFloat(nextRecords[0].data) : 0
    this.persistHeightAndRefreshMetrics(latestHeight)
    this.refreshHeightRecords()
  }

  private closeHeightDialog(): void {
    if (this.heightDialog) {
      this.heightDialog.close()
      this.heightDialog = null
    }
  }

  @Builder
  private heightRecordDialogBuilder() {
    Column() {
      Row() {
        Blank()
          .width(24)

        Text('身高记录')
          .fontSize(16)
          .fontWeight(600)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('关闭')
          .fontSize(14)
          .fontColor('#0cc291')
          .onClick(() => {
            this.closeHeightDialog()
          })
      }
      .width('100%')
      .padding({ bottom: 12 })

      if (this.heightRecords.length > 0) {
        Column() {
          ForEach(this.heightRecords, (item: BodyRecordModel, index: number) => {
            Row() {
              Column() {
                Text(`${item.data}${item.unit}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#222222')
                Text(DateUtils.timeToDate(item.time))
                  .fontSize(12)
                  .fontColor('#888888')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)

              Row() {
                Text('修改')
                  .fontSize(13)
                  .fontColor('#0cc291')
                  .onClick(() => {
                    this.openEditHeightRecord(item)
                  })

                Text('删除')
                  .fontSize(13)
                  .fontColor('#FF6B6B')
                  .margin({ left: 16 })
                  .onClick(() => {
                    this.deleteHeightRecord(item)
                  })
              }
            }
            .padding({ top: 12, bottom: 12, left: 12, right: 12 })
            .backgroundColor('#F7F9F9')
            .borderRadius(12)
            .margin({ top: index === 0 ? 0 : 12 })
          }, (item: BodyRecordModel) => `${item.id}-${item.time}`)
        }
      } else {
        Column() {
          Text('暂无身高记录')
            .fontSize(14)
            .fontColor('#888888')
          Text('点击下方按钮即可添加。')
            .fontSize(12)
            .fontColor('#BBBBBB')
            .margin({ top: 6 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 12, bottom: 12 })
      }

      Button('添加身高记录')
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .backgroundColor('#0cc291')
        .borderRadius(22)
        .margin({ top: 20 })
        .onClick(() => {
          this.openAddHeightRecord()
        })
    }
    .padding({ left: 20, right: 20, top: 16, bottom: 24 })
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  private getSummaryCards(): Array<SummaryCardConfig> {
    return [
      {
        id: 'height',
        title: '我的身高',
        value: this.formatNumber(this.currentHeight, 1),
        unit: this.currentHeight > 0 ? '厘米' : '',
        icon: $r('app.media.icon_my_height'),
        accent: '#42C7A7',
        badgeBackground: 'rgba(66,199,167,0.18)',
        onTap: () => {
          this.openHeightRecordSheet()
        }
      },
      {
        id: 'weight',
        title: '我的体重',
        value: this.formatWeightDisplay(),
        unit: this.currentWeight > 0 ? this.getWeightUnitLabel() : '',
        icon: $r('app.media.icon_my_weight'),
        accent: '#FF8CB3',
        badgeBackground: 'rgba(255,140,179,0.18)'
      },
      {
        id: 'bmr',
        title: '基础代谢',
        value: this.basalMetabolism > 0 ? this.basalMetabolism.toString() : '--',
        unit: this.basalMetabolism > 0 ? '千卡' : '',
        icon: $r('app.media.icon_my_bmr'),
        accent: '#FF8C47',
        badgeBackground: 'rgba(255,140,71,0.18)',
        onTap: () => {
          router.pushUrl({ url: 'pages/BasalMetabolismPage' })
        }
      },
      {
        id: 'bmi',
        title: '身体质量指数',
        value: this.bmi > 0 ? this.bmi.toFixed(1) : '--',
        note: this.bmi > 0 ? this.bmiStatus : '',
        icon: $r('app.media.icon_my_bmi'),
        accent: '#77C693',
        badgeBackground: 'rgba(119,198,147,0.18)',
        noteColor: this.getBmiNoteColor(),
        onTap: () => {
          router.pushUrl({ url: 'pages/BodyMassIndexPage' })
        }
      }
    ]
  }

  private getNavigationItems(): Array<NavItemConfig> {
    return [
      {
        id: 'unit',
        icon: $r('app.media.icon_my_unit'),
        title: '切换单位',
        trailing: this.getWeightUnitLabel(),
        onTap: () => void this.toggleWeightUnit()
      },
      {
        id: 'calendar',
        icon: $r('app.media.icon_my_calendar'),
        title: '汇总日历',
        onTap: () => {
          router.pushUrl({ url: 'pages/WeightCalendarPage' })
        }
      },
      {
        id: 'food',
        icon: $r('app.media.icon_my_food'),
        title: '食物热量查询',
        onTap: () => this.openFoodHeatPage()
      },
      {
        id: 'settings',
        icon: $r('app.media.icon_my_settings'),
        title: '设置',
        onTap: () => {
          router.pushUrl({ url: 'pages/SettingPage' })
        }
      }
    ]
  }

  build() {
    Column() {
      Scroll(this.scroller) {
        Column() {
          this.profileHeader()

          Column() {
            this.summarySection(this.getSummaryCards())
            this.navigationPanel(this.getNavigationItems())
          }
          .width('100%')
          .margin({ top: -36 })
          .padding({ left: 16, right: 16, bottom: this.getSafeBottomPadding() + 24 })
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private profileHeader() {
    Stack() {
      Image($r('app.media.my_profile_bg'))
        .width('100%')
        .height(220)
        .borderRadius({ bottomLeft: 32, bottomRight: 32 })

      Column() {
        Row() {
          Row() {
            Image($r('app.media.user_image'))
              .width(64)
              .height(64)
              .borderRadius(32)
              .backgroundColor('rgba(255,255,255,0.2)')

            Column() {
              Text(this.nickname)
                .fontSize(20)
                .fontWeight(600)
                .fontColor('#222222')

              Text(this.getStreakText())
                .fontSize(12)
                .fontColor('#0cc291')
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .backgroundColor('rgba(12,194,145,0.12)')
                .borderRadius(12)
                .margin({ top: 8 })
            }
            .margin({ left: 16 })
          }
          .layoutWeight(1)

          Row() {
            Text('个人信息')
              .fontSize(14)
              .fontColor('#222222')
            Image($r('app.media.right_point'))
              .width(16)
              .height(16)
              .margin({ left: 6 })
              .fillColor('#999999')
          }
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingPage' })
          })
        }
        .width('100%')

        Text('请保持良好的作息与饮食，保持健康状态')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 18 })
      }
      .padding({ top: 48, left: 24, right: 24 })
    }
    .width('100%')
    .margin({ bottom: 24 })
  }

  @Builder
  private summarySection(cards: Array<SummaryCardConfig>) {
    if (cards.length >= 2) {
      this.summaryRow(cards[0], cards[1])
    }
    if (cards.length >= 4) {
      this.summaryRow(cards[2], cards[3])
    }
  }

  @Builder
  private summaryRow(leftCard: SummaryCardConfig, rightCard: SummaryCardConfig) {
    Row() {
      Column() {
        this.summaryCard(leftCard)
      }
        .layoutWeight(1)
        .margin({ right: 8 })
      Column() {
        this.summaryCard(rightCard)
      }
        .layoutWeight(1)
        .margin({ left: 8 })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  private summaryCard(config: SummaryCardConfig) {
    Column() {
      Row() {
        Column() {
          Text(config.title)
            .fontSize(14)
            .fontWeight(500)
            .fontColor('#333333')

          if (config.note && config.note.length > 0) {
            Text(config.note)
              .fontSize(12)
              .fontColor(config.noteColor ?? config.accent)
              .margin({ top: 6 })
          }
        }
        .layoutWeight(1)

        Row() {
          Image(config.icon)
            .width(28)
            .height(28)
            .objectFit(ImageFit.Contain)
        }
        .width(48)
        .height(48)
        .backgroundColor(config.badgeBackground)
        .borderRadius(24)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row() {
        Text(config.value)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')

        if (config.unit && config.unit.length > 0) {
          Text(config.unit)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 4 })
        } else {
          // 即使没有单位，也保留占位空间，确保卡片高度一致
          Blank()
            .width(0)
            .height(28) // 与数字高度保持一致
        }
      }
      .height(56) // 固定高度，确保所有卡片大小一致
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 12 })
    }
    .width('100%')
    .height(140) // 固定高度，确保所有卡片大小一致
    .padding({ top: 20, bottom: 20, left: 20, right: 20 })
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ color: 'rgba(12,194,145,0.08)', radius: 8, offsetX: 0, offsetY: 4 })
    .onClick(() => {
      if (config.onTap) {
        config.onTap()
      }
    })
  }

  @Builder
  private navigationPanel(items: Array<NavItemConfig>) {
    Column() {
      ForEach(items, (item: NavItemConfig, index: number) => {
        this.navigationRow(item, index === items.length - 1)
      }, (item: NavItemConfig) => item.id)
    }
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .padding({ left: 16, right: 12 })
    .margin({ top: 12 })
  }

  @Builder
  private navigationRow(item: NavItemConfig, isLast: boolean) {
    Column() {
      Row() {
        Row() {
          Image(item.icon)
            .width(24)
            .height(24)
          Text(item.title)
            .fontSize(16)
            .fontColor('#333333')
            .margin({ left: 14 })
        }
        .layoutWeight(1)

        if (item.trailing && item.trailing.length > 0) {
          Text(item.trailing)
            .fontSize(14)
            .fontColor('#999999')
            .margin({ right: 8 })
        }

        Image($r('app.media.right_point'))
          .width(16)
          .height(16)
          .fillColor('#C8C8C8')
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        item.onTap()
      })

      if (!isLast) {
        Row()
          .width('100%')
          .height(1)
          .backgroundColor('#F0F0F0')
      }
    }
  }

  private getSafeBottomPadding(): number {
    // 适配底部安全区域，默认返回16
    return 16
  }
}
