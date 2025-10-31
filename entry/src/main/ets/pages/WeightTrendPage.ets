import { CommonTitleView } from '../view/CommonTitleView'
import { router } from '@kit.ArkUI'
import { McBarChart, Options } from '@mcui/mccharts'
import appDataManager, { AppDataManager, DataCallback } from '../tools/AppDataManager'
import { BodyRecordModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'
import preferencesUtil from '../tools/DataPreUtils'
import targetManager from '../tools/TargetManager'
import { BodyRecordDialog } from '../view/BodyRecordDialog'

type ViewMode = 'week' | 'month' | 'year'
type FilterMode = 'min' | 'max' | 'avg' | 'first' | 'last'

@Entry
@Component
struct WeightTrendPage {
  @State viewMode: ViewMode = 'week'
  @State filterMode: FilterMode = 'min'
  @State topRange: string = ''
  @State chartOptions: Options = new Options({
    legend: { show: false },
    xAxis: { data: [] },
    series: [{ name: '', barStyle: { width: 10, color: '#0cc291', borderRadius: [4, 4] }, data: [] }]
  })

  // 目标/当前/初始
  @State initialWeight: number = 0
  @State currentWeight: number = 0
  @State targetWeight: number = 0
  @State daysPersisted: number = 0
  @State initialDateLabel: string = '--'
  @State currentDateLabel: string = '--'
  @State targetDateLabel: string = '--'
  @State progressSummary: string = '暂无体重记录'
  @State progressPercent: number = 0

  // 概览
  @State statDays: number = 0
  @State statMax: string = '--'
  @State statMin: string = '--'
  @State statAvgDelta: string = '--'
  @State highlightValue: string = '--'
  @State highlightLabel: string = ''

  private allWeights: Array<BodyRecordModel> = []
  private windowEndDate: Date = new Date()
  private filterDialog?: CustomDialogController = undefined
  private earliestRecord: BodyRecordModel | null = null
  private latestRecord: BodyRecordModel | null = null

  private weightCallback: DataCallback<BodyRecordModel> = {
    onDataResult: (type: number, result: BodyRecordModel[], isFirst: boolean): void => {
      if (type !== AppDataManager.TYPE_WEIGHT) return
      console.info('[WeightTrendPage] weightCallback: received', result?.length || 0, 'weight records')
      this.allWeights = result || []
      if (this.allWeights.length > 0) {
        console.info('[WeightTrendPage] weightCallback: first record - id=', this.allWeights[0].id, 'time=', this.allWeights[0].time, 'data=', this.allWeights[0].data)
      }
      this.refreshAll()
    }
  }

  onPageShow() {
    // 先加载配置，再刷新数据
    void this.loadPrefs().then(() => {
      this.refreshData()
    })
    // 初始化筛选弹窗
    this.filterDialog = new CustomDialogController({ builder: (): void => { this.filterDialogBuilder() }, autoCancel: true })
  }

  private refreshData() {
    appDataManager.findBodyRecordByType(AppDataManager.TYPE_WEIGHT, this.weightCallback, false)
  }

  private async loadPrefs() {
    const saved = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight_trend_filter', 'min') as string
    if (['min','max','avg','first','last'].includes(saved)) {
      this.filterMode = saved as FilterMode
    }
    const t = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight_target', 0) as number
    this.targetWeight = t
    const targetTime = await preferencesUtil.getPreferenceValue('steps_ohos', 'weight_target_update_time', 0) as number
    this.targetDateLabel = targetTime > 0 ? this.formatDisplayDate(targetTime) : '--'
  }

  private async saveFilter() {
    await preferencesUtil.putPreferenceValue('steps_ohos', 'weight_trend_filter', this.filterMode)
  }

  private refreshAll() {
    this.computeBaseFigures()
    this.updateChart()
    this.updateOverview()
    // 添加调试日志
    console.info('[WeightTrendPage] refreshAll: allWeights.length=', this.allWeights.length)
    console.info('[WeightTrendPage] refreshAll: statDays=', this.statDays)
    console.info('[WeightTrendPage] refreshAll: statMin=', this.statMin, 'statMax=', this.statMax)
  }

  private computeBaseFigures() {
    if (this.allWeights.length === 0) {
      this.initialWeight = 0
      this.currentWeight = 0
      this.daysPersisted = 0
      this.initialDateLabel = '--'
      this.currentDateLabel = '--'
      this.progressPercent = 0
      this.progressSummary = '暂无体重记录，快去记录吧'
      this.earliestRecord = null
      this.latestRecord = null
      return
    }
    const sorted = [...this.allWeights].sort((a, b) => a.time - b.time)
    this.earliestRecord = sorted[0]
    this.latestRecord = sorted[sorted.length - 1]
    this.initialWeight = parseFloat(sorted[0].data)
    this.currentWeight = parseFloat(sorted[sorted.length - 1].data)
    this.initialDateLabel = this.formatDisplayDate(sorted[0].time)
    this.currentDateLabel = this.formatDisplayDate(sorted[sorted.length - 1].time)
    const firstDay = new Date(sorted[0].time).toDateString()
    const today = new Date().toDateString()
    const ms = new Date(today).getTime() - new Date(firstDay).getTime()
    this.daysPersisted = Math.max(1, Math.floor(ms / 86400000) + 1)
    if (this.targetWeight <= 0) this.targetWeight = this.currentWeight

    const diff = this.currentWeight - this.initialWeight
    const diffAbs = Math.abs(diff).toFixed(1)
    let diffText = '体重保持不变'
    if (diff < -0.05) {
      diffText = `共减少${diffAbs}公斤`
    } else if (diff > 0.05) {
      diffText = `共增加${diffAbs}公斤`
    }

    const remain = this.currentWeight - this.targetWeight
    const remainAbs = Math.abs(remain).toFixed(1)
    let remainText = '已达到目标'
    if (remain > 0.05) {
      remainText = `距离目标还${remainAbs}公斤`
    } else if (remain < -0.05) {
      remainText = `已超越目标${remainAbs}公斤`
    }

    let progress = 0
    if (Math.abs(this.initialWeight - this.targetWeight) > 0.001) {
      progress = (this.initialWeight - this.currentWeight) / (this.initialWeight - this.targetWeight) * 100
    } else if (Math.abs(this.currentWeight - this.targetWeight) < 0.01) {
      progress = 100
    }
    progress = Math.max(0, Math.min(100, progress))
    this.progressPercent = progress
    this.progressSummary = `已坚持${this.daysPersisted}天，${diffText}，${remainText}，进度已完成${progress.toFixed(0)}%`
  }

  // 生成窗口内数据并绘图
  private updateChart() {
    const labels: Array<string> = []
    const values: Array<number> = []
    this.collectWindow(labels, values)
    this.chartOptions.setVal({
      xAxis: { data: labels },
      series: [{ name: '', barStyle: { width: 10, color: '#0cc291', borderRadius: [4, 4] }, data: values }]
    })
  }

  private groupByDay(records: BodyRecordModel[]): Map<string, Array<BodyRecordModel>> {
    const map = new Map<string, Array<BodyRecordModel>>()
    for (const r of records) {
      const key = this.formatYMDFromMs(r.time)
      if (!map.has(key)) {
        map.set(key, [])
      }
      map.get(key)!.push(r)
    }
    return map
  }

  private formatYMDFromMs(ms: number): string {
    const d: Date = new Date(ms)
    const y: string = d.getFullYear().toString()
    const m: string = (d.getMonth() + 1).toString().padStart(2, '0')
    const day: string = d.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  private formatDisplayDate(ms: number): string {
    const d = new Date(ms)
    return `${d.getFullYear()}年${(d.getMonth() + 1).toString().padStart(2, '0')}月${d.getDate().toString().padStart(2, '0')}日`
  }

  private pickDayValue(records: Array<BodyRecordModel>): number {
    if (records.length === 0) {
      return 0
    }
    const sorted = [...records].sort((a, b) => a.time - b.time)
    const weights = sorted.map(r => parseFloat(r.data))
    switch (this.filterMode) {
      case 'min':
        return Math.min(...weights)
      case 'max':
        return Math.max(...weights)
      case 'avg':
        return weights.reduce((a, b) => a + b, 0) / weights.length
      case 'first':
        return weights[0]
      case 'last':
        return weights[weights.length - 1]
    }
    return weights[weights.length - 1]
  }

  private collectWindow(outLabels: Array<string>, outValues: Array<number>): void {
    const records: Array<BodyRecordModel> = this.allWeights
    const end = new Date(this.windowEndDate)

    if (this.viewMode === 'year') {
      const start = new Date(end.getFullYear(), end.getMonth() - 11, 1)
      this.topRange = `${start.getFullYear()}年${start.getMonth() + 1}月 - ${end.getFullYear()}年${end.getMonth() + 1}月`
      for (let i = 11; i >= 0; i--) {
        const currentMonth = new Date(end.getFullYear(), end.getMonth() - i, 1)
        outLabels.push(`${currentMonth.getMonth() + 1}月`)
        const monthRecords = records.filter(r => {
          const rd = new Date(r.time)
          return rd.getFullYear() === currentMonth.getFullYear() && rd.getMonth() === currentMonth.getMonth()
        })
        if (monthRecords.length === 0) {
          outValues.push(0)
          continue
        }
        const dayMap = this.groupByDay(monthRecords)
        const dailyValues: Array<number> = []
        dayMap.forEach((dayRecords: Array<BodyRecordModel>) => {
          dailyValues.push(this.pickDayValue(dayRecords))
        })
        const avg = dailyValues.length > 0 ? dailyValues.reduce((a, b) => a + b, 0) / dailyValues.length : 0
        outValues.push(parseFloat(avg.toFixed(1)))
      }
    } else {
      const size = this.viewMode === 'week' ? 7 : 30
      const start = new Date(end)
      start.setDate(end.getDate() - (size - 1))
      this.topRange = `${start.getFullYear()}年${start.getMonth() + 1}月${start.getDate()}日 - ${end.getFullYear()}年${end.getMonth() + 1}月${end.getDate()}日`

      for (let i = 0; i < size; i++) {
        const current = new Date(start)
        current.setDate(start.getDate() + i)
        outLabels.push(this.viewMode === 'week'
          ? ['周日', '周一', '周二', '周三', '周四', '周五', '周六'][current.getDay()]
          : `${current.getMonth() + 1}/${current.getDate()}`)
        const dayRecords = records.filter(r => {
          const rd = new Date(r.time)
          return rd.getFullYear() === current.getFullYear() && rd.getMonth() === current.getMonth() && rd.getDate() === current.getDate()
        })
        const picked = this.pickDayValue(dayRecords)
        outValues.push(parseFloat(picked.toFixed(1)))
      }
    }

    if (outValues.length === 0) {
      this.highlightValue = '--'
      this.highlightLabel = ''
      return
    }
    let latestIndex = outValues.length - 1
    while (latestIndex >= 0 && outValues[latestIndex] === 0 && this.allWeights.length > 0) {
      latestIndex--
    }
    if (latestIndex < 0) {
      latestIndex = outValues.length - 1
    }
    const latestValue = outValues[latestIndex]
    this.highlightValue = this.allWeights.length === 0 && latestValue === 0 ? '--' : latestValue.toFixed(1)
    if (this.viewMode === 'year') {
      const highlightMonth = new Date(end.getFullYear(), end.getMonth() - (outValues.length - 1 - latestIndex), 1)
      this.highlightLabel = `${highlightMonth.getFullYear()}年${highlightMonth.getMonth() + 1}月`
    } else {
      const highlightDate = new Date(end)
      if (this.viewMode === 'week') {
        highlightDate.setDate(end.getDate() - (outValues.length - 1 - latestIndex))
      } else {
        highlightDate.setDate(end.getDate() - (outValues.length - 1 - latestIndex))
      }
      this.highlightLabel = `${highlightDate.getMonth() + 1}月${highlightDate.getDate()}日`
    }
  }

  private updateOverview() {
    console.info('[WeightTrendPage] updateOverview: allWeights.length=', this.allWeights.length)
    if (this.allWeights.length === 0) {
      console.info('[WeightTrendPage] updateOverview: no weights, setting defaults')
      this.statDays = 0
      this.statMax = '--'
      this.statMin = '--'
      this.statAvgDelta = '--'
      return
    }
    // 记录天数：有记录的不同日期数量
    const daySet = new Set<string>()
    for (const r of this.allWeights) {
      const d = new Date(r.time)
      const dayKey = `${d.getFullYear()}-${d.getMonth()+1}-${d.getDate()}`
      daySet.add(dayKey)
      console.info('[WeightTrendPage] updateOverview: weight record - time=', r.time, 'date=', dayKey, 'data=', r.data)
    }
    this.statDays = daySet.size
    console.info('[WeightTrendPage] updateOverview: statDays=', this.statDays, 'unique days=', Array.from(daySet))
    
    const vals = this.allWeights.map(r => {
      const val = parseFloat(r.data)
      if (isNaN(val)) {
        console.error('[WeightTrendPage] updateOverview: invalid weight data:', r.data)
        return 0
      }
      return val
    }).filter(v => v > 0)
    
    if (vals.length === 0) {
      console.error('[WeightTrendPage] updateOverview: no valid weight values')
      this.statDays = 0
      this.statMax = '--'
      this.statMin = '--'
      this.statAvgDelta = '--'
      return
    }
    
    const min = Math.min(...vals)
    const max = Math.max(...vals)
    this.statMin = `${min.toFixed(1)}公斤`
    this.statMax = `${max.toFixed(1)}公斤`
    console.info('[WeightTrendPage] updateOverview: statMin=', this.statMin, 'statMax=', this.statMax)
    
    // 平均每日变化：相邻日均差的平均值
    const entries = Array.from(this.groupByDay(this.allWeights).entries()).sort((a, b) => a[0].localeCompare(b[0]))
    const series: Array<number> = []
    for (let idx = 0; idx < entries.length; idx++) {
      const dayRecords: Array<BodyRecordModel> = entries[idx][1]
      const value = this.pickDayValue(dayRecords)
      if (value > 0) {
        series.push(value)
      }
    }
    console.info('[WeightTrendPage] updateOverview: series.length=', series.length, 'series=', series)
    if (series.length <= 1) { 
      this.statAvgDelta = series.length === 0 ? '--' : '0.0公斤'
      return 
    }
    let sum = 0
    for (let i=1;i<series.length;i++) sum += (series[i]-series[i-1])
    this.statAvgDelta = `${(sum/(series.length-1)).toFixed(1)}公斤`
    console.info('[WeightTrendPage] updateOverview: statAvgDelta=', this.statAvgDelta)
  }

  private formatWeightDisplay(value: number): string {
    if (value <= 0) {
      return '--'
    }
    return value.toFixed(1)
  }

  private getEarliestRecordDate(): Date | null {
    if (this.allWeights.length === 0) {
      return null
    }
    const earliest = Math.min(...this.allWeights.map(r => r.time))
    return new Date(earliest)
  }

  private shiftWindow(direction: number): void {
    const now = new Date()
    if (this.viewMode === 'year') {
      const candidate = new Date(this.windowEndDate.getFullYear(), this.windowEndDate.getMonth() + direction, 1)
      if (direction > 0 && candidate > now) {
        this.windowEndDate = new Date(now.getFullYear(), now.getMonth(), 1)
      } else {
        const earliest = this.getEarliestRecordDate()
        if (direction < 0 && earliest) {
          const clamp = new Date(earliest.getFullYear(), earliest.getMonth(), 1)
          this.windowEndDate = candidate < clamp ? clamp : candidate
        } else {
          this.windowEndDate = candidate
        }
      }
    } else {
      const delta = this.viewMode === 'week' ? 7 : 30
      const candidate = new Date(this.windowEndDate)
      candidate.setDate(candidate.getDate() + delta * direction)
      if (direction > 0 && candidate > now) {
        this.windowEndDate = now
      } else {
        const earliest = this.getEarliestRecordDate()
        if (direction < 0 && earliest && candidate < earliest) {
          this.windowEndDate = earliest
        } else {
          this.windowEndDate = candidate
        }
      }
    }
    this.updateChart()
  }

  private switchViewMode(mode: ViewMode): void {
    if (this.viewMode === mode) {
      console.info('[WeightTrendPage] switchViewMode: 已经是', mode, '模式，无需切换')
      return
    }
    console.info('[WeightTrendPage] switchViewMode: 从', this.viewMode, '切换到', mode)
    this.viewMode = mode
    this.windowEndDate = new Date()
    if (this.viewMode === 'year' && (this.filterMode === 'first' || this.filterMode === 'last')) {
      this.filterMode = 'min'
      this.saveFilter()
    }
    this.updateChart()
  }

  private openTargetModifyDialog(): void {
    const baseValue = this.targetWeight > 0
      ? this.targetWeight
      : (this.currentWeight > 0 ? this.currentWeight : (this.initialWeight > 0 ? this.initialWeight : 60))
    const normalized = Math.min(200, Math.max(30, parseFloat(baseValue.toFixed(1))))

    let dialog = new CustomDialogController({
      builder: BodyRecordDialog({
        title: '目标体重',
        unit: '公斤',
        content: normalized.toFixed(1),
        bodyType: AppDataManager.TYPE_WEIGHT,
        startNum: 30,
        endNum: 200,
        stepNum: 0.1,
        selectNum: normalized,
        cancel: () => {
          dialog.close()
        },
        confirm: async (value: number, _type: number) => {
          dialog.close()
          await this.onTargetModified(parseFloat(value.toFixed(1)))
        }
      }),
      autoCancel: true
    })
    dialog.open()
  }

  private openInitialWeightDialog(): void {
    const baseValue = this.initialWeight > 0
      ? this.initialWeight
      : (this.currentWeight > 0 ? this.currentWeight : (this.targetWeight > 0 ? this.targetWeight : 60))
    const normalized = Math.min(200, Math.max(30, parseFloat(baseValue.toFixed(1))))

    let dialog: CustomDialogController
    dialog = new CustomDialogController({
      builder: BodyRecordDialog({
        title: '设置初始体重',
        unit: '公斤',
        content: normalized.toFixed(1),
        bodyType: AppDataManager.TYPE_WEIGHT,
        startNum: 30,
        endNum: 200,
        stepNum: 0.1,
        selectNum: normalized,
        cancel: () => {
          dialog.close()
        },
          confirm: async (value: number, _type: number) => {
            dialog.close()
            const formatted = value.toFixed(1)
            if (this.earliestRecord) {
              const base = this.earliestRecord
              const updated: BodyRecordModel = {
                id: base.id,
                time: base.time,
                type: base.type,
                data: formatted,
                unit: base.unit
              }
              appDataManager.updateBodyRecordItem(updated)
            } else {
              appDataManager.insertBodyRecord(AppDataManager.TYPE_WEIGHT, formatted)
            }
            this.windowEndDate = new Date()
            // 延迟一下确保数据库操作完成后再刷新
            setTimeout(() => {
              this.refreshData()
            }, 200)
          }
      }),
      autoCancel: true
    })
    dialog.open()
  }

  private openCurrentWeightDialog(): void {
    const baseValue = this.currentWeight > 0
      ? this.currentWeight
      : (this.initialWeight > 0 ? this.initialWeight : (this.targetWeight > 0 ? this.targetWeight : 60))
    const normalized = Math.min(200, Math.max(30, parseFloat(baseValue.toFixed(1))))

    let dialog: CustomDialogController
    dialog = new CustomDialogController({
      builder: BodyRecordDialog({
        title: '设置当前体重',
        unit: '公斤',
        content: normalized.toFixed(1),
        bodyType: AppDataManager.TYPE_WEIGHT,
        startNum: 30,
        endNum: 200,
        stepNum: 0.1,
        selectNum: normalized,
        cancel: () => {
          dialog.close()
        },
          confirm: async (value: number, _type: number) => {
            dialog.close()
            const formatted = value.toFixed(1)
            if (this.latestRecord) {
              const base = this.latestRecord
              const updated: BodyRecordModel = {
                id: base.id,
                time: base.time,
                type: base.type,
                data: formatted,
                unit: base.unit
              }
              appDataManager.updateBodyRecordItem(updated)
            } else {
              appDataManager.insertBodyRecord(AppDataManager.TYPE_WEIGHT, formatted)
            }
            this.windowEndDate = new Date()
            // 延迟一下确保数据库操作完成后再刷新
            setTimeout(() => {
              this.refreshData()
            }, 200)
          }
      }),
      autoCancel: true
    })
    dialog.open()
  }

  private openRecordWeightDialog(): void {
    const baseValue = this.currentWeight > 0
      ? this.currentWeight
      : (this.initialWeight > 0 ? this.initialWeight : (this.targetWeight > 0 ? this.targetWeight : 60))
    const normalized = Math.min(200, Math.max(30, parseFloat(baseValue.toFixed(1))))

    let dialog = new CustomDialogController({
      builder: BodyRecordDialog({
        title: '记录体重',
        unit: '公斤',
        content: normalized.toFixed(1),
        bodyType: AppDataManager.TYPE_WEIGHT,
        startNum: 30,
        endNum: 200,
        stepNum: 0.1,
        selectNum: normalized,
        cancel: () => {
          dialog.close()
        },
        confirm: async (value: number, _type: number) => {
          dialog.close()
          appDataManager.insertBodyRecord(AppDataManager.TYPE_WEIGHT, value.toFixed(1))
          this.windowEndDate = new Date()
          // 延迟一下确保数据库操作完成后再刷新
          setTimeout(() => {
            this.refreshData()
          }, 200)
        }
      }),
      autoCancel: true
    })
    dialog.open()
  }

  private async onTargetModified(newValue: number) {
    await targetManager.updateTarget('weight_target', newValue)
    await preferencesUtil.putPreferenceValue('steps_ohos', 'weight_target_update_time', Date.now())
    this.targetWeight = newValue
    this.targetDateLabel = this.formatDisplayDate(Date.now())
    // 刷新所有数据以确保一致性
    this.refreshAll()
  }

  private openFilterDialog(): void {
    this.filterDialog?.close()
    this.filterDialog = new CustomDialogController({
      builder: (): void => { this.filterDialogBuilder() },
      autoCancel: true
    })
    this.filterDialog?.open()
  }

  private isFilterDisabled(mode: FilterMode): boolean {
    if (this.viewMode !== 'year') {
      return false
    }
    return mode === 'first' || mode === 'last'
  }

  @Builder
  private buildProgressSection() {
    Column() {
      Column() {
        Row() {
          Text('目标进度')
            .fontSize(16)
            .fontWeight(500)
            .fontColor('#333333')
          Blank().layoutWeight(1)
          Row() {
            Text('修改目标')
              .fontSize(14)
              .fontColor('#0cc291')
            Text('✏️')
              .fontSize(12)
              .margin({ left: 4 })
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#E8F5E8')
          .borderRadius(12)
          .onClick(() => {
            this.openTargetModifyDialog()
          })
        }
        .width('100%')

        Text(this.progressSummary)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 8 })

        Row() {
          Row()
            .backgroundColor('#0cc291')
            .height('100%')
            .borderRadius(4)
            .width(`${Math.max(0, Math.min(100, this.progressPercent)).toFixed(0)}%`)
        }
        .width('100%')
        .height(8)
        .backgroundColor('#F0F0F0')
        .borderRadius(4)
        .clip(true)
        .margin({ top: 12 })

        Text(`进度 ${Math.max(0, Math.min(100, this.progressPercent)).toFixed(0)}%`)
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.End)
          .margin({ top: 6 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)

      Column() {
        Row() {
          Text('体重概览')
            .fontSize(16)
            .fontWeight(500)
            .fontColor('#333333')
        }
        .width('100%')

        Row() {
          this.buildProgressMetric('初始', this.formatWeightDisplay(this.initialWeight), this.initialDateLabel, '#FFB950', 12, () => {
            this.openInitialWeightDialog()
          })
          this.buildProgressMetric('当前', this.formatWeightDisplay(this.currentWeight), this.currentDateLabel, '#0cc291', 12, () => {
            this.openCurrentWeightDialog()
          })
          this.buildProgressMetric('目标', this.formatWeightDisplay(this.targetWeight), this.targetDateLabel, '#5B8FF9', 0, () => {
            this.openTargetModifyDialog()
          })
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ top: 12 })
    }
    .width('92%')
    .margin({ top: 16 })
  }

  @Builder
  private buildProgressMetric(label: string, value: string, dateLabel: string, color: string, marginRight: number, onTap?: () => void) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#FFFFFF')
        .padding({ left: 12, right: 12, top: 4, bottom: 4 })
        .backgroundColor(color)
        .borderRadius(12)
        .alignSelf(ItemAlign.Start)

      Text(value)
        .fontSize(24)
        .fontWeight(600)
        .fontColor('#333333')
        .margin({ top: 8 })

      if (value !== '--') {
        Text('公斤')
          .fontSize(12)
          .fontColor('#666666')
      } else {
        Text(' ')
          .fontSize(12)
          .fontColor('#666666')
      }

      Text(dateLabel)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 8 })
    }
    .padding(12)
    .backgroundColor('#F8F8F8')
    .borderRadius(12)
    .layoutWeight(1)
    .margin({ right: marginRight })
    .onClick(() => {
      if (onTap) {
        onTap()
      }
    })
  }

  @Builder
  private buildTrendSection() {
    Column() {
      Row() {
        Text('趋势查看')
          .fontSize(16)
          .fontWeight(500)
          .fontColor('#333333')
        Blank().layoutWeight(1)
        Row() {
          Text(this.getFilterTitle(this.filterMode))
            .fontSize(14)
            .fontColor('#333333')
          Text('▼')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ left: 4 })
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('#F4F4F4')
        .borderRadius(16)
        .onClick(() => {
          this.openFilterDialog()
        })
      }
      .width('100%')

      Row() {
        this.buildViewModeChip('周', 'week', 12, this.viewMode === 'week')
        this.buildViewModeChip('月', 'month', 12, this.viewMode === 'month')
        this.buildViewModeChip('年', 'year', 0, this.viewMode === 'year')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 12 })

      Row() {
        Image($r('app.media.back_btn_dark'))
          .width(24)
          .height(24)
          .onClick(() => this.shiftWindow(-1))

        Column() {
          Text(this.topRange !== '' ? this.topRange : '暂无时间范围')
            .fontSize(14)
            .fontColor('#333333')
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)

        Image($r('app.media.right_btn'))
          .width(24)
          .height(24)
          .onClick(() => this.shiftWindow(1))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 12 })

      Column() {
        Text(this.highlightValue !== '--' ? this.highlightValue : '--')
          .fontSize(36)
          .fontWeight(600)
          .fontColor('#333333')
        if (this.highlightValue !== '--') {
          Text('公斤')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 2 })
        }
        Text(this.highlightValue !== '--' ? this.highlightLabel : '暂无数据')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: this.highlightValue !== '--' ? 2 : 4 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 12, bottom: 12 })

      McBarChart({ options: this.chartOptions })
        .height(220)
        .width('100%')
    }
    .width('92%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ top: 16 })
  }

  @Builder
  private buildViewModeChip(label: string, mode: ViewMode, marginRight: number, active: boolean) {
    Text(label)
      .fontSize(14)
      .fontColor(active ? '#FFFFFF' : '#333333')
      .fontWeight(active ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: 16, right: 16, top: 6, bottom: 6 })
      .backgroundColor(active ? '#0cc291' : '#F0F0F0')
      .borderRadius(16)
      .margin({ right: marginRight })
      .opacity(active ? 1 : 0.8)
      .onClick(() => {
        console.info('[WeightTrendPage] 点击视图模式:', mode)
        this.switchViewMode(mode)
      })
  }

  @Builder
  private buildOverviewSection() {
    Column() {
      Row() {
        this.buildOverviewCard('记录天数', this.statDays > 0 ? `${this.statDays}` : '--', this.statDays > 0 ? '天' : '', 12)
        this.buildOverviewCard('平均每日变化', this.statAvgDelta, '', 0)
      }
      .width('92%')
      .margin({ top: 16 })

      Row() {
        this.buildOverviewCard('最低体重', this.statMin, '', 12)
        this.buildOverviewCard('最高体重', this.statMax, '', 0)
      }
      .width('92%')
      .margin({ top: 12 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildOverviewCard(title: string, value: string, suffix: string, marginRight: number) {
    Column() {
      Text(title)
        .fontSize(12)
        .fontColor('#666666')
      Text(suffix !== '' ? `${value}${suffix}` : value)
        .fontSize(20)
        .fontWeight(600)
        .fontColor('#333333')
        .margin({ top: 8 })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .layoutWeight(1)
    .margin({ right: marginRight })
  }

  build() {
    Column() {
      CommonTitleView({ data1: { str1: '体重趋势' }, cancel: () => { router.back() } })

      Scroll() {
        Column() {
          this.buildProgressSection()
          this.buildTrendSection()
          this.buildOverviewSection()

          Button('记录体重')
            .onClick(() => {
              this.openRecordWeightDialog()
            })
            .width('92%')
            .height(48)
            .margin({ top: 20, bottom: 36 })
            .fontColor('#FFFFFF')
            .backgroundColor('#0cc291')
            .borderRadius(24)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  @Builder filterDialogBuilder() {
    Column(){
      Text('筛选方式').fontSize(18).fontWeight(600).margin({ bottom: 12 })
      this.filterOption('min','最低体重', this.isFilterDisabled('min'))
      this.filterOption('max','最高体重', this.isFilterDisabled('max'))
      this.filterOption('avg','平均体重', this.isFilterDisabled('avg'))
      this.filterOption('first','最早时间', this.isFilterDisabled('first'))
      this.filterOption('last','最晚时间', this.isFilterDisabled('last'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder filterOption(mode: FilterMode, title: string, disabled: boolean) {
    Row(){
      Text(title)
        .fontSize(16)
        .fontColor(disabled ? '#CCCCCC' : '#333333')
        .layoutWeight(1)
      Text(this.filterMode === mode ? '✓' : '')
        .fontSize(16)
        .fontColor(disabled ? '#CCCCCC' : '#0cc291')
    }
    .height(44)
    .onClick(()=>{
      if (disabled) {
        return
      }
      this.filterMode = mode
      this.saveFilter()
      this.updateChart()
      this.filterDialog?.close()
    })
  }

  private getFilterTitle(mode: FilterMode): string {
    switch (mode) {
      case 'min': return '最低体重'
      case 'max': return '最高体重'
      case 'avg': return '平均体重'
      case 'first': return '最早时间'
      case 'last': return '最晚时间'
    }
    return '最低体重'
  }
}
