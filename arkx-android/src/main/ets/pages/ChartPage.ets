import { CommonTitleView } from '../view/CommonTitleView'
import { BarChartView } from '../view/BarChartView'
import appDataManager from '../tools/AppDataManager'
import { DataCallback } from '../tools/DataCallback'
import { SportModel } from '../appdata/Model'
import { DateUtils } from '../tools/DateUtils'

@Entry
@Component
struct ChartPage {
  @State top_week: string = '本周'
  @State allCalories: number = 0
  @State argCalories: number = 0
  @State targetCalories: number = 300
  @State currentCalories: number = 0
  @State viewMode: 'week' | 'month' | 'year' = 'week'
  @State windowEndDate: Date = new Date()
  // 图表数据
  @State chartLabels: Array<string> = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
  @State chartData: Array<number> = [0, 0, 0, 0, 0, 0, 0]
  // 运动数据
  @State sportRecords: Array<SportModel> = []
  private dates: Array<string> = []

  private sportCallback: DataCallback<SportModel> = {
    onDataResult: (type: number, result: SportModel[], isReturnFirstData: boolean): void => {
      this.sportRecords = result
      this.calculateCalorieStats()
    }
  }

  onPageShow(): void {
    this.windowEndDate = new Date()
    this.loadByViewMode()
  }

  private loadByViewMode() {
    if (this.viewMode === 'week') {
      this.loadWeekWindow()
    } else if (this.viewMode === 'month') {
      this.loadDailyWindow(30)
    } else {
      this.loadYearWindow()
    }
  }

  private loadWeekWindow() {
    const ref = new Date(this.windowEndDate)
    const jsDay = ref.getDay()
    const offsetToMonday = (jsDay + 6) % 7
    const start = new Date(ref)
    start.setDate(ref.getDate() - offsetToMonday)
    const end = new Date(start)
    end.setDate(start.getDate() + 6)

    this.dates.length = 0
    for (let i = 0; i < 7; i++) {
      const d = new Date(start)
      d.setDate(start.getDate() + i)
      this.dates.push(this.formatYMD(d))
    }

    this.top_week = this.formatDateCH(start) + ' - ' + this.formatDateCH(end)
    this.loadSportData()
  }

  private loadDailyWindow(sizeDays: number) {
    const end = new Date(this.windowEndDate)
    const start = new Date(end)
    start.setDate(end.getDate() - sizeDays + 1)

    this.dates.length = 0
    for (let i = 0; i < sizeDays; i++) {
      const d = new Date(start)
      d.setDate(start.getDate() + i)
      this.dates.push(this.formatYMD(d))
    }

    this.top_week = this.formatDateCH(start) + ' - ' + this.formatDateCH(end)
    this.loadSportData()
  }

  private loadYearWindow() {
    const end = new Date(this.windowEndDate)
    const start = new Date(end.getFullYear(), end.getMonth() - 11, 1)

    this.dates.length = 0
    for (let i = 0; i < 12; i++) {
      const d = new Date(start.getFullYear(), start.getMonth() + i, 1)
      this.dates.push(this.formatYMD(d))
    }

    this.top_week = this.formatYMCH(start) + ' - ' + this.formatYMCH(end)
    this.loadSportData()
  }

  private loadSportData() {
    // 加载所有类型的运动数据
    appDataManager.findSportByType(0, this.sportCallback, false)
  }

  private calculateCalorieStats() {
    if (this.dates.length === 0) {
      return
    }

    // 按日期分组计算每日热量
    const dailyCalories: Map<string, number> = new Map()
    
    for (const record of this.sportRecords) {
      const recordDate = new Date(record.start_time)
      const dateKey = this.formatYMD(recordDate)
      const calories = Number.parseFloat(record.cal) || 0
      
      if (calories > 0) {
        const current = dailyCalories.get(dateKey) || 0
        dailyCalories.set(dateKey, current + calories)
      }
    }

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

    // 计算今日热量
    const todayDate = this.formatYMD(new Date())
    this.currentCalories = dailyCalories.get(todayDate) || 0

    // 更新图表数据
    let mm_datas = new Array<number>()
    let mm_dates = new Array<string>()
    
    for (let i = 0; i < this.dates.length; i++) {
      const calories = dailyCalories.get(this.dates[i]) || 0
      
      if (this.viewMode === 'week') {
        const d = new Date(this.dates[i])
        const jsDay = d.getDay()
        const weekDays = ['日', '一', '二', '三', '四', '五', '六']
        mm_dates.push(weekDays[jsDay])
        mm_datas.push(calories)
      } else if (this.viewMode === 'month') {
        const d = new Date(this.dates[i])
        const jsDay = d.getDay()
        if (jsDay === 1) { // 只显示周一
          mm_dates.push(this.formatMDLabel(this.dates[i]))
          mm_datas.push(calories)
        }
      } else {
        const d = new Date(this.dates[i])
        const month = (d.getMonth() + 1).toString()
        mm_dates.push(month)
        mm_datas.push(calories)
      }
    }
    
    this.chartLabels = mm_dates
    this.chartData = mm_datas
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

  private formatMDLabel(ymd: string): string {
    const parts = ymd.split('-')
    const month = parseInt(parts[1])
    const day = parseInt(parts[2])
    return `${month}/${day}`
  }

  build() {
    Column() {
      CommonTitleView({
        data1: { str1: '热量' },
        cancel: () => {
          router.back()
        },
        useSafeTop: true
      })

      Scroll() {
        Column() {
          // 控制区域和图表区域 - 合并为一个白色卡片
          Column() {
            // 维度切换（周 / 月 / 年）
            Row() {
              Button('周')
                .backgroundColor(this.viewMode === 'week' ? '#0cc291' : '#EEEEEE')
                .fontColor(this.viewMode === 'week' ? '#FFFFFF' : '#333333')
                .height(32)
                .padding({ left: 12, right: 12 })
                .borderRadius(16)
                .onClick(() => {
                  this.viewMode = 'week'
                  this.windowEndDate = new Date()
                  this.loadByViewMode()
                })
              Button('月')
                .backgroundColor(this.viewMode === 'month' ? '#0cc291' : '#EEEEEE')
                .fontColor(this.viewMode === 'month' ? '#FFFFFF' : '#333333')
                .height(32)
                .padding({ left: 12, right: 12 })
                .borderRadius(16)
                .margin({ left: 8 })
                .onClick(() => {
                  this.viewMode = 'month'
                  this.windowEndDate = new Date()
                  this.loadByViewMode()
                })
              Button('年')
                .backgroundColor(this.viewMode === 'year' ? '#0cc291' : '#EEEEEE')
                .fontColor(this.viewMode === 'year' ? '#FFFFFF' : '#333333')
                .height(32)
                .padding({ left: 12, right: 12 })
                .borderRadius(16)
                .margin({ left: 8 })
                .onClick(() => {
                  this.viewMode = 'year'
                  this.windowEndDate = new Date()
                  this.loadByViewMode()
                })
            }
            .margin({ top: 16, bottom: 8 })
            .width('100%')
            .justifyContent(FlexAlign.Center)

            // 日期范围选择器
            Row() {
              Image($r('app.media.back_btn_dark'))
                .width(20)
                .height(20)
                .margin(5)
                .onClick(() => {
                  if (this.viewMode === 'week') {
                    this.windowEndDate.setDate(this.windowEndDate.getDate() - 7)
                    this.loadByViewMode()
                  } else if (this.viewMode === 'month') {
                    this.windowEndDate.setDate(this.windowEndDate.getDate() - 30)
                    this.loadByViewMode()
                  } else {
                    this.windowEndDate = new Date(this.windowEndDate.getFullYear(), this.windowEndDate.getMonth() - 1, 1)
                    this.loadByViewMode()
                  }
                })
              Text(this.top_week)
                .fontSize(14)
              Image($r('app.media.right_btn'))
                .width(20)
                .height(20)
                .margin(5)
                .onClick(() => {
                  if (this.viewMode === 'week') {
                    this.windowEndDate.setDate(this.windowEndDate.getDate() + 7)
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
            }
            .margin({ top: 4, bottom: 16 })
            .width('100%')
            .justifyContent(FlexAlign.Center)

            // 图表区域
            BarChartView({
              xAxisData: this.chartLabels,
              seriesData: this.chartData,
              barColor: '#FF8C47',
              title: '千卡',
              titlePosition: 'right'
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
          Column() {
            Text(`今日 ${this.currentCalories}/${this.targetCalories} 千卡`)
              .fontSize(16)
              .fontColor('#333')
          }
          .width('92%')
          .margin({ top: 12 })
          .padding(16)
          .borderRadius(15)
          .backgroundColor('#FFFFFF')

          // 汇总指标 - 白色卡片
          Column() {
            Row() {
              Column() {
                Text('总消耗')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(this.allCalories.toString())
                  .fontWeight(600)
                  .fontSize(30)
                  .margin({ top: 6 })
                Text('千卡')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)

              Column() {
                Text('平均每日消耗')
                  .fontSize(12)
                  .fontColor('#666666')
                Text(this.argCalories.toFixed(0))
                  .fontWeight(600)
                  .fontSize(30)
                  .margin({ top: 6 })
                Text('千卡')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .layoutWeight(1)
            }
          }
          .width('92%')
          .margin({ top: 10 })
          .padding(16)
          .borderRadius(15)
          .backgroundColor('#FFFFFF')
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
