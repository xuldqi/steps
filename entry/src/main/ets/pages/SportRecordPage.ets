import { router, window } from '@kit.ArkUI';
import { SportModel } from '../appdata/Model';
import AppDataManager, { DataCallback } from '../tools/AppDataManager';
import { DateUtils } from '../tools/DateUtils';
import { Log } from '../tools/Logger';
import { Utils } from '../tools/Utils';
import { Common2TitleData, Common2TitleView } from '../view/Common2TitleView';
import { SportTypeDialog } from '../view/SportTypeDialog';
import { SubFragmentData } from '../view/SubFragment';
import { McBarChart, Options } from '@mcui/mccharts';
import { SportRecordDialog } from '../view/SportRecordDialog';
import { CommonTitleView } from '../view/CommonTitleView';
import EntryAbility from '../entryability/EntryAbility';

interface SportTypeStat {
  name: string
  value: number
  display: string
  percentage: number
}

interface SportTypeAggregate {
  count: number
  minutes: number
  calories: number
}

interface TimeRangeWindow {
  start: number
  end: number
}

interface ChartSeriesData {
  labels: Array<string>
  values: Array<number>
  title: string
}

@Entry
@Component
struct SportRecordPage {
  @State currentType: number = 0
  @State data: Array<SportModel> = new Array<SportModel>();
  
  // 统计相关状态
  @State curOffset: number = 0
  @State top_week: string = ''
  @State totalDistance: number = 0
  @State totalTime: number = 0
  @State totalActivities: number = 0
  @State totalCalories: number = 0
  @State selectedMetric: string = '运动时长' // 运动次数、运动时长、消耗热量（默认运动时长）
  @State timeRange: string = '周' // 周、月、年
  private dates: Array<string> = new Array<string>()
  private readonly metricOptions: Array<string> = ['运动时长', '运动次数', '消耗热量']
  @State showMetricSelector: boolean = false
  @State showSportTypeSelector: boolean = false
  
  @State seriesRadiusOption: Options = new Options({
    legend: { show: false },
    title: { show: true, text: '最近七天的运动时长', right: 20, top: 30 },
    xAxis: { data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']},
    series: [{ name: '运动时长', barStyle: { 
          width: 10,
          color:'#0cc291',
          borderRadius: [4, 4] },
        data: [0, 0, 0, 0, 0, 0, 0] }]
  })

  // 运动类型占比数据
  @State sportTypeStats: Array<SportTypeStat> = []
  private initialized: boolean = false


  onPageShow(): void {
    if (!this.initialized) {
      let params = router.getParams() as SubFragmentData;
      if (params && params.type !== undefined) {
        this.currentType = params.type
        Log.i('SportRecordPage Received: ' + this.currentType);
      } else {
        this.currentType = 0
        Log.i('SportRecordPage Using default type: ' + this.currentType);
      }
      this.selectedMetric = '运动时长'
      this.timeRange = '周'
      this.curOffset = 0
      this.initialized = true
      this.showWeekSportRecord(this.curOffset)
      return
    }

    const status = AppDataManager.getSportDataStatus()
    if (status.isChange) {
      this.showWeekSportRecord(this.curOffset)
      AppDataManager.resetSportDataStatus()
    }
  }

  exitApp() {

  }

  private sportCallback:DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      if(isReturnFirstData){
        if(type === 1){

        }
      }else{
        this.data.length = 0
        this.data = result
        this.refreshVisualData()
      }
    }
  }

  private refreshVisualData(): void {
    this.recalculateRangeStatistics()
    this.updateChartData()
  }

  private recalculateRangeStatistics(): void {
    const range = this.getCurrentRangeWindow()
    const recordsInRange: Array<SportModel> = this.data.filter((record: SportModel) => record.start_time >= range.start && record.start_time <= range.end)

    this.totalActivities = recordsInRange.length
    let totalMinutes = 0
    let totalCalories = 0
    let totalDistance = 0

    const typeAggregates: Map<number, SportTypeAggregate> = new Map()

    for (const record of recordsInRange) {
      const minutes = Math.max(0, Math.floor(record.use_time / 60000))
      const calories = this.getCaloriesForRecord(record)
      const distance = Number.parseFloat(Utils.getDistanceByStep(record.steps))

      totalMinutes = totalMinutes + minutes
      totalCalories = totalCalories + calories
      totalDistance = totalDistance + (Number.isNaN(distance) ? 0 : distance)

      let aggregate = typeAggregates.get(record.type)
      if (!aggregate) {
        aggregate = { count: 0, minutes: 0, calories: 0 }
        typeAggregates.set(record.type, aggregate)
      }
      aggregate.count = aggregate.count + 1
      aggregate.minutes = aggregate.minutes + minutes
      aggregate.calories = aggregate.calories + calories
    }

    this.totalTime = totalMinutes
    this.totalCalories = totalCalories
    this.totalDistance = totalDistance

    const totalMetric = this.selectedMetric === '运动次数'
      ? this.totalActivities
      : this.selectedMetric === '运动时长'
        ? totalMinutes
        : totalCalories

    const stats: Array<SportTypeStat> = []
    typeAggregates.forEach((aggregate: SportTypeAggregate, type: number) => {
      const metricValue = this.getMetricValueFromAggregate(aggregate, this.selectedMetric)
      const percentage = totalMetric > 0 ? Math.round(metricValue / totalMetric * 1000) / 10 : 0
      stats.push({
        name: Utils.getSportRecordName(type),
        value: metricValue,
        display: this.formatMetricDisplay(metricValue, this.selectedMetric),
        percentage: percentage
      })
    })

    stats.sort((a, b) => b.value - a.value)
    this.sportTypeStats = stats
  }

  private getCurrentRangeWindow(): TimeRangeWindow {
    if (this.timeRange === '周') {
      const startDate = this.getDateByOffset(6 + 7 * this.curOffset)
      const endDate = this.getDateByOffset(7 * this.curOffset)
      return {
        start: this.getStartOfDay(startDate),
        end: this.getEndOfDay(endDate)
      }
    } else if (this.timeRange === '月') {
      const base = this.getMonthBaseDate(this.curOffset)
      const monthEnd = new Date(base.getFullYear(), base.getMonth() + 1, 0)
      return {
        start: this.getStartOfDay(base),
        end: this.getEndOfDay(monthEnd)
      }
    }
    const year = new Date().getFullYear() - this.curOffset
    const startDate = new Date(year, 0, 1)
    const endDate = new Date(year, 11, 31)
    return {
      start: this.getStartOfDay(startDate),
      end: this.getEndOfDay(endDate)
    }
  }

  private getCaloriesForRecord(record: SportModel): number {
    let calories = Number.parseFloat(record.cal ?? '0')
    if (Number.isNaN(calories) || calories <= 0) {
      calories = Math.round(parseFloat(Utils.getDistanceByStep(record.steps)) * 50)
    }
    return Number.isNaN(calories) ? 0 : calories
  }

  private getMetricValueFromAggregate(aggregate: SportTypeAggregate, metric: string): number {
    if (metric === '运动次数') {
      return aggregate.count
    } else if (metric === '运动时长') {
      return aggregate.minutes
    } else if (metric === '消耗热量') {
      return aggregate.calories
    }
    return 0
  }

  private formatMetricDisplay(value: number, metric: string): string {
    if (metric === '运动次数') {
      return `${Math.round(value)}次`
    } else if (metric === '运动时长') {
      return `${Math.round(value)}分钟`
    } else if (metric === '消耗热量') {
      return `${Math.round(value)}千卡`
    }
    return `${Math.round(value)}`
  }

  private showWeekSportRecord(i: number) {
    this.curOffset = i
    this.refreshRangeWindow()
    AppDataManager.findSportByType(this.currentType, this.sportCallback, false)
  }

  private openAddSportDialog() {
    // 使用简单的页面跳转方式
    router.pushUrl({
      url: 'pages/AddSportPage',
      params: {
        sportType: this.currentType === 0 ? 1 : this.currentType
      }
    })
  }

  private setTimeRange(range: string) {
    if (this.timeRange === range) {
      console.info('[SportRecordPage] setTimeRange: 已经是', range, '范围，无需切换')
      this.showMetricSelector = false
      return
    }
    console.info('[SportRecordPage] setTimeRange: 从', this.timeRange, '切换到', range)
    this.timeRange = range
    this.curOffset = 0 // 重置为当前周期
    this.showMetricSelector = false
    this.refreshRangeWindow()
    this.refreshVisualData()
  }

  private changeRangeOffset(delta: number) {
    this.showMetricSelector = false
    const candidate = this.curOffset + delta
    if (candidate < 0) {
      console.info('[SportRecordPage] changeRangeOffset: 已达到最早时间，无法继续向前')
      return
    }
    console.info('[SportRecordPage] changeRangeOffset: 从', this.curOffset, this.timeRange, '切换到', candidate, this.timeRange)
    this.curOffset = candidate
    this.refreshRangeWindow()
    this.refreshVisualData()
  }

  private refreshRangeWindow(): void {
    if (this.timeRange === '周') {
      const start = this.getDateByOffset(6 + 7 * this.curOffset)
      const end = this.getDateByOffset(7 * this.curOffset)
      this.top_week = `${this.formatDateCN(start)} - ${this.formatDateCN(end)}`
    } else if (this.timeRange === '月') {
      const base = this.getMonthBaseDate(this.curOffset)
      this.top_week = `${base.getFullYear()}年${base.getMonth() + 1}月`
    } else {
      const year = new Date().getFullYear() - this.curOffset
      this.top_week = `${year}年`
    }
  }

  private updateChartData(): void {
    const chartData: ChartSeriesData = this.computeChartSeries()
    this.seriesRadiusOption.setVal({
      legend: { show: false },
      title: { show: true, text: chartData.title, right: 20, top: 30 },
      xAxis: { data: chartData.labels },
      series: [{
        name: this.selectedMetric,
        barStyle: {
          width: 10,
          color: '#0cc291',
          borderRadius: [4, 4]
        },
        data: chartData.values
      }]
    })
  }

  private computeChartSeries(): ChartSeriesData {
    const labels: Array<string> = []
    const values: Array<number> = []
    let title = `最近七天的${this.selectedMetric}`

    if (this.timeRange === '周') {
      for (let day = 6; day >= 0; day--) {
        const offset = day + 7 * this.curOffset
        const date = this.getDateByOffset(offset)
        const startMs = this.getStartOfDay(date)
        const endMs = this.getEndOfDay(date)
        const labelKey = this.formatDateKey(date)
        labels.push(DateUtils.getWeek(labelKey))
        values.push(this.normalizeMetricValue(this.calculateMetricInRange(startMs, endMs)))
      }
      title = `最近七天的${this.selectedMetric}`
    } else if (this.timeRange === '月') {
      const base = this.getMonthBaseDate(this.curOffset)
      const year = base.getFullYear()
      const month = base.getMonth()
      const daysInMonth = new Date(year, month + 1, 0).getDate()
      for (let day = 1; day <= daysInMonth; day++) {
        const current = new Date(year, month, day)
        const startMs = this.getStartOfDay(current)
        const endMs = this.getEndOfDay(current)
        labels.push(`${day}日`)
        values.push(this.normalizeMetricValue(this.calculateMetricInRange(startMs, endMs)))
      }
      title = `${year}年${month + 1}月的${this.selectedMetric}`
    } else {
      const year = new Date().getFullYear() - this.curOffset
      for (let month = 0; month < 12; month++) {
        const monthStart = new Date(year, month, 1)
        const monthEnd = new Date(year, month + 1, 0)
        const startMs = this.getStartOfDay(monthStart)
        const endMs = this.getEndOfDay(monthEnd)
        labels.push(`${month + 1}月`)
        values.push(this.normalizeMetricValue(this.calculateMetricInRange(startMs, endMs)))
      }
      title = `${year}年的${this.selectedMetric}`
    }

    const result: ChartSeriesData = {
      labels: labels,
      values: values,
      title: title
    }
    return result
  }

  private getRangeSummaryLabel(): string {
    if (this.timeRange === '周') {
      const end = this.getDateByOffset(7 * this.curOffset)
      return this.formatDateCN(end)
    } else if (this.timeRange === '月') {
      const base = this.getMonthBaseDate(this.curOffset)
      return `${base.getFullYear()}年${base.getMonth() + 1}月`
    } else {
      const year = new Date().getFullYear() - this.curOffset
      return `${year}年`
    }
  }

  private calculateMetricInRange(startMs: number, endMs: number): number {
    let total = 0
    for (const item of this.data) {
      const recordTime = item.start_time
      if (recordTime >= startMs && recordTime <= endMs) {
        if (this.selectedMetric === '运动次数') {
          total += 1
        } else if (this.selectedMetric === '运动时长') {
          total += Math.max(0, Math.floor(item.use_time / 60000))
        } else if (this.selectedMetric === '消耗热量') {
          total += this.getCaloriesForRecord(item)
        }
      }
    }
    return total
  }

  private normalizeMetricValue(value: number): number {
    if (this.selectedMetric === '运动次数') {
      return Math.max(0, Math.round(value))
    } else if (this.selectedMetric === '运动时长') {
      return Math.max(0, Math.round(value))
    } else if (this.selectedMetric === '消耗热量') {
      return Math.max(0, Math.round(value))
    }
    return value
  }

  private getDateByOffset(offsetDays: number): Date {
    const base = new Date()
    base.setHours(0, 0, 0, 0)
    base.setDate(base.getDate() - offsetDays)
    return base
  }

  private getMonthBaseDate(offsetMonths: number): Date {
    const base = new Date()
    base.setHours(0, 0, 0, 0)
    base.setDate(1)
    base.setMonth(base.getMonth() - offsetMonths)
    return base
  }

  private formatDateCN(date: Date): string {
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`
  }

  private formatDateKey(date: Date): string {
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`
  }

  private getStartOfDay(date: Date): number {
    const copy = new Date(date)
    copy.setHours(0, 0, 0, 0)
    return copy.getTime()
  }

  private getEndOfDay(date: Date): number {
    const copy = new Date(date)
    copy.setHours(23, 59, 59, 999)
    return copy.getTime()
  }

  build() {
    Stack() {
      Column() {
        // 顶部标题栏
        Row() {
          Image($r('app.media.back_btn_dark'))
            .width(20)
            .height(20)
            .onClick(() => {
              router.back()
            })
          
          Row() {
            Text(Utils.getSportRecordTitle(this.currentType))
              .fontSize(18)
              .fontWeight(500)
              .fontColor('#333333')
              .textAlign(TextAlign.Center)
              .margin({ right: 4 })
            Text(this.showSportTypeSelector ? '▲' : '▼')
              .fontSize(12)
              .fontColor('#666666')
          }
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
          .height(40)
          .onClick(() => {
            this.toggleSportTypeSelector()
          })
        }
        .width('100%')
        .padding({ top: this.getSafeTopPadding() + 16, bottom: 16, left: 20, right: 20 })
        .backgroundColor('#F5F5F5')
        .border({ width: { bottom: 1 }, color: '#E5E5E5' })
        
        Scroll() {
          Column() {
            // 趋势查看区域
            this.buildTrendSection()
            
            // 信息概览
            this.buildInfoOverview()
            
            // 运动次数占比（仅全部运动时显示）
            if (this.currentType === 0) {
              this.buildSportTypeStats()
            }
            
            // 添加运动按钮
            this.buildAddSportButton()
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      if (this.showSportTypeSelector) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#33000000')
          .onClick(() => {
            this.showSportTypeSelector = false
          })
      }

      if (this.showSportTypeSelector) {
        Column() {
          SportTypeDialog({
            currentType: this.currentType,
            onSelect: (type: number) => {
              this.onSportTypeSelected(type)
            }
          })
        }
        .width('88%')
        .align(Alignment.TopStart)
        .margin({ top: this.getSportTypeSelectorTopMargin(), left: 20, right: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  onBackPress(): boolean {
    if (this.showSportTypeSelector) {
      this.showSportTypeSelector = false
      return true
    }
    return false
  }

  private getSafeTopPadding(): number {
    if (!EntryAbility.myWindowClass) {
      return 0
    }
    const avoidArea = EntryAbility.myWindowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    return Math.max(0, avoidArea.topRect.height - 80)
  }

  private getSportTypeSelectorTopMargin(): number {
    return this.getSafeTopPadding() + 72
  }

  @Builder
  buildTrendSection() {
    Stack() {
      Column() {
        Row() {
          Text('趋势查看')
            .fontSize(16)
            .fontWeight(500)
            .fontColor('#333333')
            .layoutWeight(1)

          Row() {
            Text(this.selectedMetric)
              .fontSize(14)
              .fontColor('#333333')
            Text('▼')
              .fontSize(12)
              .fontColor('#333333')
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#F4F4F4')
          .borderRadius(16)
          .onClick(() => {
            this.toggleMetricSelector()
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row() {
          ForEach(['周', '月', '年'], (item: string) => {
            Text(item)
              .fontSize(14)
              .fontColor(this.timeRange === item ? '#FFFFFF' : '#333333')
              .fontWeight(this.timeRange === item ? FontWeight.Medium : FontWeight.Normal)
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
              .backgroundColor(this.timeRange === item ? '#0cc291' : '#F0F0F0')
              .borderRadius(16)
              .margin({ left: 4, right: 4 })
              .opacity(this.timeRange === item ? 1 : 0.8)
              .onClick(() => {
                console.info('[SportRecordPage] 点击时间范围:', item)
                this.setTimeRange(item)
              })
          }, (item: string, index: number) => `range-${item}-${index}`)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .margin({ top: 12, bottom: 12 })

        Row() {
          Image($r('app.media.back_btn_dark'))
            .width(20)
            .height(20)
            .onClick(() => {
              this.changeRangeOffset(1)
            })

          Text(this.top_week)
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Image($r('app.media.right_btn'))
            .width(20)
            .height(20)
            .onClick(() => {
              this.changeRangeOffset(-1)
            })
        }
        .width('100%')
        .margin({ bottom: 12 })

        Row() {
          Text(this.getCurrentValue())
            .fontSize(24)
            .fontWeight(600)
            .fontColor('#333333')

          Text(this.getCurrentUnit())
            .fontSize(16)
            .fontColor('#666666')
            .margin({ left: 8 })

          Text(this.getRangeSummaryLabel())
            .fontSize(14)
            .fontColor('#666666')
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .margin({ bottom: 16 })

        Row() {
          McBarChart({
            options: this.seriesRadiusOption
          })
        }
        .height(200)
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ bottom: 12 })

      if (this.showMetricSelector) {
        Column() {
          ForEach(this.metricOptions, (option: string, index: number) => {
            Text(option)
              .fontSize(14)
              .fontColor(this.selectedMetric === option ? '#333333' : '#999999')
              .fontWeight(this.selectedMetric === option ? 600 : 400)
              .padding({ left: 16, right: 16, top: 10, bottom: 10 })
              .width('100%')
              .backgroundColor(this.selectedMetric === option ? '#F3F7F5' : '#FFFFFF')
              .textAlign(TextAlign.Start)
              .onClick(() => {
                this.onMetricSelect(option)
              })
          }, (option: string, index: number) => `metric-${index}`)
        }
        .width(140)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .border({ width: 1, color: '#EAEAEA' })
        .align(Alignment.TopEnd)
        .margin({ top: 62, right: 32 })
      }
    }
    .width('100%')
  }

  @Builder
  buildInfoOverview() {
    Column() {
      Text('信息概览')
        .fontSize(16)
        .fontWeight(500)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })
      
      Row() {
        Column() {
          Text('运动时长')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 4 })
          Text((this.totalTime / 60).toFixed(1))
            .fontSize(20)
            .fontWeight(600)
            .fontColor('#333333')
          Text('小时')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        
        Column() {
          Text('运动次数')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 4 })
          Text(this.totalActivities.toString())
            .fontSize(20)
            .fontWeight(600)
            .fontColor('#333333')
          Text('次')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        
        Column() {
          Text('消耗热量')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 4 })
          Text(this.totalCalories.toFixed(0))
            .fontSize(20)
            .fontWeight(600)
            .fontColor('#333333')
          Text('千卡')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  buildSportTypeStats() {
    Column() {
      Row() {
        Text('运动占比')
          .fontSize(16)
          .fontWeight(500)
          .fontColor('#333333')
          .layoutWeight(1)

        Text(this.selectedMetric)
          .fontSize(12)
          .fontColor('#666666')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#F3F7F5')
          .borderRadius(12)
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      ForEach(this.sportTypeStats, (item: SportTypeStat, index: number) => {
        Row() {
          Text((index + 1).toString())
            .fontSize(14)
            .fontColor('#666666')
            .width(20)
          
          Text(item.name)
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
            .margin({ left: 8 })
          
          Text(item.display)
            .fontSize(14)
            .fontColor('#333333')
            .margin({ right: 8 })
          
          Text(item.percentage.toFixed(1) + '%')
            .fontSize(14)
            .fontColor('#0cc291')
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .border({ width: { bottom: 1 }, color: '#F0F0F0' })
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  buildAddSportButton() {
    Button('添加运动')
      .fontSize(16)
      .fontColor('#FFFFFF')
      .backgroundColor('#0cc291')
      .borderRadius(8)
      .width('100%')
      .height(48)
      .onClick(() => {
        this.openAddSportDialog()
      })
      .margin({ bottom: 20 })
  }

  private getCurrentValue(): string {
    if (this.selectedMetric === '运动次数') {
      return this.totalActivities.toString()
    } else if (this.selectedMetric === '运动时长') {
      return Math.max(0, Math.round(this.totalTime)).toString()
    } else if (this.selectedMetric === '消耗热量') {
      return Math.round(this.totalCalories).toString()
    }
    return '0'
  }

  private getCurrentUnit(): string {
    if (this.selectedMetric === '运动次数') {
      return '次'
    } else if (this.selectedMetric === '运动时长') {
      return '分钟'
    } else if (this.selectedMetric === '消耗热量') {
      return '千卡'
    }
    return ''
  }

  private toggleSportTypeSelector(): void {
    this.showSportTypeSelector = !this.showSportTypeSelector
  }

  private onSportTypeSelected(type: number): void {
    const nextType = type
    this.showSportTypeSelector = false
    if (this.currentType === nextType) {
      return
    }
    this.currentType = nextType
    this.showWeekSportRecord(this.curOffset)
  }

  private toggleMetricSelector(): void {
    this.showMetricSelector = !this.showMetricSelector
  }

  private onMetricSelect(metric: string): void {
    if (this.selectedMetric === metric) {
      this.showMetricSelector = false
      return
    }
    this.selectedMetric = metric
    this.showMetricSelector = false
    this.refreshVisualData()
  }

}
