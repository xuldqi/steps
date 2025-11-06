import { CommonTitleView } from '../view/CommonTitleView'
import { router, window } from '@kit.ArkUI'
import { McBarChart, Options } from '@mcui/mccharts'
import appDataManager, { DataCallback } from '../tools/AppDataManager'
import { PerStepModel, SportModel } from '../appdata/Model'
import StepData from '../appdata/StepData'
import { DateUtils } from '../tools/DateUtils'
import { Log } from '../tools/Logger'
import { TargetProgressView } from '../view/TargetModifyDialog'
import preferencesUtil from '../tools/DataPreUtils'
import targetManager, { TargetValue } from '../tools/TargetManager'
import { Utils } from '../tools/Utils'

@Entry
@Component
struct ChartPage {
  @State curOffset: number = 0
  @State top_week: string = ''
  @State reward_str: string = ''
  @State allCalories: number = 0
  @State argCalories: number = 0
  @State targetCalories: number = 300
  @State currentCalories: number = 0
  @State viewMode: 'week' | 'month' | 'year' = 'week'
  @State windowEndDate: Date = new Date()
  private dates: Array<string> = new Array<string>()
  
  @State seriesRadiusOption: Options = new Options({
    title: { show: true, text: '千卡', right: 20, top: 30 },
    xAxis: { data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']},
    legend: { show: false },
    series: [{ name: '', barStyle: { 
          width: 10,
          color:'#FF8C47',
          borderRadius: [4, 4] },
        data: [0, 0, 0, 0, 0, 0, 0] }]
  })

  // 热量数据 - 从运动记录中获取
  @State sportRecords: Array<SportModel> = new Array<SportModel>()
  // 按天统计的步数热量（仅用于无运动记录热量时的兜底展示）
  private stepCaloriesByDate: Map<string, number> = new Map<string, number>()
  private stepListLoaded: boolean = false
  private sportListLoaded: boolean = false

  private sportCallback: DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      console.info('[ChartPage] 收到运动记录数据:', result?.length || 0, '条')
      if (result && result.length > 0) {
        console.info('[ChartPage] 第一条记录 - start_time:', result[0].start_time, 'cal:', result[0].cal, 'steps:', result[0].steps)
      }
      // 根据当前视图模式筛选时间范围内的记录
      const filtered = this.filterRecordsByTimeRange(result || [])
      this.sportRecords = filtered
      console.info('[ChartPage] 筛选后的记录数量:', filtered.length)
      this.sportListLoaded = true
      this.calculateCalorieStats()
    }
  }

  // 一周内每天步数列表回调（用于计算当天步数估算的热量）
  private perStepCallback: DataCallback<PerStepModel> = {
    onDataResult: (type: number, result: Array<PerStepModel>, isReturnFirstData: boolean, firstDay?: string) => {
      this.stepCaloriesByDate.clear()
      for (const item of result || []) {
        // 归一化日期格式为 yyyy-MM-dd
        const date = (item.date || '').replace(/\//g, '-')
        const steps = Math.max(0, item.steps)
        const calories = Number.parseFloat(Utils.getKalByStep(steps))
        this.stepCaloriesByDate.set(date, Number.isFinite(calories) ? Math.round(calories) : 0)
      }
      console.info('[ChartPage] perDay steps calories:', Array.from(this.stepCaloriesByDate.entries()))
      this.stepListLoaded = true
      this.calculateCalorieStats()
    }
  }

  private filterRecordsByTimeRange(records: Array<SportModel>): Array<SportModel> {
    if (this.dates.length === 0) {
      return records
    }
    const firstDate = this.parseDateFromYMD(this.dates[0])
    const lastDate = this.parseDateFromYMD(this.dates[this.dates.length - 1])
    const startMs = this.getStartOfDay(firstDate)
    const endMs = this.getEndOfDay(lastDate)
    
    return records.filter(record => {
      return record.start_time >= startMs && record.start_time <= endMs
    })
  }

  private getCaloriesForRecord(record: SportModel): number {
    let calories = Number.parseFloat(record.cal ?? '0')
    if (Number.isNaN(calories) || calories <= 0) {
      calories = Math.round(parseFloat(Utils.getDistanceByStep(record.steps)) * 50)
    }
    return Number.isNaN(calories) ? 0 : calories
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

  private calculateCalorieStats() {
    // 仅在数据窗口准备好时计算
    if (this.dates.length === 0) {
      return
    }
    console.info('[ChartPage] calculateCalorieStats: 运动记录数量=', this.sportRecords.length)
    
    // 按日期分组计算每日热量
    const dailyCalories: Map<string, number> = new Map()
    
    for (const record of this.sportRecords) {
      const recordDate = new Date(record.start_time)
      const dateKey = this.formatYMD(recordDate)
      const calories = this.getCaloriesForRecord(record)
      
      if (calories > 0) {
        const current = dailyCalories.get(dateKey) || 0
        dailyCalories.set(dateKey, current + calories)
      }
    }
    
    // 用每日步数估算热量兜底：若某天无运动记录热量，则使用步数热量
    for (const d of this.dates) {
      const existed = dailyCalories.get(d) || 0
      if (existed <= 0) {
        const stepCal = this.stepCaloriesByDate.get(d) || 0
        if (stepCal > 0) {
          dailyCalories.set(d, stepCal)
        }
      }
    }

    // 如果今天仍为0，但首页有实时步数，则再兜底一次
    // 使用与 this.dates 相同的连字符日期格式
    const today = this.formatYMD(new Date())
    const todayCal = dailyCalories.get(today) || 0
    if (todayCal <= 0) {
      const liveSteps = StepData.getCurrentSteps?.() ?? 0
      if (liveSteps > 0) {
        const liveCal = Math.round(Number.parseFloat(Utils.getKalByStep(liveSteps)))
        if (liveCal > 0) {
          dailyCalories.set(today, liveCal)
        }
      }
    }
    
    console.info('[ChartPage] calculateCalorieStats: 每日热量数据=', Array.from(dailyCalories.entries()))
    
    // 计算总热量和平均热量
    this.allCalories = 0
    let rewardDays = 0
    
    dailyCalories.forEach((calories) => {
      this.allCalories = this.allCalories + calories
      if (calories >= this.targetCalories) {
        rewardDays = rewardDays + 1
      }
    })
    
    const divisor = dailyCalories.size > 0 ? dailyCalories.size : 1
    this.argCalories = this.allCalories / divisor

    // 计算今日热量（使用与 this.dates 一致的格式 yyyy-MM-dd）
    const todayDate = this.formatYMD(new Date())
    this.currentCalories = dailyCalories.get(todayDate) || 0
    console.info('[ChartPage] calculateCalorieStats: 今日日期=', todayDate, '今日热量=', this.currentCalories)

    if (this.viewMode === 'year') {
      this.reward_str = ''
    } else {
      if (rewardDays > 0) {
        this.reward_str = (this.viewMode === 'week' ? '本周' : '近30天') + '热量达标天数' + rewardDays + '天'
      } else {
        this.reward_str = (this.viewMode === 'week' ? '最近一周' : '近30天') + '没有一天热量达标哦！'
      }
    }
    
    let mm_datas = new Array<number>()
    let mm_dates = new Array<string>()
    
    // 遍历日期范围，查找对应的热量数据
    for (let i = 0; i < this.dates.length; i++) {
      const calories = dailyCalories.get(this.dates[i]) || 0
      
        if (this.viewMode === 'week') {
        // 周视图：固定显示七天，包含0值，避免单点不渲染
          const d = this.parseDateFromYMD(this.dates[i])
          const jsDay = d.getDay() // 周日0、周一1
          const weekDays = ['日', '一', '二', '三', '四', '五', '六']
          mm_dates.push(weekDays[jsDay])
        mm_datas.push(calories)
        } else if (this.viewMode === 'month') {
        // 月视图：只显示周一
          const d = this.parseDateFromYMD(this.dates[i])
        const jsDay = d.getDay()
        if (jsDay === 1) {
            mm_dates.push(this.formatMDLabel(this.dates[i]))
          mm_datas.push(calories)
          }
        } else {
          // 年视图：显示月份数字
          const d = this.parseDateFromYMD(this.dates[i])
          const month = (d.getMonth() + 1).toString()
          mm_dates.push(month)
        mm_datas.push(calories)
      }
    }
    
    console.info('[ChartPage] calculateCalorieStats: 图表数据 - 标签=', mm_dates, '数值=', mm_datas)
    
    this.seriesRadiusOption.setVal({
      legend: { show: false },
      xAxis: { data: mm_dates },
      series: [{ name: '', barStyle: { 
            width: 10,
            color:'#FF8C47',
            borderRadius: [4, 4] }, data: mm_datas }]
    })
  }

  private parseDateFromYMD(ymd: string): Date {
    const parts = ymd.split('-')
    return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
  }

  private formatMDLabel(ymd: string): string {
    const parts = ymd.split('-')
    const month = parseInt(parts[1])
    const day = parseInt(parts[2])
    return `${month}/${day}`
  }

  onPageShow(): void {
    Log.i('ChartPage onPageShow called')
    this.loadTargetCalories()
    targetManager.addListener(this.onTargetsChanged)
    this.windowEndDate = new Date()
    // 刷新数据
    this.refreshData()
  }

  private refreshData() {
    this.loadByViewMode()
  }

  aboutToDisappear(): void {
    targetManager.removeListener(this.onTargetsChanged)
  }

  private onTargetsChanged = (targets: TargetValue) => {
    const newTarget = targets.calorie_target
    if (this.targetCalories !== newTarget) {
      this.targetCalories = newTarget
      this.calculateCalorieStats()
    }
  }

  private loadByViewMode() {
    if (this.viewMode === 'week') {
      this.seriesRadiusOption.setVal({ title: { text: '千卡' } })
      this.loadWeekWindow()
    } else if (this.viewMode === 'month') {
      this.seriesRadiusOption.setVal({ title: { text: '千卡' } })
      this.loadDailyWindow(30)
    } else {
      this.seriesRadiusOption.setVal({ title: { text: '千卡' } })
      this.showYearRecord()
      // 顶部区间显示
      const end = new Date(this.windowEndDate)
      const start = new Date(end.getFullYear(), end.getMonth() - 11, 1)
      this.top_week = this.formatYMCH(start) + ' - ' + this.formatYMCH(end)
    }
  }

  private async loadTargetCalories() {
    await targetManager.loadTargets()
    this.targetCalories = targetManager.getTarget('calorie_target')
  }

  private loadWeekWindow() {
    // 将 windowEndDate 对齐到其所在自然周（周一为一周开始）
    const ref = new Date(this.windowEndDate)
    const jsDay = ref.getDay() // 0-周日,1-周一,...
    const offsetToMonday = (jsDay + 6) % 7 // 周一=0
    const start = new Date(ref)
    start.setDate(ref.getDate() - offsetToMonday)
    const end = new Date(start)
    end.setDate(start.getDate() + 6)

    this.dates.length = 0
    for (let i = 0; i < 7; i++) {
      const d = new Date(start)
      d.setDate(start.getDate() + i)
      const s = this.formatYMD(d)
      this.dates.push(s)
    }

    this.top_week = this.formatDateCH(start) + ' - ' + this.formatDateCH(end)

    // 从运动记录中加载数据
    const startMs = this.getStartOfDay(start)
    const endMs = this.getEndOfDay(end)
    console.info('[ChartPage] loadWeekWindow: 查询时间范围', new Date(startMs), '到', new Date(endMs))
    this.sportListLoaded = false
    this.stepListLoaded = false
    appDataManager.findSportByType(0, this.sportCallback, false) // 0表示查询所有类型
    // 同时加载这7天的步数并换算热量
    appDataManager.getStepPerDayWeekList3(this.dates, this.perStepCallback, true)
  }

  private loadDailyWindow(sizeDays: number) {
    const end = new Date(this.windowEndDate)
    const start = new Date(end)
    start.setDate(end.getDate() - sizeDays + 1)

    this.dates.length = 0
    for (let i = 0; i < sizeDays; i++) {
      const d = new Date(start)
      d.setDate(start.getDate() + i)
      const s = this.formatYMD(d)
      this.dates.push(s)
    }

    this.top_week = this.formatDateCH(start) + ' - ' + this.formatDateCH(end)

    // 从运动记录中加载数据
    const startMs = this.getStartOfDay(start)
    const endMs = this.getEndOfDay(end)
    console.info('[ChartPage] loadDailyWindow: 查询时间范围', new Date(startMs), '到', new Date(endMs))
    appDataManager.findSportByType(0, this.sportCallback, false) // 0表示查询所有类型
  }

  private showYearRecord() {
    const end = new Date(this.windowEndDate)
    const start = new Date(end.getFullYear(), end.getMonth() - 11, 1)

    this.dates.length = 0
    for (let i = 0; i < 12; i++) {
      const d = new Date(start.getFullYear(), start.getMonth() + i, 1)
      const s = this.formatYMD(d)
      this.dates.push(s)
    }

    // 从运动记录中加载全年数据
    const startMs = this.getStartOfDay(start)
    const endMs = this.getEndOfDay(end)
    console.info('[ChartPage] showYearRecord: 查询时间范围', new Date(startMs), '到', new Date(endMs))
    appDataManager.findSportByType(0, this.sportCallback, false) // 0表示查询所有类型
  }

  private formatYMD(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  private formatDateCH(date: Date): string {
    const year = date.getFullYear()
    const month = date.getMonth() + 1
    const day = date.getDate()
    return `${year}年${month}月${day}日`
  }

  private formatYMCH(date: Date): string {
    const year = date.getFullYear()
    const month = date.getMonth() + 1
    return `${year}年${month}月`
  }

  async onTargetModified(newValue: number) {
    await targetManager.updateTarget('calorie_target', newValue)
    this.targetCalories = newValue
    this.calculateCalorieStats()
  }

  showWeekCalorieRecord(i: number) {
    this.top_week = DateUtils.getYMDCH(6 + 7 * i) + ' - ' + DateUtils.getYMDCH(7 * i)
    this.dates.length = 0
    this.dates.push(DateUtils.getYMD_(6 + 7 * i))
    this.dates.push(DateUtils.getYMD_(5 + 7 * i))
    this.dates.push(DateUtils.getYMD_(4 + 7 * i))
    this.dates.push(DateUtils.getYMD_(3 + 7 * i))
    this.dates.push(DateUtils.getYMD_(2 + 7 * i))
    this.dates.push(DateUtils.getYMD_(1 + 7 * i))
    this.dates.push(DateUtils.getYMD_(7 * i))
    
    // 从运动记录中加载数据
    appDataManager.findSportByType(0, this.sportCallback, false)
  }

  build() {
    Column() {
      CommonTitleView({data1:{str1:'热量'},cancel:()=>{
          router.back()
      }})
      Scroll(){
        Column(){
          // 控制区域和图表区域 - 合并为一个白色卡片
          Column(){
            // 维度切换（周 / 月 / 年）
            Row(){
              Button('周')
                .backgroundColor(this.viewMode === 'week' ? '#0cc291' : '#EEEEEE')
                .fontColor(this.viewMode === 'week' ? '#FFFFFF' : '#333333')
                .height(32).padding({ left:12, right:12 }).borderRadius(16)
                .onClick(()=>{ this.viewMode='week'; this.windowEndDate = new Date(); this.loadByViewMode() })
              Button('月')
                .backgroundColor(this.viewMode === 'month' ? '#0cc291' : '#EEEEEE')
                .fontColor(this.viewMode === 'month' ? '#FFFFFF' : '#333333')
                .height(32).padding({ left:12, right:12 }).borderRadius(16).margin({ left:8 })
                .onClick(()=>{ this.viewMode='month'; this.windowEndDate = new Date(); this.loadByViewMode() })
              Button('年')
                .backgroundColor(this.viewMode === 'year' ? '#0cc291' : '#EEEEEE')
                .fontColor(this.viewMode === 'year' ? '#FFFFFF' : '#333333')
                .height(32).padding({ left:12, right:12 }).borderRadius(16).margin({ left:8 })
                .onClick(()=>{ this.viewMode='year'; this.windowEndDate = new Date(); this.loadByViewMode() })
            }.margin({ top:16, bottom:8 }).width('100%').justifyContent(FlexAlign.Center)

            // 日期范围选择器
            Row(){
              Image($r('app.media.back_btn_dark')).width(20).height(20).margin(5).onClick(() => {
                if (this.viewMode === 'week') {
                  this.windowEndDate.setDate(this.windowEndDate.getDate() - 7)
                  this.loadByViewMode()
                } else if (this.viewMode === 'month') {
                  this.windowEndDate.setDate(this.windowEndDate.getDate() - 30)
                  this.loadByViewMode()
                } else {
                  // 年视图：整体往前一个月
                  this.windowEndDate = new Date(this.windowEndDate.getFullYear(), this.windowEndDate.getMonth() - 1, 1)
                  this.loadByViewMode()
                }
              })
              Text(this.top_week).fontSize(14)
              Image($r('app.media.right_btn')).width(20).height(20).margin(5).onClick(() => {
                if (this.viewMode === 'week') {
                  this.windowEndDate.setDate(this.windowEndDate.getDate() + 7)
                  // 不能超出今天
                  const today = new Date()
                  if (this.windowEndDate > today) this.windowEndDate = today
                  this.loadByViewMode()
                } else if (this.viewMode === 'month') {
                  this.windowEndDate.setDate(this.windowEndDate.getDate() + 30)
                  const today = new Date()
                  if (this.windowEndDate > today) this.windowEndDate = today
                  this.loadByViewMode()
                } else {
                  this.windowEndDate = new Date(this.windowEndDate.getFullYear(), this.windowEndDate.getMonth() + 1, 1)
                  const now = new Date()
                  if (this.windowEndDate > now) this.windowEndDate = new Date(now.getFullYear(), now.getMonth(), 1)
                  this.loadByViewMode()
                }
              })
            }.margin({ top:4, bottom:16 }).width('100%').justifyContent(FlexAlign.Center)
            
            // 图表区域
            McBarChart({
              options: this.seriesRadiusOption
            })
            .height(200)
            .width('100%')
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding(16)
          .margin({ top: 8, bottom: 8 })
          
          // 目标进度 - 白色卡片容器
          Column(){
            TargetProgressView({
              targetName: '千卡',
              currentValue: this.currentCalories,
              targetValue: this.targetCalories,
              unit: '千卡'
            })
          }
          .width('92%')
          .margin({ top: 12 })
          .padding(16)
          .borderRadius(15)
          .backgroundColor('#FFFFFF')

          // 汇总指标 - 同一张白色卡片
          Column(){
            Row(){
              Column(){
                Text('总消耗').fontSize(12).fontColor('#666666')
                Text(this.allCalories.toString()).fontWeight(600).fontSize(30).margin({ top: 6 })
                Text('千卡').fontSize(12).fontColor('#666666')
              }.layoutWeight(1)
              Column(){
                Text('平均每日消耗').fontSize(12).fontColor('#666666')
                Text(this.argCalories.toFixed(0)).fontWeight(600).fontSize(30).margin({ top: 6 })
                Text('千卡').fontSize(12).fontColor('#666666')
              }.layoutWeight(1)
            }
          }
          .width('92%')
          .margin({ top: 10 })
          .padding(16)
          .borderRadius(15)
          .backgroundColor('#FFFFFF')
        }.width('100%').height('91%')
      }
    }
    .backgroundColor('#F5F5F5')
  }
}
