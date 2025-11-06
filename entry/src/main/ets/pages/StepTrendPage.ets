import { CommonTitleView } from '../view/CommonTitleView'
import { router, window } from '@kit.ArkUI'
import { McBarChart, Options } from '@mcui/mccharts'
import appDataManager, { DataCallback, ModelCallback } from '../tools/AppDataManager'
import { PerStepModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'
import { Log } from '../tools/Logger'
import { TargetProgressView } from '../view/TargetModifyDialog'
import preferencesUtil from '../tools/DataPreUtils'
import targetManager, { TargetValue } from '../tools/TargetManager'
import StepData from '../appdata/StepData'

@Entry
@Component
struct StepTrendPage {
  @State curOffset: number = 0
  @State top_week: string = ''
  @State reward_str: string = ''
  @State allSteps: number = 0
  @State argSteps: number = 0
  @State targetSteps: number = 5000
  @State currentSteps: number = 0
  @State viewMode: 'week' | 'month' | 'year' = 'week'
  @State windowEndDate: Date = new Date()
  private dates: Array<string> = new Array<string>()
  
  @State seriesRadiusOption: Options = new Options({
    title: { show: true, text: '最近七天的步数统计', right: 20, top: 30 },
    xAxis: { data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']},
    legend: { show: false },
    series: [{ name: '', barStyle: { 
          width: 10,
          color:'#0cc291',
          borderRadius: [4, 4] },
        data: [0, 0, 0, 0, 0, 0, 0] }]
  })

  // 步数数据
  @State stepChartData: Array<PerStepModel> = new Array<PerStepModel>()

  private stepCallback: DataCallback<PerStepModel> = {
    onDataResult: (type: number, result: PerStepModel[], isReturnFirstData: boolean): void => {
      this.stepChartData = result
      this.calculateStepStats()
    }
  }

  // 月/年统计异步收集
  private pendingMonthCount: number = 0
  private monthTotals: Array<number> = []
  private monthLabels: Array<string> = []
  private monthCallback: ModelCallback<number> = {
    onResult: (sum: number, isEnd?: boolean, date?: string): void => {
      this.monthTotals.push(sum)
      this.monthLabels.push(date || '')
      this.pendingMonthCount--
      if (this.pendingMonthCount === 0) {
        // 标签形如 2025-10，转为 10月
        const x = this.monthLabels.map(m => m.split('-')[1] + '月')
        const y = this.monthTotals
        this.seriesRadiusOption.setVal({
          legend: { show: false },
          xAxis: { data: x },
          series: [{ name: '', barStyle: { width: 10, color: '#0cc291', borderRadius: [4, 4] }, data: y }]
        })
      }
    }
  }

  private calculateStepStats() {
    const stepsByDate: Map<string, number> = new Map()
    for (const item of this.stepChartData) {
      stepsByDate.set(item.date, Math.max(0, item.steps))
    }

    this.allSteps = 0
    let rewardDays = 0
    const totalDays = this.dates.length > 0 ? this.dates.length : Math.max(1, this.stepChartData.length)

    for (const date of this.dates) {
      const steps = stepsByDate.get(date) ?? 0
      this.allSteps = this.allSteps + steps
      if (steps >= this.targetSteps) {
        rewardDays = rewardDays + 1
      }
    }
    this.argSteps = this.allSteps / totalDays

    // 目标进度显示今日步数，从StepData实时获取
    this.currentSteps = StepData.getCurrentSteps()

    if (this.viewMode === 'year') {
      this.reward_str = ''
    } else {
      if (rewardDays > 0) {
        this.reward_str = (this.viewMode === 'week' ? '本周' : '近30天') + '步数达标天数' + rewardDays + '天'
      } else {
        this.reward_str = (this.viewMode === 'week' ? '最近一周' : '近30天') + '没有一天步数达标哦！'
      }
    }
    
    let mm_datas = new Array<number>()
    let mm_dates = new Array<string>()
    
    // 构造图表数据：每一天都展示，未同步的数据置零
    for (let i = 0; i < this.dates.length; i++) {
      const steps = stepsByDate.get(this.dates[i]) ?? 0
      if (this.viewMode === 'week') {
        const d = this.parseDateFromYMD(this.dates[i])
        const jsDay = d.getDay()
        const weekDays = ['日', '一', '二', '三', '四', '五', '六']
        mm_dates.push(weekDays[jsDay])
      } else if (this.viewMode === 'month') {
        mm_dates.push(this.formatMDLabel(this.dates[i]))
      } else {
        const d = this.parseDateFromYMD(this.dates[i])
        const month = (d.getMonth() + 1).toString()
        mm_dates.push(month)
      }
      mm_datas.push(steps)
    }
    this.seriesRadiusOption.setVal({
      legend: { show: false },
      xAxis: { data: mm_dates },
      series: [{ name: '', barStyle: { 
            width: 10,
            color:'#0cc291',
            borderRadius: [4, 4] }, data: mm_datas }]
    })
  }

  onPageShow(): void {
    Log.i('StepTrendPage onPageShow called')
    this.loadTargetSteps()
    // 订阅目标变更，保持目标与页面同步
    targetManager.addListener(this.onTargetsChanged)
    this.windowEndDate = new Date()
    this.loadByViewMode()
  }

  aboutToDisappear(): void {
    // 取消订阅，避免内存泄漏
    targetManager.removeListener(this.onTargetsChanged)
  }

  private onTargetsChanged = (targets: TargetValue) => {
    const newTarget = targets.step_target
    if (this.targetSteps !== newTarget) {
      this.targetSteps = newTarget
      this.calculateStepStats()
    }
  }

  private async loadTargetSteps() {
    await targetManager.loadTargets()
    this.targetSteps = targetManager.getTarget('step_target')
  }

  async onTargetModified(newValue: number) {
    await targetManager.updateTarget('step_target', newValue)
    this.targetSteps = newValue
    this.calculateStepStats()
  }

  private formatYMD(d: Date): string {
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    const day = d.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  private formatDateCH(d: Date): string {
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    const day = d.getDate().toString().padStart(2, '0')
    return `${y}年${m}月${day}日`
  }

  private formatYMCH(d: Date): string {
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    return `${y}年${m}月`
  }

  private parseDateFromYMD(s: string): Date {
    const parts = s.split('-')
    if (parts.length !== 3) return new Date(s)
    const y = parseInt(parts[0])
    const m = parseInt(parts[1]) - 1
    const d = parseInt(parts[2])
    return new Date(y, m, d)
  }

  private formatMDLabel(s: string): string {
    const parts = s.split('-')
    if (parts.length !== 3) return s
    return `${parseInt(parts[1])}/${parseInt(parts[2])}`
  }

  private loadDailyWindow(sizeDays: number) {
    // 生成从 (end - sizeDays + 1) 到 end 的日期数组
    this.dates.length = 0
    const end = new Date(this.windowEndDate)
    const start = new Date(end)
    start.setDate(end.getDate() - (sizeDays - 1))

    const labels: Array<string> = []
    for (let i = 0; i < sizeDays; i++) {
      const d = new Date(start)
      d.setDate(start.getDate() + i)
      const s = this.formatYMD(d)
      this.dates.push(s)
      labels.push(DateUtils.getWeek(s))
    }

    // 顶部区间文案
    this.top_week = this.formatDateCH(start) + ' - ' + this.formatDateCH(end)

    // 拉取每日数据（逐日回调聚合）
    const results: Array<PerStepModel> = []
    let pending = sizeDays
    for (const s of this.dates) {
      appDataManager.getStepPerDay(s, {
        onResult: (data: PerStepModel) => {
          if (data) {
            results.push(data)
          } else {
            results.push({
              id: 0,
              state: 0,
              date: s,
              steps: 0,
              backup: 0,
              time: 0
            })
          }
          pending--
          if (pending === 0) {
            // 保证与 this.dates 顺序一致
            results.sort((a, b) => a.date.localeCompare(b.date))
            this.stepChartData = results
            this.calculateStepStats()
          }
        }
      })
    }
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
    const labels: Array<string> = []
    for (let i = 0; i < 7; i++) {
      const d = new Date(start)
      d.setDate(start.getDate() + i)
      const s = this.formatYMD(d)
      this.dates.push(s)
      labels.push(DateUtils.getWeek(s))
    }

    this.top_week = this.formatDateCH(start) + ' - ' + this.formatDateCH(end)

    // 逐日查询，仅保留有数据的日期
    const results: Array<PerStepModel> = []
    let pending = this.dates.length
    for (const s of this.dates) {
      appDataManager.getStepPerDay(s, {
        onResult: (data: PerStepModel) => {
          if (data) {
            results.push(data)
          } else {
            results.push({
              id: 0,
              state: 0,
              date: s,
              steps: 0,
              backup: 0,
              time: 0
            })
          }
          pending--
          if (pending === 0) {
            results.sort((a, b) => a.date.localeCompare(b.date))
            this.stepChartData = results
            this.calculateStepStats()
          }
        }
      })
    }
  }

  private loadByViewMode() {
    if (this.viewMode === 'week') {
      this.seriesRadiusOption.setVal({ title: { text: '步数' } })
      this.loadWeekWindow()
    } else if (this.viewMode === 'month') {
      this.seriesRadiusOption.setVal({ title: { text: '步数' } })
      this.loadDailyWindow(30)
    } else {
      this.seriesRadiusOption.setVal({ title: { text: '步数' } })
      this.showYearRecord()
      // 顶部区间显示
      const end = new Date(this.windowEndDate)
      const start = new Date(end.getFullYear(), end.getMonth() - 11, 1)
      this.top_week = this.formatYMCH(start) + ' - ' + this.formatYMCH(end)
    }
  }

  private showMonthRecord(): void {
    // 最近6个月总步数（暂未在新交互中使用，保留）
    this.monthTotals = []
    this.monthLabels = []
    const months: Array<string> = [] as Array<string> // 形如 2025-10
    const base = new Date()
    for (let i = 5; i >= 0; i--) {
      const d = new Date(base.getFullYear(), base.getMonth() - i, 1)
      const y = d.getFullYear()
      const m = (d.getMonth() + 1).toString().padStart(2, '0')
      months.push(`${y}-${m}`)
    }
    this.pendingMonthCount = months.length
    for (const m of months) {
      appDataManager.getStepPerMonth(m, this.monthCallback, true)
    }
  }

  private showYearRecord(): void {
    // 近12个月自然月总步数
    const end = new Date(this.windowEndDate.getFullYear(), this.windowEndDate.getMonth(), 1)
    const labels: Array<string> = []
    const totals: Array<number> = []
    const months: Array<string> = [] // yyyy-MM
    for (let i = 11; i >= 0; i--) {
      const d = new Date(end.getFullYear(), end.getMonth() - i, 1)
      const y = d.getFullYear()
      const m = (d.getMonth() + 1).toString().padStart(2, '0')
      months.push(`${y}-${m}`)
      labels.push(`${parseInt(m)}`) // 不显示单位“月”
    }
    let pending = months.length
    months.forEach((mm: string, idx: number) => {
      appDataManager.getStepPerMonth(mm, {
        onResult: (sum: number) => {
          totals[idx] = sum
          pending--
          if (pending === 0) {
            const finalTotals = totals.map((value: number | undefined) => value ?? 0)
            this.seriesRadiusOption.setVal({
              legend: { show: false },
              xAxis: { data: labels },
              series: [{ name: '', barStyle: { width: 10, color: '#0cc291', borderRadius: [4, 4] }, data: finalTotals }]
            })
            this.reward_str = ''
          }
        }
      }, true)
    })
  }

  build() {
    Column() {
      CommonTitleView({data1:{str1:'步数'},cancel:()=>{
          router.back()
      }})
      Scroll(){
        Column(){
          // 控制区域和图表区域 - 合并为一个白色卡片
          Column(){
            // 第一排：左“趋势查看”，右侧  周/月/年  胶囊（右对齐）
            Row(){
              Text('趋势查看').fontSize(16).fontWeight(500).fontColor('#333333').layoutWeight(1)

              Row(){
                Button('周')
                .backgroundColor(this.viewMode === 'week' ? '#0cc291' : '#EEEEEE')
                .fontColor(this.viewMode === 'week' ? '#FFFFFF' : '#333333')
                .fontWeight(this.viewMode === 'week' ? FontWeight.Medium : FontWeight.Normal)
                .height(32).padding({ left:12, right:12 }).borderRadius(16)
                .opacity(this.viewMode === 'week' ? 1 : 0.8)
                .onClick(()=>{ 
                  console.info('[StepTrendPage] 点击视图模式: week')
                  this.viewMode='week'; 
                  this.windowEndDate = new Date(); 
                  this.loadByViewMode() 
                })
              Button('月')
                .backgroundColor(this.viewMode === 'month' ? '#0cc291' : '#EEEEEE')
                .fontColor(this.viewMode === 'month' ? '#FFFFFF' : '#333333')
                .fontWeight(this.viewMode === 'month' ? FontWeight.Medium : FontWeight.Normal)
                .height(32).padding({ left:12, right:12 }).borderRadius(16).margin({ left:8 })
                .opacity(this.viewMode === 'month' ? 1 : 0.8)
                .onClick(()=>{ 
                  console.info('[StepTrendPage] 点击视图模式: month')
                  this.viewMode='month'; 
                  this.windowEndDate = new Date(); 
                  this.loadByViewMode() 
                })
              Button('年')
                .backgroundColor(this.viewMode === 'year' ? '#0cc291' : '#EEEEEE')
                .fontColor(this.viewMode === 'year' ? '#FFFFFF' : '#333333')
                .fontWeight(this.viewMode === 'year' ? FontWeight.Medium : FontWeight.Normal)
                .height(32).padding({ left:12, right:12 }).borderRadius(16).margin({ left:8 })
                .opacity(this.viewMode === 'year' ? 1 : 0.8)
                .onClick(()=>{ 
                  console.info('[StepTrendPage] 点击视图模式: year')
                  this.viewMode='year'; 
                  this.windowEndDate = new Date(); 
                  this.loadByViewMode() 
                })
              }
            }.margin({ top:16, bottom:8 }).width('100%')

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
              targetName: '步数',
              currentValue: this.currentSteps,
              targetValue: this.targetSteps,
              unit: '步'
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
                Text('总步数').fontSize(12).fontColor('#666666')
                Text(this.allSteps.toString()).fontWeight(600).fontSize(30).margin({ top: 6 })
                Text('步').fontSize(12).fontColor('#666666')
              }.layoutWeight(1)
              Column(){
                Text('平均每日步数').fontSize(12).fontColor('#666666')
                Text(this.argSteps.toFixed(0)).fontWeight(600).fontSize(30).margin({ top: 6 })
                Text('步').fontSize(12).fontColor('#666666')
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
